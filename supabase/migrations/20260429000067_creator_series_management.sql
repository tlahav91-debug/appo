ALTER TABLE public.series ADD COLUMN IF NOT EXISTS creator_id uuid REFERENCES public.profiles(id) ON DELETE SET NULL;
CREATE INDEX IF NOT EXISTS idx_series_creator ON public.series(creator_id);

CREATE POLICY "series_insert_creator" ON public.series FOR INSERT TO authenticated
  WITH CHECK (creator_id = auth.uid() AND is_vip = false);

CREATE POLICY "series_update_creator" ON public.series FOR UPDATE TO authenticated
  USING (creator_id = auth.uid())
  WITH CHECK (creator_id = auth.uid() AND is_vip = false);

CREATE POLICY "series_delete_creator" ON public.series FOR DELETE TO authenticated
  USING (creator_id = auth.uid());

-- Allow approved creators to INSERT their own draft submissions directly
CREATE POLICY "submissions_insert_creator" ON public.content_submissions
  FOR INSERT TO authenticated
  WITH CHECK (creator_id = auth.uid());
