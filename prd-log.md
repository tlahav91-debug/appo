# PRD Log

| ID | Feature | Status | Bugs found | Bugs fixed | Commit(s) |
|----|---------|--------|------------|------------|-----------|
| PRD-065 | Creator Live Q&A | ✅ Shipped | BUG-065-C1 (race cond. start-qa-session) | ✅ | 78fdf47 |
| PRD-066 | Fan Q&A Submission | ✅ Shipped | BUG-066-M1 (input visible pre-live) | ✅ | fb57744 |
| PRD-067 | Creator Series Management | ✅ Shipped | BUG-067-C2 (orphaned draft), BUG-067-H3 (premature submit), M3-cosmetic | ✅ | 950d6fb, a035e48 |
| PRD-068 | Creator Earnings Dashboard | ✅ Shipped | BUG-068-C2 (auth substring bypass), BUG-068-H2 (missing UNIQUE constraint), BUG-068-H3 (button hidden during load) | ✅ | df44de8, a9920be |
| PRD-069 | Creator Analytics: Real Play Counts | ✅ Shipped | BUG-069-C1 (serial loop timeout), BUG-069-H1 (CF URL params broken), BUG-069-L2 (zero completion insight) | ✅ | 41337f6, 4797cef |
| PRD-070 | Fan Discovery & Home Feed Redesign | ✅ Shipped | BUG-070-H1 (spotlight view no GRANT), BUG-070-M1 (anon RPC exposure), BUG-070-M2 (view ORDER BY unreliable), BUG-070-M3 (following strip UUID order) | ✅ | 1f21fb5, a0b867e, 826baed |
| PRD-071 | Fan Episode Reactions (12 emojis) | ✅ Shipped | none | — | a07ca4d |
| PRD-072 | Push Notifications: new episode + streak reminder | ✅ Shipped | BUG-072-H1 (PostgREST 1000-row truncation) | ✅ | d3260f1, 76d9c48 |
| PRD-073 | Admin Content Moderation Screen | ✅ Shipped | BUG-073-M1 (context after pop crash), BUG-073-M2 (missing row limit) | ✅ | 2d455a9, d319afa |
| PRD-075 | Creator Payout Admin Panel | ✅ Shipped | BUG-075-H1 (FK join mismatch in get-admin-payouts) | ✅ | e28745c, f2a2c25 |
| PRD-077 | Fan Public Profile Page | ✅ Shipped | BUG-077-C1 (profiles_select_public exposes sensitive fields), BUG-077-H1 (creator_follows FK join broken) | ✅ | 045afd6, 2671fe1 |
| PRD-078 | Rewarded Ads: Coin Refill Sheet | ✅ Shipped | BUG-078-M1 (GoRouter after Navigator.pop in _goToShop), BUG-078-L1 (unused router var) | ✅ | 37a9527, 0120c8c |
| PRD-081 | Daily Login Reward Calendar | ✅ Shipped | BUG-081-C1 (race condition double-claim), BUG-081-L1 (non-const TextStyle) | ✅ | 9bffa8f, 0282566, ce355b2, a0e1939 |
| PRD-086 | Leaderboard: Weekly + Friends Filter | ✅ Shipped | BUG-086-M1 (get_friends_leaderboard viewer_id exposes any user's friend list) | ✅ | e81de83, d39ceb7, 18c9648, fc3a468 |
| PRD-087 | Achievement Badge System | ✅ Shipped | BUG-087-H1 (self-grant exploit — no condition check), BUG-087-H2 (XP via raw UPDATE bypasses level-up), BUG-087-H3 (PK conflict returns 500 instead of already_earned) | ✅ | 1a1425a, 4053a85 |
| PRD-088 | Series Completion Reward | ✅ Shipped | BUG-088-H1 (achievement level-up discarded from response), BUG-088-M1 (seriesCompletionsProvider not invalidated after completion), BUG-088-M2 (completionCount error unguarded) | ✅ | 47660ff, 4053a85 |
| PRD-089 | Fan Level-Up Overlay & Perks Screen | ✅ Shipped | BUG-089-CRITICAL1 (claim-daily-reward: non-existent 'scrolls' column — daily reward always 500s), BUG-089-HIGH1 (profile null after invalidate — XP bar never shown in LevelUpDialog), BUG-089-LOW1 (LevelPerksScreen "X XP away" labels misleading for non-adjacent levels) | ✅ | ec43308 |
| PRD-090 | VIP Episode Coin Unlock | ✅ Shipped | BUG-090-CRITICAL1 (coin refund uses null updatedProfile — sets balance to cost instead of restoring), BUG-090-HIGH1 (FunctionException not caught in _coinUnlock — INSUFFICIENT_COINS shown as raw error), BUG-090-MEDIUM1 (EpisodeCard hides energy cost when coin cost present) | ✅ | ec43308 |
| PRD-093 | Timed Series Marathon Event | ✅ Shipped | BUG-093-CRITICAL1 (marathon double coin grant via concurrent claim race — upsert not idempotent for coin credit), BUG-093-MEDIUM1 (_ClaimButton stored WidgetRef as StatefulWidget field — stale ref risk) | ✅ | ec43308 |
