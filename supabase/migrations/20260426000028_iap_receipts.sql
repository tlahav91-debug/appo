CREATE TABLE IF NOT EXISTS iap_receipts (
  id             UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id        UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  transaction_id TEXT        UNIQUE NOT NULL,
  product_id     TEXT        NOT NULL,
  gems_credited  INTEGER     NOT NULL,
  platform       TEXT        NOT NULL CHECK (platform IN ('ios','android')),
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE iap_receipts ENABLE ROW LEVEL SECURITY;
-- No client-facing policies — service_role only (Edge Function bypasses RLS)
