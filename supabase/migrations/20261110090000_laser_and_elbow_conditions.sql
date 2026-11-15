ALTER TYPE public.modality_type ADD VALUE IF NOT EXISTS 'high_power_laser' AFTER 'tecar';

INSERT INTO public.condition_catalog (region, condition_name, display_order) VALUES
  ('elbow', 'Tennis elbow', 1),
  ('elbow', 'Golfer''s elbow', 2),
  ('elbow', 'Elbow stiffness', 3),
  ('elbow', 'Elbow muscle strain', 4),
  ('elbow', 'Elbow ligament sprain', 5),
  ('elbow', 'Elbow dislocation', 6),
  ('elbow', 'Triceps tendinopathy', 7),
  ('elbow', 'Triceps tear', 8)
ON CONFLICT (region, condition_name) DO NOTHING;
