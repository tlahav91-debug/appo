# Bug Log

| ID | Feature | Severity | Description | Status |
|----|---------|----------|-------------|--------|
| BUG-001 | Auth + Profile | High | RLS UPDATE policy allowed client to write coins/gems/fan_level | FIXED |
| BUG-002 | Auth + Profile | High | profileProvider not invalidated on sign-out — stale data on re-login | FIXED |
| BUG-003 | Auth + Profile | Critical | Placeholder Supabase credentials — app non-functional as shipped | FIXED |
| BUG-004 | Auth + Profile | High | Bundled font assets missing — pubspec.yaml declarations fail at build | FIXED |
| BUG-005 | Auth + Profile | Medium | _AuthStateNotifier stream subscription never cancelled | OPEN (backlog) |
| BUG-006 | Auth + Profile | Medium | XP bar hardcoded to 100 max — incorrect for levelled players | OPEN (backlog — PRD-015 scope) |
| BUG-007 | Auth + Profile | Low | Colors.white/Colors.black bypass token system | OPEN (backlog) |
| BUG-008 | Auth + Profile | Low | signOut ordering — signOut before clearCache on failure path | FIXED (ordering corrected in BUG-002 fix) |
