-- Drop the unsafe policy that exposes all columns to authenticated users
DROP POLICY IF EXISTS "creator_profiles_select_approved" ON public.creator_profiles;

-- Recreate view with same definition (no changes to columns)
CREATE OR REPLACE VIEW public.public_creator_profiles AS
SELECT
  cp.id,
  cp.display_name,
  cp.bio,
  p.avatar_url,
  COUNT(DISTINCT cf.follower_id)::INT AS follower_count
FROM public.creator_profiles cp
JOIN public.profiles p ON p.id = cp.id
LEFT JOIN public.creator_follows cf ON cf.creator_id = cp.id
WHERE cp.status = 'approved'
GROUP BY cp.id, cp.display_name, cp.bio, p.avatar_url;

-- Transfer ownership to postgres so view queries bypass RLS on creator_profiles
ALTER VIEW public.public_creator_profiles OWNER TO postgres;

-- Grant authenticated users SELECT on the view only (not the underlying table)
GRANT SELECT ON public.public_creator_profiles TO authenticated;
