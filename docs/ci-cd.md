# CI and CD

Plan: `docs/plans/0007-ci-cd-firebase-distribution.md`. Scope today: Android, `dev` flavor, Firebase App Distribution.

## What runs

| Workflow                           | When                                 | What                                                                                       |
|------------------------------------|--------------------------------------|--------------------------------------------------------------------------------------------|
| `.github/workflows/ci.yml`         | every pull request, every push to `main` | pub get, build_runner, gen-l10n, `flutter analyze`, `flutter test`, `dart test` in `packages/lunar_calendar` |
| `.github/workflows/distribute-dev.yml` | push of a tag `dev-<x.y.z>+<n>`      | fastlane `distribute_dev`: builds the dev release APK and uploads it to Firebase App Distribution |

The fastlane files are in `android/` (`Gemfile`, `fastlane/Fastfile`, `Appfile`, `Pluginfile`).

## One-time setup

1. **Firebase App Distribution.** In the Firebase console, project `evermoon-dev`: open Release and Monitor, App Distribution, accept the terms for the Android app `com.fox.evermoon.dev`, and create a tester group named `testers` (alias `testers`). Add the emails.
2. **Service account.** Google Cloud console, project `evermoon-dev`: IAM and Admin, Service Accounts, create one (for example `github-distribute`), give it the role **Firebase App Distribution Admin**, create a JSON key. The whole JSON file is the secret value.
3. **GitHub secrets** (repository Settings, Secrets and variables, Actions, Repository secrets):

| Secret                         | Value                                                                                      |
|--------------------------------|--------------------------------------------------------------------------------------------|
| `FIREBASE_SERVICE_ACCOUNT_DEV` | the service account JSON, as plain text                                                    |
| `GOOGLE_SERVICES_DEV_B64`      | `base64 -i android/app/src/dev/google-services.json \| pbcopy` (macOS)                      |
| `DEBUG_KEYSTORE_B64`           | `base64 -i ~/.android/debug.keystore \| pbcopy`                                            |

`DEBUG_KEYSTORE_B64` makes CI sign with the same debug key as your local builds. Without it each run would use a new key and Android would refuse to install a build over the previous one. It is the public Android debug key (password `android`), not a store key.

The Firebase app id of the dev app is in the Fastfile (not a secret). Set `FIREBASE_APP_ID_DEV` or `FIREBASE_TESTER_GROUPS` as environment variables only to override the defaults.

## Release a dev build

Tag a commit on `main` and push the tag. The build number must grow with every tag.

```bash
git tag dev-1.0.0+60
git push origin dev-1.0.0+60
```

The tag sets the version: name `1.0.0` (shown as `1.0.0-dev`) and code `60`. A tag that does not match `dev-<x.y.z>+<n>` stops the workflow before the build. Testers get an email and the build appears in the App Distribution app.

To re-run a failed upload, delete the tag on GitHub and push it again, or use "Re-run jobs" on the workflow run.

## Run the same lanes locally

Needs a working Ruby 3.x with Bundler (the Homebrew Ruby 4.0.5 on the Mac failed to load Bundler on 2026-11-13; use rbenv with Ruby 3.3). Once `bundle install` works, commit `android/Gemfile.lock`.

```bash
cd android
bundle install
bundle exec fastlane android build_dev build_name:1.0.0 build_number:60
FIREBASE_SERVICE_CREDENTIALS=/path/to/service-account.json \
  bundle exec fastlane android distribute_dev build_name:1.0.0 build_number:60
```

Locally Flutter runs through `fvm`; the workflow sets `FLUTTER_CMD=flutter` and `DART_CMD=dart`.

## Keep out of the repository

Service account JSON, `google-services.json`, keystores, `.p8` keys. `.gitignore` already covers the first two and the keystores; the workflow deletes the files it writes in a last step that always runs.

## Later

- `prod` flavor: needs a release keystore (`android/key.properties`, see `doc/manual/FASTLANE_SETUP.md`, A2 and A3), a `distribute_prod` lane and a `prod-*` tag trigger. The prod Firebase app is in project `evermoon-2cc28`.
- iOS: an Apple Developer account, ad-hoc profiles (or match) and the testers' device UDIDs, and a macOS job.
- Google Play: after the prod keystore exists.
