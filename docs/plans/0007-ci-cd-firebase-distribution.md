# Plan 0007: CI and CD to Firebase App Distribution

Status: Implemented 2026-11-13, waiting for Fox to add the secrets and push a first tag.

## Outcome

Pushing a tag such as `dev-1.0.0+60` builds the `dev` flavor on GitHub Actions with fastlane and uploads the APK to Firebase App Distribution (project `evermoon-dev`, group `testers`). Every pull request and push to `main` runs analyze and tests.

## Scope

In:

- `ci.yml`: checks on pull requests and pushes to `main`.
- `distribute-dev.yml`: build and upload, on tags `dev-*`.
- fastlane in `android/` (Gemfile, Pluginfile, Appfile, Fastfile) with lanes `build_dev` and `distribute_dev`.
- `docs/ci-cd.md`: secrets, first run, how to release, how to roll back.

Out (decided by Fox, 2026-11-13): iOS (needs an Apple Developer account, ad-hoc profiles and device UDIDs), the `prod` flavor and a release keystore (added together later), Google Play.

## Decisions

| ID   | Decision                                                                                                                                                                                              |
|------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| D-C1 | Android only, `dev` flavor only. Trigger: tag `dev-<name>+<build>`; the version name and build number come from the tag, so the tag is the single source for what testers see.                         |
| D-C2 | Pull requests and `main` pushes only check (analyze, tests); they never publish.                                                                                                                       |
| D-C3 | The dev release APK is signed with the debug key, as `build.gradle.kts` does today. A runner creates a new debug key on every run, and Android refuses to update an app signed with another key, so the workflow restores Fox's own `~/.android/debug.keystore` from a secret. Builds then install over each other and over local debug builds. The debug key is public knowledge (password `android`), so this is a consistency measure, not a secrecy one. |
| D-C4 | No app secret is needed in the build: `assets/env/.env.dev` holds no secret (its own header says so), so CI copies the committed `.example` files. Only `google-services.json` (dev) is a secret, because it is gitignored.                                                  |
| D-C5 | Generated code (`*.g.dart`, `lib/generated/`) is gitignored, so every job runs build_runner and gen-l10n first.                                                                                        |
| D-C6 | Flutter is pinned to the version used locally (3.47.1), actions to major tags (the existing workflow does the same), Ruby to 3.3. fastlane and its plugin are pinned with `~>` ranges (2.241, 1.0); a `Gemfile.lock` is not committed because Bundler does not run on Fox's Mac right now (Homebrew Ruby 4.0.5 fails to load `vendored_net_http`) nor in Claude's sandbox. Commit one once Bundler works. |
| D-C7 | Secrets reach scripts through `env:`, never by putting `${{ secrets.* }}` inside a shell command; the files written from them are removed in a last step that always runs.                              |
| D-C8 | Testers are the Firebase group alias `testers`, so adding a relative later needs no code change.                                                                                                       |

## Acceptance criteria

- CD-1: `ci.yml` is green on a clean checkout (needs build_runner and gen-l10n in the job).
- CD-2: a tag `dev-1.0.0+60` produces an APK with versionName `1.0.0-dev` and versionCode 60 (`aapt dump badging`).
- CD-3: a tag that does not match `dev-<x.y.z>+<n>` fails the workflow before any build.
- CD-4: the APK appears in Firebase App Distribution for `evermoon-dev` and group `testers` is notified.
- CD-5: a second tag installs over the first without uninstalling (same signing key).
- CD-6: no secret value appears in the repository or in the workflow logs.

## Verification

Run locally on Fox's Mac on 2026-11-13: Fastfile syntax OK (`ruby -c`); both workflow files parse as YAML; the exact commands of `build_dev` (pub get, build_runner, `flutter build apk --release --flavor dev ... --build-name=1.0.0 --build-number=60`) built `app-dev-release.apk` (70.9 MB) whose `aapt dump badging` shows `com.fox.evermoon.dev`, versionCode 60, versionName `1.0.0-dev` (CD-2 confirmed locally, so the Crashlytics mapping task works without a login); `dart test` in `packages/lunar_calendar` passes (18). Not run: fastlane itself (Bundler does not work on the Mac, see D-C6) and `bundle lock`. The upload and the workflows themselves can only run on GitHub after Fox adds the secrets, so CD-1 to CD-6 are confirmed by the first runs.

## Risks and checks

| Risk                                                                      | Handling                                                                                       |
|---------------------------------------------------------------------------|------------------------------------------------------------------------------------------------|
| Crashlytics mapping upload fails on the runner during a release build     | Seen in the first CI run; the local `build_dev` run shows whether the task works without login |
| A tag is pushed from a branch other than `main`                           | Documented: tag only `main`; a later step can check the commit is reachable from `main`        |
| The service account lacks the role                                        | Needs "Firebase App Distribution Admin" on `evermoon-dev`; listed in `docs/ci-cd.md`           |
| Free GitHub minutes on a private repository                               | Android builds take about 10 minutes; tags are rare                                            |

## Blockers and next action

Fox adds four items (see `docs/ci-cd.md`): the `GOOGLE_SERVICES_DEV_B64` and `DEBUG_KEYSTORE_B64` and `FIREBASE_SERVICE_ACCOUNT_DEV` secrets, and a `testers` group in App Distribution. Then Fox pushes `main` and a first tag. The older generic guide `doc/manual/FASTLANE_SETUP.md` (three flavors, iOS, Play) stays as background; this plan supersedes it for what is built.
