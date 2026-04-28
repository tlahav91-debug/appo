# PRD Log

| PRD | Feature | Status | Commit(s) | Notes |
|-----|---------|--------|-----------|-------|
| PRD-011 | Series Race Leaderboard | ✅ Closed | local | QA fixes: C-1 score spoofing, C-2 silent join, C-3 channel leak, H-1 double score, H-2 stale providers, H-3 banner subtitle, H-4 countdown flash, M-5 shared join state |
| PRD-012 | Lava Quest Event Engine | ✅ Closed | local | QA fixes: BUG-001 non-atomic claim, BUG-002 no service_role grant, BUG-006 stale quest detail, BUG-012 animation during build, BUG-013 duplicate toast |
| PRD-013 | Character Affinity | ✅ Closed | local | QA fixes: C-1 channel outside try, H-3 ref.watch in StreamProvider, H-4 banner layout shift, M-2 empty name crash |
| PRD-014 | Watch Club / Guild | ✅ Closed | local | QA fixes: C1 direct INSERT bypass (watch_club_members), H1 leave_club race condition, H2 direct INSERT bypass (watch_clubs), M1 leaderboard staleness |
| PRD-015 | Fan Level + XP | ✅ Closed | local | QA fix: C1 grant_xp missing REVOKE FROM PUBLIC (XP exploit) |
| PRD-016 | PostHog Analytics | ✅ Closed | local | QA fix: M1 session_started fires on every profileProvider invalidation |
| PRD-017 | Push Notifications (FCM) | ✅ Closed | local | QA fixes: M1 data values not coerced to strings (FCM rejection), L1 non-stale FCM errors silent |
| PRD-018 | Navigation Restructure + HUD | ✅ Closed | 19296be | QA fixes: M-1 mail badge hardcoded colours (removed placeholder badge) |
| PRD-019 | Continue Watching / My List | ✅ Closed | 19296be | QA fixes: M-1 toggle-saved-drama unchecked insert/delete errors; M-2 missing FK constraints on series_id/episode_id |
| PRD-020 | Discover Screen | ✅ Closed | 19296be | QA fixes: M-1 VIP badge text bgDeep not Colors.white; M-2 onRefresh catchError; L-1 AlwaysScrollableScrollPhysics |
| PRD-021 | Home Screen v5 Redesign | ✅ Closed | 19296be | QA fixes: H-1 timer % _featuredCount not hardcoded 5; M-1 invalidate activeQuestsProvider on refresh; M-2 token colours in QuickLinkCards |
| PRD-022 | My List Series Data Join | ✅ Closed | 79587fa | Clean — no bugs |
| PRD-023 | Meta World Tab | ✅ Closed | e03a80d | QA fixes: M-2 gem rollback re-reads current balance; M-1 mounted guard in _save(); L-1 JWT validated before free-item early return |
| PRD-024 | Inbox with Claimable Rewards | ✅ Closed | e03a80d | QA fixes: C-1 double-claim race via .select('id') on UPDATE; L-1 unused WidgetRef removed from show(); L-2 seed inserts use WHERE NOT EXISTS guard |
| PRD-025 | Cliffhanger / Energy Gate Modal | ✅ Closed | e3e6761 | QA fix: C-1 GoRouter captured before Navigator.pop to prevent use-after-free context |
| PRD-026 | Series Detail Screen v5 | ✅ Closed | e3e6761 | QA fixes: H-1 WidgetRef stored as _RaceBanner field removed; M-1 loading placeholder shows spinner |
| PRD-027 | Daily Streak + Rewards Screen | ✅ Closed | e3e6761 | QA fixes: C-1 atomic increment_currency RPC replaces lost-update pattern; C-2 INSERT RLS gap documented + RPC secured; H-1 date boundary uses tomorrow not 23:59:59; H-2 isToday flag consolidated; M-1 dead streakStart variable removed |
| PRD-028 | Leaderboard — Real Rankings | ✅ Closed | e3e6761 | QA fixes: C-1 races ordered by starts_at (no created_at column); H-1 profiles join uses automatic FK resolution; M-1 Column wrapped in Positioned.fill |
| PRD-029 | Journey Screen | ✅ Closed | b72c104 | QA fix: L-1 hardcoded Color(0xFF333333) in milestone emoji replaced with textDim |
| PRD-030 | Episode End Auto-Advance | ✅ Closed | b72c104 | QA fixes: C-1 context.go('/discover') route not found → /home; H-1 _init() now awaits episodesProvider.future to avoid empty list on direct navigation |
| PRD-031 | Series Completion Modal | ✅ Closed | b72c104 | Covered by PRD-030 QA fixes (same file) |
| PRD-032 | Episode Reactions | ✅ Closed | b72c104 | QA fix: M-1 ReactionRow moved outside synopsis guard — always visible |
| PRD-033 | Profile Edit Screen | ✅ Closed | 37c3d10 | QA fixes: H-1 avatar preview live update (addListener); H-2 clearing avatar sets avatar_url=null explicitly |
| PRD-034 | Push Notification Soft-Ask | ✅ Closed | 37c3d10 | QA fixes: C-1 _softAskInProgress guard prevents concurrent soft-ask; H-1 pre-auth check extended to all platforms |
| PRD-035 | Episode Progress Indicators | ✅ Closed | 37c3d10 | QA fixes: H-1 composite index on watch_progress(user_id,series_id); H-2 invalidate seriesProgressProvider in _onDone() |
| PRD-036 | Series Ratings | ✅ Closed | 37c3d10 | QA fixes: C-1 context.go('/') → /home in completion modal; H-1 myRating cast via (as num?)?.toInt() |
| PRD-037 | IAP / Gem Store | ✅ Closed | ee5238b | Clean — in_app_purchase, validate-iap-receipt Edge Fn, GemStoreScreen, iap_receipts migration |
| PRD-038 | Rewarded Ads | ✅ Closed | 1364469 | Clean — increment-energy Edge Fn, RewardedAdService, _AdButton in EnergyGate (goldGrad, 3/day cap) |
| PRD-039 | Referral System | ✅ Closed | 04a0ab0 | Clean — redeem-referral Edge Fn, referral_code trigger, ReferralScreen, hud invite tile |
| PRD-040 | Onboarding Flow | ✅ Closed | 443e10a | QA fix: M-2 _skip() now invalidates profileProvider for consistency |
| PRD-037 | IAP / Gem Store | ✅ Closed | 443e10a | QA fixes: C-1 all RevenueCat/purchases_flutter removed (5 files); H-2 cancelled completePurchase; H-3 lastValidationError surfaced |
| PRD-038 | Rewarded Ads | ✅ Closed | 443e10a | QA fixes: C-1 grantAdEnergy try-catch in _AdButton; H-2 invalidate adEnergyCapProvider after grant |
| PRD-039 | Referral System | ✅ Closed | 443e10a | QA fixes: C-1 referral code → 12 chars + retry loop (migration 031); H-1 increment_currency errors checked in redeem-referral |
| PRD-044 | Paywall Hardening | ✅ Closed | c87b2a0 + e1a87de | QA fixes: C-1 wrong DROP POLICY name for episode_choices (migration 034); C-2 wrong DROP POLICY name for episode_reactions; H-3 optimistic isUnlocked during loading to prevent flash-of-locked |
| PRD-041 | Social Feed / Activity | ✅ Closed | 75499b4 + e1a87de | QA fixes: C-1 activity_events RLS scoped to followers (migration 035); C-2 INSERT denied for direct client writes; H-4 missing event indexes added; C-7 fetchFeed() now RLS-gated; H-8 Riverpod family comment; C-10 like count double-count fixed with _serverLikedIds sync; H-11 _likedIds seeded from server; M-12 NetworkImage error handler; M-13 created_at null guard |
| PRD-042 | Creator Accounts | ✅ Closed | cf3dd72 + beecf05 | QA fixes: C-1 approve-creator best-effort rollback on partial failure; H-2 rejected users can re-apply (UPDATE not INSERT); H-3 404 on missing creator profile; C-5 session expiry redirects to auth; M-7 _loading reset before navigation; M-9 Colors.white → textCol in hud.dart |
| PRD-043 | Content Upload Pipeline | ✅ Closed | 8f098e0 + beecf05 | QA fixes: C-4 Upload-Length now set from file.size; H-10 fresh token fetched at each Edge Fn call in creator portal |
| PRD-045 | Admin Moderation Dashboard | ✅ Closed | 581750c + 579cc0e | QA fixes: C-1 admin secret moved to server-side API route; C-2 CF URL uses CF_CUSTOMER_SUBDOMAIN; C-3 series INSERT drops non-existent columns; H-4 reject-content status guard; H-5 query error handling; H-6 optimistic lock on approve-content |
| PRD-046 | Revenue Share & Payouts | ✅ Closed | 3d731cd + 579cc0e | QA fixes: C-1 atomic increment_energy_revenue RPC (migration 039); C-2 creator lookup via episodes.creator_id; C-3 upsert with UNIQUE constraint prevents duplicate payouts; H-4 process-payout status update errors handled; H-5 dead payout_email join removed; M-7/8 is_creator guard on earnings screen |
| PRD-047 | Subscription Revenue Attribution | ✅ Closed | 6015a4c | Clean — pass_watch_events table, watch-episode attribution, calculate-monthly-earnings pool split |
| PRD-048 | Creator Analytics Dashboard | ✅ Closed | 2d946e2 | Clean — creator_episode_stats view, CreatorAnalyticsScreen, Analytics tile in creator portal |
| PRD-049 | Public Creator Profiles | ✅ Closed | 78b6776 + 77f3631 | QA fix: C-1 creator_profiles_select_approved policy dropped; public_creator_profiles view owner set to postgres |
| PRD-050 | Creator Notifications | ✅ Closed | 3241b9b + 77f3631 | QA fix: H-2 creator_notifications INSERT wrapped in try-catch in approve-content and reject-content |
| PRD-051 | Series Search | ✅ Closed | fdfa1b4 + 0f2cfd4 | QA fix: M-1 searchQueryProvider reset in dispose() |
| PRD-052 | Following Feed | ✅ Closed | f318c13 | Clean — Following tab with purpleGrad chip, empty state, pull-to-refresh |
| PRD-053 | Creator Profile Editor | ✅ Closed | f7ab122 + 0f2cfd4 | QA fix: M-2 lazy _initControllers via profileAsync.whenData() |
| PRD-054 | Share / Deep Link | ✅ Closed | f7ab122 | Clean — shareSeries/shareCreator via share_plus; deep-link TODO for Sprint 12 |
| PRD-055 | Collectible Card Album | ✅ Closed | 991f931 → c481b55 | QA fixes: H1 mint-collectible race (upsert); H2 _AlbumBanner missing from SeriesScreen |
| PRD-056 | Deep Link Incoming | ✅ Closed | b1127f9 → b67f7c3 | QA fixes: M1 unawaited init() race; L1 auth listener leak in dispose() |
| PRD-057 | Trending Now | ✅ Closed | 6342c72 → 5e9cf69 | QA fix: M1 Trending header leaked into skeleton loading state |
| PRD-058 | Episode Comments | ✅ Closed | fd41d06 → 7573cae | QA fixes: M1 realtime UPDATE events; L1 re-delete 409 guard |
| PRD-059 | Series Completion Reward | ✅ Closed | b6cff8c → e479e03 | QA fixes: H1 coins always credited; L1 ledger idempotency_key |
| PRD-060 | Starter Pack IAP Wire-Up | ✅ Closed | fde92ed → 8ef7fc0 | QA fixes: C1 atomic stamp prevents double-grant race; M1 isDismissible:false prevents swipe-dismiss StateError |
| PRD-061 | Drama Pass IAP Wire-Up | ✅ Closed | 5b7a218 | Clean — activate-drama-pass Edge Fn, onPassPurchase callback, restoreAndCheck with 10s timeout |
| PRD-062 | Notification Preferences | ✅ Closed | 737deba → commit | QA fix: L1 getAccessToken moved after opt-out check |
