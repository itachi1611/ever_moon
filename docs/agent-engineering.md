# Agent engineering workflow

How Claude works on Evermoon. `CLAUDE.md` points here. Explicit task limits and project authorities (`CLAUDE.md`, ADRs, plans) govern over this guide.

## Routing

| Request                             | Skill                                                     |
|-------------------------------------|-----------------------------------------------------------|
| Full implementation of a change     | `agent-engineering:deliver-change`                        |
| Plan or revise a plan               | `agent-engineering:plan-change`                           |
| Implement an accepted plan or slice | `agent-engineering:implement-change`                      |
| Verify against acceptance criteria  | `agent-engineering:verify-change`                         |
| Independent review                  | `agent-engineering:review-change`                         |
| Fix validated findings              | `agent-engineering:remediate-findings`                    |
| Commit, push, draft pull request    | `agent-engineering:publish-change` (only when authorized) |

A phase skill stops at its own boundary. If a needed skill is missing, report it; do not install it.

## Project decisions

- Requirements and plans: owned by Fox; plans live in `docs/plans/`. A requirements tracker is not chosen yet (status: Pending). Plan 0001 uses criterion IDs `LC-n`.
- Standards: `docs/engineering-standards.md` (rule IDs `EM-*`), backed by `CLAUDE.md`.
- ADRs: `docs/adr/`. Domain vocabulary: `docs/GLOSSARY.md`. Product context: `docs/PRODUCT_BRIEF.md`.
- Branching and commits: short branches, Conventional Commits. The git repository exists (first commits 2026-11-06); Fox makes the commits, or asks Claude to commit on his Mac (git through the Mac terminal, never in the sandbox; since 2026-11-11). Claude uses only read-only git in the sandbox (`git --no-optional-locks status`, `log`, `diff`), because index-writing commands there leave a stale `.git/index.lock` that blocks Fox's git.
- Verification: Python oracle tests in `tools/lunar_oracle/` (`python3 -m unittest discover -s tests -v`); Dart with `fvm dart analyze` and `fvm dart test`; the app with `fvm flutter analyze`, `fvm flutter test` and a run on an Android device. Neither Dart nor fvm is available in Claude's sandbox, so Fox runs these checks locally and Claude reports them as not run until Fox shares the output. Claude gives the exact commands and the expected output for every check it asks Fox to run. Since 2026-11-06 Fox lets Claude run these commands on the Mac terminal itself (fvm, flutter, build_runner); Claude still does not commit, push or publish.
- Publication: nothing is committed, pushed or published without explicit authorization.

## Adoption record

Adopted 2026-11-04 by Fox. Changes to this workflow are recorded here with a date.

- 2026-11-06: Claude may run build, analyze and test commands on Fox's Mac terminal.
- 2026-11-06: git repository in use; read-only git for Claude; every check Claude asks Fox to run comes with exact commands and expected output.
- 2026-11-11: when Fox asks, Claude commits on the Mac terminal (scanning for unused files first and asking before deleting); never pushes.
