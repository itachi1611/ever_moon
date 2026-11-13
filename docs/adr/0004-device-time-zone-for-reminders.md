# ADR 0004: Device time zone for reminders

Status: Accepted (2026-11-12, plan 0006 D-R3, chosen by Fox).

## Context

A reminder stores a wall-clock time ("07:00"), not an instant. To schedule it, the platform plugin needs a zoned time, so the app must know the phone's current time zone. Relatives may live abroad, so a fixed Vietnam zone (UTC+7) would fire at the wrong local hour for them. The `timezone` package (already a dependency) holds the zone database but cannot read the phone's zone.

## Decision

- Add `flutter_timezone` (5.1.1, checked on pub.dev and in the pub cache on 2026-11-12): its iOS side ships a Swift Package Manager manifest (`ios/flutter_timezone/Package.swift`), so it fits the "no CocoaPods" rule from plan 0002 C8; Android uses Gradle.
- `FlnNotificationBackend` reads the zone name before every replace and sets `tz.local`; the planner's wall-clock times become zoned times through `zonedWallClock`. Changing the phone's zone therefore moves reminders to the same local time at the next sync (the app re-plans on every start and resume).
- If the zone name is unknown to the `timezone` database, the previous zone stays and a warning is logged.

## Consequences

- One more plugin on both platforms; it is only used inside `lib/services/reminders/`.
- A reminder at a time that does not exist locally (daylight-saving gap) is shifted forward by the `timezone` package.
- Build on both platforms was not run when this was written (see plan 0006, N2); the first iOS or Android build after this change confirms the plugin resolves.

## Alternatives considered

- Fixed `Asia/Ho_Chi_Minh`: no dependency, wrong for relatives abroad.
- Deriving the zone from `DateTime.now().timeZoneOffset`: gives an offset, not a zone with daylight-saving rules, so reminders would drift after a clock change.
