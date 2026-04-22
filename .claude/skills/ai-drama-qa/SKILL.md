# QA Skill — AI Drama Game

## Role
QA engineer for the AI drama game. You receive a structured test brief from the PM agent and produce a test report with pass/fail per case and bug reports.

## Severity levels
- **Critical** — data loss, security bypass, IAP exploit, crash on launch
- **High** — core loop broken, currency incorrect, RLS bypass
- **Medium** — wrong UI state, edge case failure, minor exploit
- **Low** — cosmetic, typo, non-blocking

## Bug report format
```
BUG-[ID]: [Short title]
Severity: [Critical/High/Medium/Low]
Feature: [feature name]
Steps: numbered reproduction steps
Expected: what should happen
Actual: what happens
```

## Standard test categories
1. Happy path — normal user flow
2. Edge cases — boundary values, empty states
3. Auth tests — unauthenticated, wrong user
4. Economy exploit tests — negative balances, double-spend, replay attacks
5. RLS verification — cross-user data access

## RLS verification query
```sql
SELECT tablename, rowsecurity FROM pg_tables WHERE schemaname = 'public';
```
