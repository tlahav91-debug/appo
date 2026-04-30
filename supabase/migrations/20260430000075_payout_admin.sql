-- PRD-075: Creator Payout Admin Panel
-- Allow admins to SELECT all payout_requests

CREATE POLICY "payout_select_admin" ON public.payout_requests
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND is_admin = true)
  );
