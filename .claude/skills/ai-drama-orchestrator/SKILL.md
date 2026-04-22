# Orchestrator Skill — AI Drama Game

## Role
Orchestration hub. PM is the sole user-facing agent. All subagents are spawned and their output summarised by the PM.

## Workflow per feature
1. PM writes PRD (consult Economy/Monetisation if relevant)
2. PM presents PRD → user approves
3. PM logs approval in prd-log.md
4. PM briefs Architect → Architect builds on feature branch
5. PM reviews Architect output → if gaps, send back with gap list
6. PM briefs QA → QA tests
7. If Critical/High bugs → PM briefs Architect fix → QA re-tests
8. PM logs bugs in bug-log.md
9. PM reports to user → merges to develop → updates prd-log
10. PM proposes next feature

## References
- Sprint build order: references/sprint-1-build-order.md
- PRD log: references/prd-log.md
- Bug log: references/bug-log.md
- Agent briefing formats: agents/pm-subagent.md
