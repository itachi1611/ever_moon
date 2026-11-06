# Engineering standards index

Stable rule IDs so that plans, reviews and findings can cite them. The full text lives in `CLAUDE.md` (hard rules and domain rules); this file is an index, not a second authority. If they disagree, `CLAUDE.md` wins.

## State and navigation

- EM-STATE-1: Cubit (flutter_bloc) only; one Cubit per page, created in `initState`, closed in `dispose`.
- EM-STATE-2: States are sealed and extend Equatable; never one class with nullable fields; no `setState` for business logic.
- EM-NAV-1: GoRouter only; the `Routes` enum comes first, then `router_config.dart`; navigate with `context.go()` or `context.goNamed()`.

## Code and widgets

- EM-CODE-1: Comments in English; `///` DartDoc for public API; explain why, not what.
- EM-CODE-2: `async`/`await` only; avoid `!` (justify with a comment when unavoidable).
- EM-CODE-3: Every `catch` logs or rethrows; use `AppLogger`, never bare `print()`.
- EM-CODE-4: Functions of at most 20 lines; zero warnings from `fvm dart analyze`.
- EM-UI-1: Each distinct UI piece is its own widget class; no `_buildX()` helpers; `const` where possible; `ListView.builder` for dynamic lists.
- EM-UI-2: No hardcoded colors, paddings, dimensions or user-visible strings; use theme, `AppColors`, `AppDimensions` and `S.of(context)` (Vietnamese primary).
- EM-GEN-1: Run build_runner after `@JsonSerializable` edits and `intl_utils:generate` after ARB edits; never hand-edit generated files.

## Domain

- EM-DOM-1: Day and month are required for anniversaries; the death year is optional and never hard-validated (ADR 0001).
- EM-DOM-2: Month selection and day-30 fallback follow ADR 0001.
- EM-DOM-3: Vietnamese rules with UTC+7; never a Chinese-calendar library (ADR 0002).
- EM-DOM-4: Lunar engine tests compare to fixtures from the independent oracle; no expected solar dates from memory or from the code under test.
- EM-DOM-5: No `year % 19` leap shortcut in code.
- EM-ARCH-1: Offline-first; stable IDs on every entity.

## Process

- EM-PROC-1: Documents go in `docs/`, English only.
- EM-PROC-2: Toolchain through fvm only.
- EM-PROC-3: Conventional Commits and short branches; nothing is committed, pushed or published without explicit authorization.
