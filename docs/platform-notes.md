# Platform notes

Android is the main target. iOS code is kept but not built for now (no Apple Developer account). Other platforms are kept in the repo; this file records where they differ. It is not a promise that they are tested.

| Topic                                               | Android                                                                                                              | iOS                                                      | Web / desktop                                                           |
|-----------------------------------------------------|----------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------|-------------------------------------------------------------------------|
| Build status                                        | Main target                                                                                                          | Not built                                                | Not built                                                               |
| Local notifications (`flutter_local_notifications`) | Supported; exact alarms need a permission on Android 12+                                                             | Supported; the system limits pending notifications to 64 | Limited or unsupported on web; check each desktop platform              |
| FCM push                                            | Works with `google-services.json`                                                                                    | Needs an APNs key from a paid Apple Developer account    | Web needs a VAPID key; desktop is not supported by `firebase_messaging` |
| Firebase options                                    | Generated for dev and prod                                                                                           | Generated if built                                       | Not generated (`lib/firebase` covers android and ios only)              |
| `permission_handler`                                | Supported                                                                                                            | Supported                                                | Not supported on web                                                    |
| Time zone                                           | UTC+7 is used for lunar rules regardless of device time zone (ADR 0002); the device zone matters only for scheduling | same                                                     | same                                                                    |
| Flavors                                             | `dev` and `prod`                                                                                                     | schemes and xcconfig for `dev` and `prod`                | not configured                                                          |

Update this table when a new platform-specific behavior is found.

