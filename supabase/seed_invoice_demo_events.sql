-- ==============================================================================
-- Invoice demo events. Run after supabase/seed_invoice_demo.sql as the
-- database owner. Adds refunds (with and without payback), corrected and
-- voided receipts, corrected invoices and voided invoices through the real
-- commands, each dated after the invoice's earlier documents.
-- ==============================================================================
BEGIN;
CREATE OR REPLACE FUNCTION pg_temp.cmd(p_user uuid, p_kind text, p_payload jsonb) RETURNS jsonb
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM set_config('request.jwt.claim.sub', p_user::text, true);
  RETURN public.execute_invoice_command(gen_random_uuid(), p_kind, p_payload);
END;
$$;
-- A moment after every earlier document on the invoice, never in the future.
CREATE OR REPLACE FUNCTION pg_temp.after(p_invoice uuid, p_days integer) RETURNS timestamptz LANGUAGE sql AS $$
  SELECT least(greatest(i.created_at, coalesce(max(r.recorded_at), i.created_at),
      coalesce(max(f.recorded_at), i.created_at)) + p_days * interval '1 day' + interval '2 hours',
    now() - interval '10 minutes')
  FROM public.invoices i
  LEFT JOIN public.invoice_receipts r ON r.invoice_id = i.id
  LEFT JOIN public.invoice_refunds f ON f.invoice_id = i.id
  WHERE i.id = p_invoice GROUP BY i.id;
$$;
CREATE OR REPLACE FUNCTION pg_temp.stamp(p_invoice uuid, p_at timestamptz) RETURNS void LANGUAGE sql AS $$
  UPDATE public.invoice_refunds SET recorded_at = p_at
    WHERE invoice_id = p_invoice AND recorded_at > now() - interval '1 minute';
  UPDATE public.invoice_receipts SET voided_at = p_at
    WHERE invoice_id = p_invoice AND voided_at > now() - interval '1 minute';
  UPDATE public.invoices SET voided_at = p_at WHERE id = p_invoice AND voided_at > now() - interval '1 minute';
$$;

DO $$
DECLARE
  manager uuid := (SELECT user_id FROM public.staff WHERE is_active AND user_id IS NOT NULL AND (role = 'super_admin'
    OR (role = 'receptionist' AND can_manage_payments)) ORDER BY role DESC, created_at LIMIT 1);
  inv public.invoice_register; line record; receipt public.invoice_receipts;
  result jsonb; moment timestamptz; refund_value bigint; payback bigint; new_id uuid; done integer;
  partial integer := 0;
