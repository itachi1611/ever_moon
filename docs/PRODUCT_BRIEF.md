# Evermoon: Product Direction Brief

Date: 2026-11-04. Source: product brainstorm between Fox and Claude. Translated from the original Vietnamese version.

## 1. Vision

Evermoon lets people **register yearly events on lunar dates and get reminded on the right day**, first of all death anniversaries ("giỗ"). Showing the Vietnamese lunar calendar is a supporting feature, not the core. A plain lunar calendar is a saturated category. Reminding on the correct anniversary day is a real pain point that Google Calendar does not solve (iCal/RRULE has no lunar recurrence).

**Job to be done:** "When the death anniversary or lunar-date milestone of a relative comes, I want to be reminded on the right day so that I never forget and never get the wrong date."

## 2. Users and phases

1. **Phase 1 (personal):** Fox is the user, tracking 10 to 30 events.
2. **Phase 2 (groups):** younger family members who want to keep the anniversary calendar of ancestors and grandparents. Build this only after 3 to 5 relatives have tried and actually used the personal version.

Riskiest assumption: do younger people really want to keep the anniversary calendar, or only their parents? A cheap test: share an anniversary card through Zalo before building any group system.

## 3. MVP (phase 1)

- Correct lunar calendar display with the matching solar date and weekday.
- Create yearly anniversary events on lunar dates (day and month required, year optional).
- System events: the 1st and 15th of each lunar month, and traditional Tết festivals (the user only toggles reminders).
- Local notification on the exact anniversary day. No (day-before) reminder.
- Home screen is an "upcoming" list with a countdown.
- Offline-first.

Deferred: profiles for the deceased (relationship, burial place, offering notes), first and final anniversary milestones, prayers and offering guides (possible premium feature), sync to the system calendar.

## 4. Leap month and day-30 rules

Decided based on the family's real data (people remember day and month, often not the year):

- An anniversary stores **lunar day + lunar month** (required) and **death year** (optional, not strictly validated).
- Only day and month entered: the anniversary always falls in the **regular month**.
- Year entered: the app checks whether that year has a leap month with the same number as the entered month. If the person died in that leap month:
  - in years that have a leap month with the same number, the anniversary falls in **that leap month**;
  - in all other years, it falls in the **regular month**, so an anniversary never disappears.
- The "died in leap month" toggle is shown only when the entered year really has a leap month with that number (otherwise the entered month is not ambiguous).
- Day 30 in a month that has only 29 days: fall back to day 29.
- No manual override (regular / leap / both) in the first version.

**Note:** these are design rules based on how the family does it. They are not verified as a universal tradition.

## 5. Lunar calendar algorithm

- Based on the published rules of Dr. Hồ Ngọc Đức: compute new moon times in time zone **UTC+7**; the month containing the winter solstice is month 11; if two consecutive month 11s are 13 months apart, the year has a leap month; the leap month is the first month without a major solar term (trung khí).
- Do not use a Chinese-calendar library (UTC+8); results can differ on some dates because the lunar calendar depends on the time zone.
- We build our own pure-Dart package, `packages/lunar_calendar`, for lunar years 1800 to 2199, from the published rules and astronomical formulas (the original JavaScript is not copied). It sits behind our own interface. See [plan 0001](plans/0001-lunar-package.md).
- The "year modulo 19" formula is only a mental shortcut and must not be used in code.
- The astronomy can differ by a day in a few edge cases (events within about a minute of midnight), so tests compare with an independent oracle.

See ADR 0001 and ADR 0002 in `docs/adr/` for the recorded decisions.

## 6. Group permissions (phase 2)

- Roles: **Owner**, **Editor**, **Viewer**. Multiple owners are allowed.
- The owner names a successor in advance.
- Fallback when all owners are inactive for a long time (for example 6 to 12 months): a member requests ownership, another editor confirms, and there is a waiting period during which the previous owner can object.
- "Request edit rights" and "request ownership" are separate flows.
- Use gentle wording, because an inactive owner may have passed away.

## 6a. Account features, phased

Decided 2026-11-05. Groups stay gated by the existing rule: build them only after 3 to 5 relatives use the personal version.

1. **v1 (offline):** no login required. Events and reminders are stored on the device; reminders are local notifications.
2. **Optional login for backup and sync:** restore after changing phones, multiple devices. Stable IDs; last write wins by `updatedAt`; deletes use `deletedAt`.
3. **Share card for one anniversary:** a card or link sent through Zalo or similar; the receiver needs no account and can add it to their own calendar. Also, the cheap test of demand.
4. **Family groups (phase 2):** roles, successor and ownership flows as in section 6. Extra group features agreed in principle: assign a host ("chủ giỗ") per anniversary, attendance confirmation and contribution checklist, notes and photos about the deceased (burial place, favorite offerings), and a change history (who edited what). Owners can send notices to members through FCM, for example to merge a giỗ with another family event.

Technical direction: Firebase (auth, Firestore for sync and groups, FCM, Crashlytics). Two Firebase projects, `evermoon-dev` and `evermoon-prod`. FCM is sent only from a Cloud Function that verifies the caller is an owner (Blaze plan on prod). Android is the main platform; iOS is not built for now (no Apple Developer account, so no iOS push). Store requirements once accounts exist: in-app account deletion and a privacy policy that covers data about deceased people and family members.

## 7. Risks and things to verify

| Item                                                                            | Approach                                                                               | Status                                         |
|---------------------------------------------------------------------------------|----------------------------------------------------------------------------------------|------------------------------------------------|
| Lunar calendar accuracy                                                         | Test against an independent oracle for lunar years 1800 to 2199 plus published anchors | Oracle and Python reference done; Dart pending |
| Edge cases near midnight                                                        | Pinned list of 13 months in 6 years; decided: follow the author's convention           | Documented                                     |
| Family custom for leap months                                                   | Ask elders in the family                                                               | Not started                                    |
| Demand from younger relatives                                                   | 3 to 5 relatives try the personal version                                              | Not started                                    |
| Reliable local notifications (iOS limits the number of scheduled notifications) | Schedule a short window and resync periodically                                        | Needs design                                   |

## 8. Next steps

1. Finish the `lunar_calendar` package (see [plan 0001](plans/0001-lunar-package.md)): scaffold, Dart port, Dart tests run locally.
2. Technical analysis and selection for the remaining areas (notifications, storage, calendar UI).
3. Scaffold the Flutter project `ever_moon` (fvm, Cubit, GoRouter, Vietnamese ARB) and integrate the package behind `LunarCalendarService`.
4. Anniversary data model (day, month, optional death year, `diedInLeapMonth`, day 30).
5. "Upcoming" screen and local notifications.
