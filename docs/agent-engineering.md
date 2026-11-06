# Agent engineering workflow

How Claude works on Evermoon. `CLAUDE.md` points here. Explicit task limits and project authorities (`CLAUDE.md`, ADRs, plans) govern over this guide.

## Routing

| Request | Skill |
|---|---|
| Full implementation of a change | `agent-engineering:deliver-change` |
| Plan or revise a plan | `agent-engineering:plan-change` |
| Implement an accepted plan or slice | `agent-engineering:implement-change` |
| Verify against acceptance criteria | `agent-engineering:verify-change` |
| Independent review | `agent-engineering:review-change` |
| Fix validated findings | `agent-engineering:remediate-findings` |
| Commit, push, draft pull request | `agent-engineering:publish-change` (only when authorized) |

A phase skill stops at its own boundary. If a needed skill is missing, report it; do not install it.

## Project decisions

- Requirements and plans: owned by Fox; plans live in `docs/plans/`. A requirements tracker is not chosen yet (status: Pending). Plan 0001 uses criterion IDs `LC-n`.
- Standards: `docs/engineering-standards.md` (rule IDs `EM-*`), backed by `CLAUDE.md`.
- ADRs: `docs/adr/`. Domain vocabulary: `docs/GLOSSARY.md`. Product context: `docs/PRODUCT_BRIEF.md`.
- Branching and commits: short branches, Conventional Commits. There is no git repository yet.
- Verification: Python oracle tests with pytest in `tools/lunar_oracle/`; Dart with `fvm dart analyze` and `fvm dart test`. Neither Dart nor fvm is available in Claude's sandbox, so Fox runs Dart checks locally and Claude reports them as not run.
- Publication: nothing is committed, pushed or published without explicit authorization.

## Adoption record

Adopted 2026-11-04 by Fox. Changes to this workflow are recorded here with a date.
