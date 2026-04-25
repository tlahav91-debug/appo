# PRD Log

| ID | Feature | Status | Approved | Notes |
|----|---------|--------|----------|-------|
| PRD-001 | Auth + Player Profile | CLOSED | 2026-04-22 | QA PASS after 1 fix cycle. 4 medium/low bugs deferred to backlog. |
| PRD-002 | Full Database Schema Deployment | CLOSED | 2026-04-22 | QA PASS after 1 fix cycle. 3 integrity triggers added. |
| PRD-003 | Energy System | CLOSED | 2026-04-22 | QA PASS after 1 fix cycle. Atomic ad cap via Postgres RPC, optimistic locking on watch-episode, gems constraint. |
| PRD-004 | Dual Currency Ledger | CLOSED | 2026-04-22 | QA PASS — earn-coins Edge Function, Realtime HUD sync, reconcile RPC. 0 bugs. |
| PRD-005 | Episode Unlock + Choice Flow | CLOSED | 2026-04-22 | QA PASS — record-choice Edge Function, SeriesScreen, EpisodeDetailScreen, ChoiceSheet, CoinToast. 0 bugs. |
| PRD-006 | Collectibles + Album System | CLOSED | 2026-04-22 | QA PASS — collectible minting in record-choice, AlbumScreen grid, CollectibleCard, CollectibleToast. 0 bugs. |
| PRD-007 | RevenueCat IAP — Gem Packs | CLOSED | 2026-04-22 | QA PASS — revenuecat-webhook, GemShopScreen, RC logIn/logOut wired. 0 bugs. |
| PRD-008 | AdMob Rewarded Ads | CLOSED | 2026-04-22 | QA PASS — AdService with Completer flow, credit gated on onUserEarnedReward. 0 bugs. |
| PRD-009 | Season Pass (Drama Pass) | CLOSED | 2026-04-22 | QA PASS — subscription webhook, claim_pass_bonus RPC, RC entitlement sync, PASS HUD badge. 0 bugs. |
| PRD-010 | Starter Pack Offer | CLOSED | 2026-04-22 | QA PASS — webhook credits gems+coins, one-time sheet shown from AppShell, dismiss/purchased guards. 0 bugs. |
| PRD-011 | Series Race Leaderboard | CLOSED | 2026-04-25 | QA PASS after 1 fix cycle. 3C/4H fixed: score spoofing locked to service role, join errors surface to UI, channel cleanup guaranteed, double-score on replay blocked, providers use ref.watch, banner subtitle context-aware, countdown no longer flashes. 4M deferred to backlog. |
| PRD-012 | Lava Quest Event Engine | CLOSED | 2026-04-25 | QA PASS after 1 fix cycle. 3C/4H fixed: atomic claim RPC with FOR UPDATE lock, service_role grant added, completed-quest re-increment blocked, idempotent claim suppresses duplicate toast, stale progress fixed via stream derivation, animation deferred off build phase. 5M deferred to backlog. |
| PRD-013 | Character Affinity | CLOSED | 2026-04-25 | QA PASS after 1 fix cycle. 1C/3H fixed: channel inside try block, ref.read in StreamProvider, stable FutureProvider for banner visibility, empty-name guard. 3M deferred to backlog. |
