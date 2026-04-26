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