BEGIN
  PERFORM setseed(0.24);
  -- Package refunds: some paid back, some only cancelling what is still owed.
  done := 0;
  FOR inv IN SELECT r.* FROM public.invoice_register r WHERE r.status IN ('paid', 'partially_paid')
    AND r.total_minor > 0 AND r.invoice_date < current_date - 10
    AND EXISTS (SELECT 1 FROM public.invoice_lines l WHERE l.invoice_id = r.id AND l.sessions_granted >= 6)
    ORDER BY r.due_minor > 0 DESC, r.invoice_date, r.number LOOP
    EXIT WHEN done >= 7;
    CONTINUE WHEN random() < 0.4 OR (inv.due_minor > 0 AND partial >= 3);
    SELECT f.line_id, f.value_minor, least(f.sessions_left, 2 + floor(random() * 3)::integer) AS sessions
      INTO line FROM public.invoice_line_figures(inv.id) f WHERE f.sessions_left >= 6 ORDER BY f.line_position LIMIT 1;
    CONTINUE WHEN NOT FOUND;
    refund_value := round(line.value_minor * line.sessions / (line.sessions + 4) / 5000.0) * 5000;
    IF inv.due_minor > 0 THEN -- partly paid: cancel only part of what is still owed
      refund_value := least(refund_value, floor(inv.due_minor / 5000.0)::bigint * 5000);
      CONTINUE WHEN refund_value = 0;
    END IF;
    payback := greatest(inv.net_collected_minor - (inv.value_minor - refund_value), 0);
    moment := pg_temp.after(inv.id, 5 + floor(random() * 10)::integer);
    result := pg_temp.cmd(manager, 'refund_create', jsonb_build_object('id', inv.id, 'version', inv.version,
      'branch', inv.branch, 'payback_minor', payback,
      'payback_method', CASE WHEN payback = 0 THEN NULL WHEN random() < 0.7 THEN 'cash' ELSE 'visa' END,
      'reason', (ARRAY['Patient stopping treatment', 'Travelling abroad', 'Moved to home program'])[1 + floor(random() * 3)::integer],
      'lines', jsonb_build_array(jsonb_build_object('line_id', line.line_id, 'sessions', line.sessions,
        'value_minor', refund_value))));
    IF (result->>'ok')::boolean THEN
      PERFORM pg_temp.stamp(inv.id, moment);
      done := done + 1;
      partial := partial + (inv.due_minor > 0)::integer;
    END IF;
  END LOOP;

  -- Receipt corrections (wrong method) and duplicate receipts voided.
  done := 0;
  FOR receipt IN SELECT rc.* FROM public.invoice_receipts rc JOIN public.invoices i ON i.id = rc.invoice_id
    WHERE rc.voided_at IS NULL AND i.voided_at IS NULL AND NOT EXISTS (SELECT 1 FROM public.invoice_refunds f
      WHERE f.invoice_id = i.id) ORDER BY rc.received_at LOOP
    EXIT WHEN done >= 5;
    CONTINUE WHEN random() < 0.9;
    SELECT * INTO inv FROM public.invoice_register WHERE id = receipt.invoice_id;
    moment := pg_temp.after(inv.id, 0);
    result := pg_temp.cmd(manager, CASE WHEN done < 3 THEN 'receipt_correct' ELSE 'receipt_void' END,
      jsonb_build_object('id', inv.id, 'version', inv.version, 'receipt_id', receipt.id,
        'amount_minor', receipt.amount_minor, 'branch', receipt.branch,
        'method', CASE receipt.method WHEN 'cash' THEN 'visa' ELSE 'cash' END,
        'reason', CASE WHEN done < 3 THEN 'Wrong payment method' ELSE 'Entered twice' END));
    IF (result->>'ok')::boolean THEN
      PERFORM pg_temp.stamp(inv.id, moment);
      UPDATE public.invoice_receipts SET recorded_at = moment WHERE replaces_receipt_id = receipt.id;
      done := done + 1;
    END IF;
  END LOOP;

  -- Two invoices corrected for a forgotten 5% discount; two unpaid ones voided.
  done := 0;
  FOR inv IN SELECT * FROM public.invoice_register WHERE status IN ('unpaid', 'partially_paid')
    AND refunded_minor = 0 AND discount_kind = 'none' AND replaces_invoice_id IS NULL
    ORDER BY invoice_date DESC, number LOOP
    EXIT WHEN done >= 4;
    moment := pg_temp.after(inv.id, 1);
    IF done < 2 AND inv.net_collected_minor <= inv.total_minor * 0.95 THEN
      result := pg_temp.cmd(manager, 'invoice_correct', jsonb_build_object('id', inv.id, 'version', inv.version,
        'reason', 'Forgot the returning-patient discount', 'invoice', jsonb_build_object(
          'patient_id', inv.patient_id, 'branch', inv.branch, 'invoice_date', inv.invoice_date,
          'discount', '{"kind":"percent","value":500}', 'lines', (SELECT jsonb_agg(jsonb_build_object(
            'service_id', l.service_id, 'quantity', l.quantity, 'unit_price_minor', s.price_minor,
            'doctor_ids', coalesce((SELECT jsonb_agg(d.doctor_id) FROM public.invoice_line_doctors d
              WHERE d.line_id = l.id), '[]'::jsonb)) ORDER BY l.position)
            FROM public.invoice_lines l JOIN public.service_catalog s ON s.id = l.service_id
            WHERE l.invoice_id = inv.id))));
      new_id := (result->>'invoice_id')::uuid;
      IF (result->>'ok')::boolean THEN
        PERFORM pg_temp.stamp(inv.id, moment);
        UPDATE public.invoices SET created_at = moment WHERE id = new_id;
        UPDATE public.invoice_receipts SET recorded_at = moment WHERE invoice_id = new_id;
        done := done + 1;
      END IF;
    ELSIF done >= 2 AND inv.status = 'unpaid' THEN
      result := pg_temp.cmd(manager, 'invoice_void', jsonb_build_object('id', inv.id, 'version', inv.version,
        'reason', 'Created for the wrong patient'));
      IF (result->>'ok')::boolean THEN
        PERFORM pg_temp.stamp(inv.id, moment);
        done := done + 1;
      END IF;
    END IF;
  END LOOP;
END;
$$;
COMMIT;
