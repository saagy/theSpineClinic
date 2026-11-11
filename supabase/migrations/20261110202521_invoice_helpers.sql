-- Private helpers for the invoice commands. None are callable by clients.

CREATE FUNCTION public.invoice_next_number(p_branch public.clinic_location, p_kind text)
RETURNS bigint LANGUAGE sql SET search_path = '' AS $$
  INSERT INTO public.invoice_number_series AS series(branch, kind, last_number)
  VALUES (p_branch, p_kind, 1)
  ON CONFLICT (branch, kind) DO UPDATE SET last_number = series.last_number + 1
  RETURNING last_number;
$$;

-- Per-line figures from active documents only.
-- value = net - active refund value; collected = active allocations.
CREATE FUNCTION public.invoice_line_figures(p_invoice_id uuid)
RETURNS TABLE(line_id uuid, line_position integer, service_type text, value_minor bigint,
  collected_minor bigint, sessions_left integer)
LANGUAGE sql STABLE SET search_path = '' AS $$
  SELECT l.id, l.position, l.service_type,
    l.net_minor - coalesce(r.value, 0),
    coalesce(a.amount, 0),
    l.sessions_granted - coalesce(r.sessions, 0)
  FROM public.invoice_lines l
  LEFT JOIN LATERAL (
    SELECT sum(rl.value_minor)::bigint AS value, sum(rl.sessions_cancelled)::integer AS sessions
    FROM public.invoice_refund_lines rl JOIN public.invoice_refunds rf ON rf.id = rl.refund_id
    WHERE rl.line_id = l.id AND rf.voided_at IS NULL
  ) r ON true
  LEFT JOIN LATERAL (
    SELECT sum(al.amount_minor)::bigint AS amount FROM public.invoice_allocations al
    LEFT JOIN public.invoice_receipts rc ON rc.id = al.receipt_id
    LEFT JOIN public.invoice_refunds rf ON rf.id = al.refund_id
    WHERE al.line_id = l.id AND coalesce(rc.voided_at, rf.voided_at) IS NULL
  ) a ON true
  WHERE l.invoice_id = p_invoice_id;
$$;

-- Invoice-level figures. Invariant: 0 <= net_collected <= value.
CREATE FUNCTION public.invoice_figures(p_invoice_id uuid,
  OUT total_minor bigint, OUT refunded_minor bigint, OUT value_minor bigint,
  OUT received_minor bigint, OUT paid_back_minor bigint, OUT net_collected_minor bigint,
  OUT due_minor bigint)
LANGUAGE sql STABLE SET search_path = '' AS $$
  SELECT i.total_minor, coalesce(rf.value, 0), i.total_minor - coalesce(rf.value, 0),
    coalesce(rc.amount, 0), coalesce(rf.payback, 0),
    coalesce(rc.amount, 0) - coalesce(rf.payback, 0),
    i.total_minor - coalesce(rf.value, 0) - coalesce(rc.amount, 0) + coalesce(rf.payback, 0)
  FROM public.invoices i
  LEFT JOIN LATERAL (SELECT sum(amount_minor)::bigint AS amount FROM public.invoice_receipts
    WHERE invoice_id = i.id AND voided_at IS NULL) rc ON true
  LEFT JOIN LATERAL (SELECT sum(value_minor)::bigint AS value, sum(payback_minor)::bigint AS payback
    FROM public.invoice_refunds WHERE invoice_id = i.id AND voided_at IS NULL) rf ON true
  WHERE i.id = p_invoice_id;
$$;

-- Applies session balance deltas. Removals must leave enough sessions for
-- future package bookings, mirroring the booking availability rule.
CREATE FUNCTION public.invoice_adjust_sessions(p_patient_id uuid, p_pt integer, p_traction integer)
RETURNS void LANGUAGE plpgsql SET search_path = '' AS $$
DECLARE person public.patients; booked_pt integer; booked_tr integer;
BEGIN
  IF coalesce(p_pt, 0) = 0 AND coalesce(p_traction, 0) = 0 THEN RETURN; END IF;
  SELECT * INTO STRICT person FROM public.patients WHERE id = p_patient_id FOR UPDATE;
  SELECT count(*) FILTER (WHERE type = 'normal_pt_session'),
    count(*) FILTER (WHERE type = 'spinal_traction_session')
  INTO booked_pt, booked_tr FROM public.appointments
  WHERE patient_id = p_patient_id AND use_package AND status = 'scheduled' AND scheduled_at > now();
  -- Additions always succeed; only removals are checked.
  IF (p_pt < 0 AND person.session_balance + p_pt < greatest(booked_pt, 0))
    OR (p_traction < 0 AND person.traction_balance + p_traction < greatest(booked_tr, 0)) THEN
    RAISE EXCEPTION 'sessions_in_use' USING ERRCODE = 'P0001';
  END IF;
  UPDATE public.patients SET session_balance = session_balance + p_pt,
    traction_balance = traction_balance + p_traction WHERE id = p_patient_id;
END;
$$;

