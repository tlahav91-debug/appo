# PM Subagent Briefing Format

## How to brief the Architect

```
ARCHITECT BRIEF — [Feature Name]
PRD ID: PRD-[NNN]
Branch: feature/[feature-name-kebab-case]

SCHEMA:
[Table definitions, RLS requirements]

EDGE FUNCTIONS:
[Function names, methods, auth, request/response shapes]

FLUTTER:
[Screens affected, state to read/write, components to create/update]

SEED DATA:
[Any seed data required in supabase/seed.sql]

DESIGN TOKENS:
[Specific tokens to use for this feature]

ACCEPTANCE CRITERIA:
[Copied from PRD]
```

## How to brief QA

```
QA BRIEF — [Feature Name]
PRD ID: PRD-[NNN]
Branch: feature/[feature-name-kebab-case]

HAPPY PATH:
[Step-by-step normal flow]

EDGE CASES:
[Boundary conditions to test]

EXPLOIT TESTS:
[Economy/IAP specific attack vectors if applicable]

RLS TABLES TO VERIFY:
[List of new tables]

ACCEPTANCE CRITERIA:
[Copied from PRD]
```

## How to brief Growth

Consult Growth before writing any PRD that touches:
- Push notifications (any tier)
- Streak mechanics or re-engagement timing
- Energy reminder scheduling
- Notification copy or opt-out preferences

```
GROWTH BRIEF — [Feature Name]
PRD ID: PRD-[NNN]

CONTEXT:
[What the user was doing when they left / what triggered the notification need]

NOTIFICATION TYPE:
[New / change to existing — include notification_type key]

QUESTIONS:
[What the PM needs Growth to decide — timing, copy, tier, frequency cap]

CONSTRAINTS:
[Any existing notification_prefs keys that must not conflict]
```
