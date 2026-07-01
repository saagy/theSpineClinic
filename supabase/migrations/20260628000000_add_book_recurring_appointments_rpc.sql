-- Add book_recurring_appointments RPC function to perform batch bookings in a single transaction.
CREATE OR REPLACE FUNCTION public.book_recurring_appointments(
  p_patient_id uuid,
  p_type public.appointment_type,
  p_slots timestamptz[],
  p_use_package boolean,
  p_creator_id uuid,
  p_doctor_ids uuid[]
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_slot timestamptz;
  v_appt_id uuid;
  v_doc_id uuid;
BEGIN
  -- Perform all inserts in a loop. PostgreSQL automatically executes
  -- the function inside a single transaction. If any statement fails
  -- or raises an exception, the entire transaction is rolled back.
  FOREACH v_slot IN ARRAY p_slots LOOP
    INSERT INTO public.appointments (
      patient_id,
      type,
      scheduled_at,
      status,
      use_package,
      created_by
    ) VALUES (
      p_patient_id,
      p_type,
      v_slot,
      'scheduled'::public.appointment_status,
      p_use_package,
      p_creator_id
    ) RETURNING id INTO v_appt_id;

    FOREACH v_doc_id IN ARRAY p_doctor_ids LOOP
      INSERT INTO public.appointment_doctors (
        appointment_id,
        doctor_id,
        is_replacement,
        is_active,
        added_by
      ) VALUES (
        v_appt_id,
        v_doc_id,
        false,
        true,
        p_creator_id
      );
    END LOOP;
  END LOOP;
END;
$$;

-- Ensure authenticated users can execute the RPC
GRANT EXECUTE ON FUNCTION public.book_recurring_appointments(uuid, public.appointment_type, timestamptz[], boolean, uuid, uuid[]) TO authenticated;