-- Session deltas granted by an invoice's remaining (not refunded) sessions.
CREATE FUNCTION public.invoice_remaining_sessions(p_invoice_id uuid, OUT pt integer, OUT traction integer)
LANGUAGE sql STABLE SET search_path = '' AS $$
  SELECT coalesce(sum(sessions_left) FILTER (WHERE service_type = 'pt_session'), 0)::integer,
    coalesce(sum(sessions_left) FILTER (WHERE service_type = 'traction_session'), 0)::integer
  FROM public.invoice_line_figures(p_invoice_id);
$$;

-- Splits a receipt across lines in proportion to each line's uncollected value.
-- Cumulative integer division keeps the parts exact and deterministic.
CREATE FUNCTION public.invoice_allocate_receipt(p_invoice_id uuid, p_receipt_id uuid, p_amount bigint)
RETURNS void LANGUAGE plpgsql SET search_path = '' AS $$
BEGIN
  WITH open AS (
    SELECT line_id, line_position, value_minor - collected_minor AS room
    FROM public.invoice_line_figures(p_invoice_id) WHERE value_minor > collected_minor
  ), weighted AS (
    SELECT *, sum(room) OVER (ORDER BY line_position) AS cumulative, sum(room) OVER () AS total FROM open
  ), parts AS (
    SELECT line_id, div(p_amount::numeric * cumulative, total)
      - div(p_amount::numeric * (cumulative - room), total) AS amount FROM weighted
  )
  INSERT INTO public.invoice_allocations(line_id, receipt_id, amount_minor)
  SELECT line_id, p_receipt_id, amount FROM parts WHERE amount > 0;
END;
$$;

-- After refund lines are written: lines collected above their new value give
-- up the excess; paid-back money leaves; what remains moves to lines that
-- still have room, in proportion to that room.
CREATE FUNCTION public.invoice_reallocate_refund(p_invoice_id uuid, p_refund_id uuid, p_payback bigint)
RETURNS void LANGUAGE plpgsql SET search_path = '' AS $$
BEGIN
  WITH figures AS (
    SELECT line_id, line_position, collected_minor AS held,
      least(collected_minor, value_minor) AS kept, value_minor - least(collected_minor, value_minor) AS room
    FROM public.invoice_line_figures(p_invoice_id)
  ), freed AS (
    SELECT sum(held - kept) - p_payback AS amount FROM figures
  ), weighted AS (
    SELECT f.*, sum(room) OVER (ORDER BY line_position) AS cumulative, sum(room) OVER () AS total,
      freed.amount AS spare FROM figures f CROSS JOIN freed
  ), targets AS (
    SELECT line_id, kept + CASE WHEN total = 0 THEN 0 ELSE
      div(spare::numeric * cumulative, total) - div(spare::numeric * (cumulative - room), total) END
      - held AS delta FROM weighted
  )
  INSERT INTO public.invoice_allocations(line_id, refund_id, amount_minor)
  SELECT line_id, p_refund_id, delta FROM targets WHERE delta <> 0;
END;
$$;

CREATE FUNCTION public.invoice_actor_name(p_actor uuid) RETURNS text
LANGUAGE sql STABLE SET search_path = '' AS $$
  SELECT full_name FROM public.staff WHERE id = p_actor;
$$;

REVOKE ALL ON FUNCTION public.invoice_next_number(public.clinic_location, text),
  public.invoice_line_figures(uuid), public.invoice_figures(uuid),
  public.invoice_adjust_sessions(uuid, integer, integer), public.invoice_remaining_sessions(uuid),
  public.invoice_allocate_receipt(uuid, uuid, bigint),
  public.invoice_reallocate_refund(uuid, uuid, bigint), public.invoice_actor_name(uuid)
  FROM PUBLIC, anon, authenticated;

-- Invoices protect a patient from deletion, like the other financial records.
CREATE OR REPLACE FUNCTION public.patient_has_records(p_patient_id uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (SELECT 1 FROM public.patients WHERE id = p_patient_id
    AND (session_balance <> 0 OR traction_balance <> 0))
    OR EXISTS (SELECT 1 FROM public.appointments WHERE patient_id = p_patient_id)
    OR EXISTS (SELECT 1 FROM public.payment_records WHERE patient_id = p_patient_id)
    OR EXISTS (SELECT 1 FROM public.patient_programs WHERE patient_id = p_patient_id)
    OR EXISTS (SELECT 1 FROM public.patient_medical_history WHERE patient_id = p_patient_id)
    OR EXISTS (SELECT 1 FROM public.patient_notes WHERE patient_id = p_patient_id)
    OR EXISTS (SELECT 1 FROM public.patient_documents WHERE patient_id = p_patient_id)
    OR EXISTS (SELECT 1 FROM public.billing_invoices WHERE patient_id = p_patient_id)
    OR EXISTS (SELECT 1 FROM public.invoices WHERE patient_id = p_patient_id);
$$;
REVOKE ALL ON FUNCTION public.patient_has_records(uuid) FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.billing_patient_has_invoices(p_patient_id uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $$
  SELECT public.can_current_staff_access_patient(p_patient_id) AND (
    EXISTS (SELECT 1 FROM public.billing_invoices WHERE patient_id = p_patient_id)
    OR EXISTS (SELECT 1 FROM public.invoices WHERE patient_id = p_patient_id));
$$;
REVOKE ALL ON FUNCTION public.billing_patient_has_invoices(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.billing_patient_has_invoices(uuid) TO authenticated;
