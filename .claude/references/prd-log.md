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
| PRD-022 | My List Series Data Join | 🔄 QA | 79587fa | Supabase nested joins for watch_progress + saved_dramas; real titles + cover art in My List |
| PRD-023 | Meta World Tab | 🔄 QA | 69878e8 | meta_unlocks + user_meta_profile tables; unlock-meta-item + equip-meta-item Edge Fns; MetaWorldScreen |
| PRD-024 | Inbox with Claimable Rewards | 🔄 QA | 903716f | inbox_items table; claim-inbox-reward + send-inbox-message Edge Fns; InboxScreen modal; HUD badge |
