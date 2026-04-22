-- [SCHEMA] Add hard range constraint to profiles.current_energy

ALTER TABLE public.profiles
  ADD CONSTRAINT chk_energy_range
  CHECK (current_energy >= 0 AND current_energy <= 20);
