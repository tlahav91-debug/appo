-- Improve referral code trigger: 12-char alphanumeric + retry loop to handle collisions
CREATE OR REPLACE FUNCTION generate_referral_code()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
  new_code TEXT;
  attempts  INT := 0;
BEGIN
  IF NEW.referral_code IS NULL THEN
    LOOP
      new_code := upper(substr(md5(gen_random_uuid()::text), 1, 12));
      EXIT WHEN NOT EXISTS (
        SELECT 1 FROM public.profiles WHERE referral_code = new_code
      );
      attempts := attempts + 1;
      IF attempts > 10 THEN
        RAISE EXCEPTION 'Could not generate unique referral code after % attempts', attempts;
      END IF;
    END LOOP;
    NEW.referral_code := new_code;
  END IF;
  RETURN NEW;
END;
$$;

-- Backfill any existing profiles still using 8-char codes (upgrade to 12)
-- Uses a DO block to safely iterate with collision avoidance
DO $$
DECLARE
  rec RECORD;
  new_code TEXT;
  attempts INT;
BEGIN
  FOR rec IN SELECT id FROM public.profiles WHERE char_length(referral_code) < 12 OR referral_code IS NULL LOOP
    attempts := 0;
    LOOP
      new_code := upper(substr(md5(gen_random_uuid()::text), 1, 12));
      EXIT WHEN NOT EXISTS (SELECT 1 FROM public.profiles WHERE referral_code = new_code AND id <> rec.id);
      attempts := attempts + 1;
      EXIT WHEN attempts > 10;
    END LOOP;
    UPDATE public.profiles SET referral_code = new_code WHERE id = rec.id;
  END LOOP;
END;
$$;
