-- Committed fixture for checking supabase/seed_invoice_demo*.sql in the
-- ephemeral database. Run order: this file, both seed files, then
-- test/invoice_seed_check.sql.
INSERT INTO auth.users(id,email) VALUES
 ('b5000000-0000-0000-0000-000000000001','seed-cashier@example.test'),
 ('b5000000-0000-0000-0000-000000000002','seed-desk@example.test');
INSERT INTO public.staff(user_id,full_name,email,role,can_manage_payments) VALUES
 ('b5000000-0000-0000-0000-000000000001','Seed cashier','seed-cashier@example.test','receptionist',true),
 ('b5000000-0000-0000-0000-000000000002','Seed desk','seed-desk@example.test','receptionist',false);
INSERT INTO public.staff(full_name,email,role)
SELECT 'Seed doctor ' || n, 'seed-doctor-' || n || '@example.test', 'doctor' FROM generate_series(1, 4) n;
INSERT INTO public.patients(full_name,phone_number,clinic)
SELECT 'Seed patient ' || n, '0100000' || lpad(n::text, 4, '0'),
  (CASE WHEN n % 3 = 0 THEN 'masr_elgedida' ELSE 'tagamoa' END)::public.clinic_location
FROM generate_series(1, 40) n;
