# Bug Log

## PRD-017 — Push Notifications (FCM)

| ID | Title | Severity | Status |
|----|-------|----------|--------|
| BUG-017-M1 | data map values not coerced to strings — FCM rejects non-string values silently | Medium | ✅ Fixed — safeData coercion in sendFcmMessage |
| BUG-017-L1 | Non-UNREGISTERED FCM failures fully silent — indistinguishable from "no tokens" | Low | ✅ Fixed — errors[] array in response |

## PRD-016 — PostHog Analytics

| ID | Title | Severity | Status |
|----|-------|----------|--------|
| BUG-016-M1 | session_started fires on every profileProvider invalidation (not just cold start) | Medium | ✅ Fixed — _hasTrackedSession flag on ProfileNotifier |

## PRD-015 — Fan Level + XP

| ID | Title | Severity | Status |
|----|-------|----------|--------|
| BUG-015-C1 | grant_xp missing REVOKE FROM PUBLIC — authenticated users can grant arbitrary XP | Critical | ✅ Fixed — migration 000018 revokes PUBLIC EXECUTE |



| ID | Title | Severity | Status |
|----|-------|----------|--------|
| BUG-014-C1 | Direct INSERT into watch_club_members bypasses join guards | Critical | ✅ Fixed — migration 000015 drops INSERT policy |
| BUG-014-H1 | leave_club missing FOR UPDATE → zombie clubs | High | ✅ Fixed — migration 000015 rewrites leave_club with lock |
| BUG-014-H2 | Direct INSERT into watch_clubs bypasses create guard | High | ✅ Fixed — migration 000015 drops INSERT policy |
| BUG-014-M1 | Leaderboard scores stale on episode watch | Medium | ✅ Fixed (partial) — second Realtime channel on user_episode_choices; current user refreshes live, other members refresh on membership event |

## PRD-013 — Character Affinity

| ID | Title | Severity | Status |
|----|-------|----------|--------|
| C-1 | Channel created outside try block (channel leak) | Critical | ✅ Fixed |
| H-3 | ref.watch in StreamProvider body (infinite rebuild) | High | ✅ Fixed |
| H-4 | Banner layout shift from stream-derived bool | High | ✅ Fixed |
| M-2 | Empty character name crash in substring(0,1) | Medium | ✅ Fixed |

## PRD-012 — Lava Quest Event Engine

| ID | Title | Severity | Status |
|----|-------|----------|--------|
| BUG-001 | Non-atomic claim reward (race condition) | Critical | ✅ Fixed |
| BUG-002 | increment_quest_progress missing service_role grant | High | ✅ Fixed |
| BUG-006 | questByIdProvider stale (separate FutureProvider) | High | ✅ Fixed |
| BUG-012 | Animation started during build phase | Medium | ✅ Fixed |
| BUG-013 | Idempotent claim showed duplicate reward toast | Medium | ✅ Fixed |

## PRD-011 — Series Race Leaderboard

| ID | Title | Severity | Status |
|----|-------|----------|--------|
| C-1 | increment_race_score GRANT to authenticated (score spoofing) | Critical | ✅ Fixed |
| C-2 | joinRace silently swallowed failure response | Critical | ✅ Fixed |
| C-3 | Realtime channel created outside try (channel leak) | Critical | ✅ Fixed |
| H-1 | Double race score on repeated choices | High | ✅ Fixed |
| H-2 | ref.read in FutureProvider.family (stale providers) | High | ✅ Fixed |
| H-3 | Race banner always showed "tap to join" | High | ✅ Fixed |
| H-4 | Countdown flash to "Race Ended" on load | High | ✅ Fixed |
| M-5 | raceJoinProvider was singleton (shared join state) | Medium | ✅ Fixed |

## PRD-049 — Public Creator Profiles

| ID | Title | Severity | Status |
|----|-------|----------|--------|
| BUG-049-C1 | creator_profiles_select_approved policy exposes payout_email to all authenticated users via direct table query | Critical | ✅ Fixed — policy dropped; public_creator_profiles view owner set to postgres (bypasses RLS internally); GRANT SELECT on view to authenticated |

## PRD-050 — Creator Notifications

| ID | Title | Severity | Status |
|----|-------|----------|--------|
| BUG-050-H2 | approve-content and reject-content return HTTP 500 on creator_notifications INSERT failure even though core operation succeeded | High | ✅ Fixed — notification INSERT wrapped in try-catch in both functions; failure logged, not propagated |

## PRD-051 — Series Search

| ID | Title | Severity | Status |
|----|-------|----------|--------|
| BUG-051-M1 | searchQueryProvider (global non-autoDispose StateProvider) retains last query after SearchScreen disposed — reopening screen shows empty field but stale results | Medium | ✅ Fixed — reset to '' in SearchScreen.dispose() |

## PRD-052 — Following Feed

| ID | Title | Severity | Status |
|----|-------|----------|--------|
| (none) | — | — | Clean pass |

## PRD-053 — Creator Profile Editor

| ID | Title | Severity | Status |
|----|-------|----------|--------|
| BUG-053-M2 | initState read creatorProfileProvider.valueOrNull synchronously — if provider not yet cached (direct navigation), all form fields init empty; bio could be saved blank overwriting existing value | Medium | ✅ Fixed — controllers lazy-initialized via profileAsync.whenData(_initControllers) with _initialized guard |

## PRD-054 — Share / Deep Link

| ID | Title | Severity | Status |
|----|-------|----------|--------|
| (none) | — | — | Clean pass |
