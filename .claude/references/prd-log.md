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
| PRD-018 | Navigation Restructure + HUD | 🔄 QA | 7c326b3 | Nav: Home/Discover/MyList/Rewards/Meta; VIP bar; mail icon; Events+Journey cards on Home; Rankings on Rewards |
| PRD-019 | Continue Watching / My List | 🔄 QA | c9b0a19 | watch_progress + saved_dramas tables; record-watch-progress + toggle-saved-drama Edge Fns; MyListScreen 3 tabs |
| PRD-020 | Discover Screen | 🔄 QA | 11ec88f | Search + genre filter + trending row + 3-col grid; allSeriesProvider |
| PRD-021 | Home Screen v5 Redesign | 🔄 QA | 3e178f0 | Hero carousel (auto-scroll 4s); Continue Watching strip; quick links; drama grid; club strip |
