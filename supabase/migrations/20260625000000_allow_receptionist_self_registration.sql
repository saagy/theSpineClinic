-- Migration: Allow receptionist self-registration
--
-- The INSERT RLS policy on public.staff previously hardcoded role = 'doctor',
-- blocking receptionist self-registration. The signUpWithEmail call would
-- create an auth.users entry, but the subsequent staff INSERT was rejected
-- by RLS, leaving orphaned auth users with no staff profile.
--
-- This updates the policy to allow both 'doctor' and 'receptionist' roles
-- for self-registration (is_active = false, user_id = auth.uid()).

DROP POLICY IF EXISTS "Allow users to insert their own profile" ON public.staff;

CREATE POLICY "Allow users to insert their own profile"
  ON public.staff
  FOR INSERT
  TO authenticated
  WITH CHECK (
    user_id = auth.uid()
    AND is_active = false
    AND role IN ('doctor'::user_role, 'receptionist'::user_role)
  );

-- Clean up orphaned auth.users from failed receptionist registration attempts.
DELETE FROM auth.users
WHERE id IN (
  '0b2a211c-a129-4d99-8c5c-662c6bd191dc',
  '10cfa34a-9616-4490-825b-c9229f0a0484',
  'd9fd6e63-a468-4796-b661-48d7ab14fb11'
);
