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
