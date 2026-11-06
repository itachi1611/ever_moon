# Plan 0002: Template cleanup for Evermoon

Status: Decisions approved by Fox on 2026-11-05 (except the open rows). Implementation in slices; each slice is verified by Fox with `fvm flutter pub get` and `fvm dart analyze` (Claude's sandbox has no Dart SDK).

## Context

The repo was cloned from Fox's Flutter base template (package `flutter_base`, applicationId `com.fox.base.flutter`). Local packages were moved from `pkgs/` to `packages/`. Evermoon v1 is offline-first and personal; an optional login (backup and sync) comes after v1, then share cards, then groups (see the product brief).

## Decisions

| Area | Decision |
|---|---|
| Platforms | Android is the main target. iOS code is kept but not built (no Apple Developer account, so no APNs and no iOS push). `web`, `windows`, `linux`, `macos` are kept; differences are recorded in `docs/platform-notes.md`. |
| Firebase projects | Two projects: `evermoon-dev` and `evermoon-2cc28` (prod; display name "evermoon", the plain id was taken). No separate UAT. |
| Flavors | `dev` and `prod` only. Remove `uat` (Android flavor, iOS xcconfig and schemes, entry file, scripts, CI, `.env`). |
| Package id | Dart package `ever_moon`. Android namespace, applicationId and iOS bundle id `com.fox.evermoon`; dev uses the suffix `.dev`. Register the new ids as apps in each Firebase project. |
| Firebase services | Keep `firebase_core`, `firebase_auth`, `firebase_ui_*`, `firebase_messaging`, `firebase_crashlytics`. Remove `firebase_remote_config`. Auth is optional in v1: the app must work without login. |
| FCM | Kept for owner-to-member notices in groups. Sending goes through a Cloud Function that checks the caller's role (needs Blaze on prod, phase 2). Reminders stay local notifications. |
| Database | Local database for v1 (chosen in the technical analysis). Firestore for sync and groups (phase 2). |
| Network | Keep `dio`, `retrofit`, `pretty_dio_logger`, `retrofit_generator`, `json_serializable`, `connectivity_plus`, `lib/network`, `NetworkService`. Dead code in v1 until phase 2. |
| AI | Remove `genkit`, `genkit_google_genai`, `lib/pages/ai_support/`, `ai_service.dart`, `GENKIT.md`. |
| Demo pages | Remove `service`, `explore`, `home_detail`, `intro`. |
| Packages | Remove `packages/dart_cli`, `packages/game_cli`, `scripts/dart_cli.sh`. Keep `pigeon` (native calls later). `animation_kit` and `animation_text`: remove if unused after the page cleanup. |
| Locales | Keep `en` and `vi`. Remove `ja`. |
| Storage | Keep both `get_storage` and `shared_preferences`. |
| Env | Keep `AppEnv` and `flutter_dotenv`. Commit `assets/env/.env.<flavor>.example`; `scripts/setup_env.sh` generates `.env.<flavor>`. Never put real secrets there: assets are bundled into the app. Server keys live in Cloud Functions. |

## Slices

| Slice | Content | Status |
|---|---|---|
| C1 | Remove `dart_cli`, `game_cli`, their script and CI references; remove locale `ja` | Done, analyzed |
| C2 | Remove AI (genkit, page, service) and demo pages (`service`, `explore`, `home_detail`, `intro`); fix routes and shell tabs | Done, analyzed. Also removed `animation_kit`, `animation_text` (only the service demo used them), the `email_validator` override and `GENKIT.md` |
| C3 | Remove `firebase_remote_config` and `uat` flavor everywhere | Done in Dart, Android, scripts, pubspec, env (analyzed, no issues). iOS done on 2026-11-05: `uat` xcconfigs, scheme and `project.pbxproj` configurations removed; the project keeps `Debug`/`Release`/`Profile` × `dev`/`prod` and the schemes `Runner`, `dev`, `prod` |
| C8 | iOS dependency manager: Swift Package Manager only, remove leftover CocoaPods integration | Done on 2026-11-05 by Fox (`pod deintegrate`; removed `Podfile`, `Podfile.lock`, `Pods/`, the `Pods.xcodeproj` workspace reference, the `#include? "Pods/..."` lines and the empty `Pods` group). `pubspec.yaml` sets `flutter: config: enable-swift-package-manager: true`. All iOS plugins resolve through `FlutterGeneratedPluginSwiftPackage`. Not yet built (see Open) |
| C4 | Rename to `ever_moon` and `com.fox.evermoon` (Dart imports, `test/`, Android Kotlin folders, Pigeon, iOS, macOS, Linux, web manifest); regenerate Pigeon | Done by text replacement (analyzed, no issues). Firebase projects: dev `evermoon-dev`, prod `evermoon-2cc28`. Firebase regenerated on 2026-11-06 with `scripts/config_firebase.sh`: `firebase_options.dart`, `android/app/src/<flavor>/google-services.json` and `ios/config/<flavor>/GoogleService-Info.plist` point to the new projects; Email/Password and Google sign-in enabled; debug SHA-1 registered on both Android apps (OAuth client present); iOS `REVERSED_CLIENT_ID` in `ios/Flutter/<flavor>-*.xcconfig` updated from the new plists. `firebase.json` was regenerated and no longer lists `uat` or `f-base-*` |
| C5 | Env: `.env.*.example`, `setup_env.sh`, pubspec assets; replace the stale `test/widget_test.dart` | Done. Examples exist for dev and prod; `test/routing/routers_test.dart` replaces the counter test (run `fvm flutter test`) |
| C6 | Review of unused UI packages and images | Packages with no import removed: `flutter_animate`, `google_fonts`, `lottie`, `collection`, `firebase_ui_oauth` (transitive). Unreferenced assets are NOT deleted: 25 images in `assets/images` (9 MB, bundled into the APK) and `assets/lotties/404.json`; Fox decides which to keep |
| C7 | Refresh `README.md`, `CLAUDE.md`, `GEMINI.md`, `PERMISSIONS.md` | Done: README rewritten, GEMINI.md now points to CLAUDE.md, FASTLANE_SETUP renamed, ANIMATION.md (flutter_animate guide) removed. `PERMISSIONS.md` is a generic `permission_handler` reference and is kept as is |

## Acceptance

- CL-1: `fvm dart analyze` reports zero warnings and `fvm flutter test` passes after each slice.
- CL-2: No remaining reference to removed packages, flavors or paths in `pubspec.yaml`, `lib/`, scripts, CI and docs.
- CL-3: `CLAUDE.md` matches the remaining structure.
- CL-4: The app starts and works without login and without a network.

## Open

- Auth is kept, but the router currently forces login. The v1 behavior (no forced login) is implemented in C2.
- C6 list of UI packages and images, pending review.
- Firebase files are gitignored. A fresh clone must run `scripts/config_firebase.sh` before building. The root copies (`android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`) hold the last flavor configured (prod); the flavor folders are the source of truth.
- iOS not yet built after C8 and the Firebase regeneration: `fvm flutter build ios --flavor dev -t lib/main_dev.dart --debug --no-codesign`. The duplicate `GoogleService-Info.plist` file reference in `project.pbxproj` was removed on 2026-11-06.
- Pigeon: `pigeon/api.dart` `kotlinOut` still pointed to the old `com/fox/base/flutter` folder, so the Android build had two `PigeonApi.g.kt` files (Kotlin redeclaration errors). Fixed on 2026-11-06: `kotlinOut` now targets `com/fox/evermoon/generated/` and the old folder is deleted. iOS still has duplicate copies: Xcode compiles `ios/generated/` and `ios/Bridge/`, while Pigeon writes `ios/Runner/generated/` and `ios/Runner/Bridge/` also exists. Pick one location when iOS is revived.
- Release builds need the release-key and Play App Signing SHA-1 added to the prod Android app before Google sign-in works in production.
