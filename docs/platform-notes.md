# Platform notes

Android is the main target. iOS code is kept but not built for now (no Apple Developer account; CI builds only Android while `IOS_ENABLED` is unset). Other platforms are kept in the repo; this file records where they differ. It is not a promise that they are tested.

| Topic                                               | Android                                                                                                              | iOS                                                      | Web / desktop                                                           |
|-----------------------------------------------------|----------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------|-------------------------------------------------------------------------|
| Build status                                        | Main target                                                                                                          | Not built                                                | Not built                                                               |
| Local notifications (`flutter_local_notifications`) | Supported; verified on Pixel 8 and Pixel 5. On Android 14 the "Alarms and reminders" permission is off by default; without it a reminder is inexact (about 5 minutes late). The app asks for it (onboarding and a Settings row) and does not use `USE_EXACT_ALARM` (Play policy). Alarms survive a restart (boot receiver) but a force-stop removes them until the app is opened again | Supported; the system limits pending notifications to 64, the planner keeps 60. Untested; the soft bell file is not in the Xcode project yet, so iOS plays the default sound | Limited or unsupported on web; check each desktop platform              |
| FCM push                                            | Works with `google-services.json`                                                                                    | Needs an APNs key from a paid Apple Developer account    | Web needs a VAPID key; desktop is not supported by `firebase_messaging` |
| Firebase options                                    | Generated for dev and prod                                                                                           | Generated if built                                       | Not generated (`lib/firebase` covers android and ios only)              |
| `permission_handler`                                | Supported                                                                                                            | Supported                                                | Not supported on web                                                    |
| Time zone                                           | UTC+7 is used for lunar rules regardless of device time zone (ADR 0002); the device zone matters only for scheduling: reminders fire at the wall-clock time of the device's zone, and a time zone change re-plans them through a native receiver even when the app is closed (plan 0006, N7a). Some phones report the old zone name `Asia/Saigon`, which is mapped to a known zone | same                                                     | same                                                                    |
| Flavors                                             | `dev` and `prod`                                                                                                     | schemes and xcconfig for `dev` and `prod`                | not configured                                                          |

Update this table when a new platform-specific behavior is found.

## Android TV (added 2026-11-13)

Fox's test device: Sony KD-65X85L (Google TV; Android version not published by Sony, one third-party listing says 10, to be read from Settings > Device Preferences > About). Step (a), the minimum to install and open the app, is in place; step (b), using it comfortably with a remote, has no plan yet.

Done (a):
- `AndroidManifest.xml`: `touchscreen` and `leanback` features with `required="false"` (the same APK still installs on phones), a second `MAIN` intent filter with `LEANBACK_LAUNCHER`, and `android:banner="@drawable/tv_banner"`.
- `res/drawable/tv_banner.xml`: layer list of the launcher background colour (teal-grey in the dev flavor) and the E8 mark. It has no app name; a published TV listing needs a raster 320x180 banner with the name.
- `lib/utils/device_form_factor.dart` (`isAndroidTv()`, reads the `android.software.leanback` system feature through `device_info_plus`) and `main.dart`: the portrait lock is skipped on TV.
- One Gradle resource and manifest pass (`:app:processDevDebugResources`) succeeded; no build or run on a TV yet.

Known gaps for (b), to confirm on the TV:
- Navigation is by D-pad; the screens were designed for touch. Focus highlights, the drawer, the calendar's swipe edit and delete (no D-pad equivalent) and the add button need checking.
- The layout is portrait phone-first; a TV renders about 960x540 dp, landscape.
- Reminders: before Android 13 there is no notification permission dialog, and exact alarms need no permission before Android 12. How Google TV shows app notifications, and whether a TV in standby fires alarms, is unverified (plan 0006, N5).
- Install and run: enable developer options, network debugging, `adb connect <ip>:5555`, then `fvm flutter run -d <id> --flavor dev -t lib/main_dev.dart`.

