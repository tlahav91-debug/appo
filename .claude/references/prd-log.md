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
