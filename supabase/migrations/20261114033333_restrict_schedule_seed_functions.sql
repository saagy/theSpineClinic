-- These maintenance functions can replace clinic appointments. Restrict every overload.
DO $$
DECLARE
  seed_function regprocedure;
BEGIN
  FOR seed_function IN
    SELECT p.oid::regprocedure
    FROM pg_catalog.pg_proc p
    WHERE p.pronamespace = 'public'::regnamespace
      AND p.prokind = 'f'
      AND p.proname IN ('seed_clinic_day_schedule', 'seed_clinic_schedule_range')
  LOOP
    EXECUTE format(
      'REVOKE EXECUTE ON FUNCTION %s FROM PUBLIC, anon, authenticated, service_role',
      seed_function
    );

    IF has_function_privilege('anon', seed_function, 'EXECUTE')
      OR has_function_privilege('authenticated', seed_function, 'EXECUTE')
      OR has_function_privilege('service_role', seed_function, 'EXECUTE') THEN
      RAISE EXCEPTION 'Data API role still has EXECUTE on %', seed_function;
    END IF;
  END LOOP;
END;
$$;
