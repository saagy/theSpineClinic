-- =============================================================================
-- Migration: Clean Condition Catalog Laterality Names
-- Replace "Rt" and "Lt" with "(Right)" and "(Left)" for readability
-- =============================================================================

UPDATE public.condition_catalog
   SET condition_name = 'Knee OA (Right)'
 WHERE condition_name = 'Knee OA Rt'
   AND region = 'knee_joint'::public.body_region;

UPDATE public.condition_catalog
   SET condition_name = 'Knee OA (Left)'
 WHERE condition_name = 'Knee OA Lt'
   AND region = 'knee_joint'::public.body_region;

UPDATE public.condition_catalog
   SET condition_name = 'Patellofemoral OA (Right)'
 WHERE condition_name = 'Patellofemoral OA Rt'
   AND region = 'knee_joint'::public.body_region;

UPDATE public.condition_catalog
   SET condition_name = 'Patellofemoral OA (Left)'
 WHERE condition_name = 'Patellofemoral OA Lt'
   AND region = 'knee_joint'::public.body_region;
