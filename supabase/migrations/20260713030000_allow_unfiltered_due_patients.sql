CREATE OR REPLACE FUNCTION public.get_due_patients(
  p_due_on date,
  p_doctor_id uuid,
  p_clinic public.clinic_location
)
RETURNS SETOF public.patients
LANGUAGE sql
STABLE
SECURITY INVOKER
AS $function$
  SELECT p.*
  FROM public.patients p
  WHERE p.clinic = p_clinic
    AND p.next_visit_date IS NOT NULL
    AND p.next_visit_date <= p_due_on
    AND (
      p_doctor_id IS NULL
      OR EXISTS (
        SELECT 1
        FROM public.patient_doctors pd
        WHERE pd.patient_id = p.id
          AND pd.doctor_id = p_doctor_id
      )
    )
    AND NOT EXISTS (
      SELECT 1
      FROM public.appointments a
      WHERE a.patient_id = p.id
        AND a.status = 'scheduled'::public.appointment_status
        AND (a.scheduled_at AT TIME ZONE public.clinic_timezone())::date
            >= p.next_visit_date
    )
  ORDER BY p.next_visit_date, p.full_name;
$function$;
