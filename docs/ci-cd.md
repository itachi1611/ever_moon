# CI and CD

Plan: `docs/plans/0007-ci-cd-firebase-distribution.md`. One branch (`main`). GitHub builds and publishes only the **prod** flavor (Android now, iOS when an Apple Developer account exists) to Firebase App Distribution. **dev** builds are made on your machine when you need them.

## What runs

| Workflow                           | When                                   | What |
|------------------------------------|----------------------------------------|------|
| `.github/workflows/ci.yml`         | every pull request into `main`         | formatting, build_runner, gen-l10n, `flutter analyze`, `flutter test`, `dart test` in `packages/lunar_calendar`, the fastlane helper tests, `fastlane lanes`, and a grep that no version, Firebase app id or tester group is written in a workflow or the Fastfile |
| `.github/workflows/distribute.yml` | push of a tag equal to the pubspec version, for example `1.0.1+2` | the release flow below |

Shared steps are composite actions: `.github/actions/setup` (Flutter, Java, Ruby, env files) and `.github/actions/verify` (the checks of the first row, reused as the release gate).

## The release flow

1. Merge your work into `main`.
2. On `main`, run `bash scripts/distribution.sh` (add `--dry-run` to see every step without changing anything). It shows the current version, the Flutter in use, and the changes since the last release grouped by commit type. It suggests a bump from the Conventional Commit types (`feat` is minor, `fix` is patch, `!` or `BREAKING CHANGE` is major) and asks `Bump to 1.1.0 (yes/no)`; `no` lets you type the version. After a final confirmation it sets `version:` in `pubspec.yaml` (the build number grows by one, because Android needs a higher code on every upload), commits `chore(release): <version>`, tags it and pushes the commit and the tag. The very first release offers to release the current version as it is.
3. The tag starts **Distribute prod**:

| Job       | Does |
|-----------|------|
| `prepare` | stops unless the tag is `x.y.z+n`, equals the version in `pubspec.yaml`, and its commit is on `main`; chooses the platforms; writes the changelog |
| `gate`    | the same checks as a pull request (format, analyze, tests) |
| `android` | restores the prod secrets, builds the signed APK (`build_prod`), checks with `apksigner` that it is signed by the key whose SHA-256 is in the variable `ANDROID_SIGNING_SHA256`, then runs `distribute_prod` to upload it to the prod Firebase app and the tester group |
| `ios`     | the same with `fastlane ios distribute_prod`; runs only when the repository variable `IOS_ENABLED` is `true` |
| `release` | creates (or updates) the GitHub Release for the tag with the changelog; it carries no APK |
| `notify`  | tells the team how it went, whatever happened |

The version testers see is the one in `pubspec.yaml`; the tag only has to match it. To re-run a failed release use "Re-run jobs" on the run, or Actions, Distribute prod, Run workflow, from the tag.

## Lanes

fastlane lives at the repository root (`Gemfile`, `Gemfile.lock`, `fastlane/`). The Fastfile contains only lanes; the code they use is in `fastlane/lib/`.

| Lane (per platform: `android`, `ios`) | Does |
|---------------------------------------|------|
| `build_dev`, `build_prod`             | pub get, build_runner, then the release build (APK, or IPA through Xcode). No credentials needed. The artifact is left in `build/`. |
| `distribute_dev`, `distribute_prod`   | the matching `build_*`, then uploads to the flavor's Firebase app and tester group |

Parameters (optional): `build_name:1.0.0 build_number:61 notes:"text"`. Without them the version comes from `pubspec.yaml`. GitHub calls only `distribute_prod`; the `dev` lanes are for your machine.

## Where each value comes from

Nothing below is written in a workflow or the Fastfile; each has one source.

| Value                         | Source |
|-------------------------------|--------|
| Flutter version               | `environment.flutter` in `pubspec.yaml` (exact, `3.47.1`). CI installs that version and `pub get` refuses any other Flutter locally, so CI and your machine cannot differ. `.fvmrc` stays `stable` and is only for choosing the SDK on your machine. To upgrade, change the pubspec line (and `fvm use <version>`), test, commit. |
| Ruby, Java version            | `.ruby-version`, `.java-version` |
| App version                   | `version:` in `pubspec.yaml`; the tag must equal it |
| Flavors, Firebase project and app ids | `firebase.json` (written by `flutterfire configure`) |
| Tester groups                 | `fastlane/distribution.yml`; `FIREBASE_TESTER_GROUPS` overrides it for one run |
| iOS bundle id                 | `ios/Flutter/<flavor>-Release.xcconfig` |
| Entry file                    | `lib/main_<flavor>.dart` |
| Flutter command               | `fvm flutter` when `fvm` is installed, otherwise `flutter` |

## One-time setup

1. **Firebase App Distribution**, project `evermoon-2cc28` (prod): Release and Monitor, App Distribution, accept the terms for the Android app (and the iOS app), create the tester group named in `fastlane/distribution.yml` (`testers`) and add the emails.
2. **Service account.** Google Cloud console, project `evermoon-2cc28`: IAM and Admin, Service Accounts, create one (for example `github-distribute`) with the role **Firebase App Distribution Admin**, create a JSON key.
3. **Prod keystore (Android).** You create it, so only you know the password. Keep a backup outside this machine; losing it means installed apps cannot be updated.

   ```bash
   mkdir -p android/signing
   keytool -genkey -v -keystore android/signing/ever_moon_upload.jks \
     -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

   For prod builds on your machine create `android/key.properties` (gitignored; `storeFile` is relative to `android/app`):

   ```properties
   storePassword=...
   keyPassword=...
   keyAlias=upload
   storeFile=../signing/ever_moon_upload.jks
   ```

   A `prod` release build without a keystore fails on purpose; it is never signed with the debug key. `dev` builds use the debug key.
4. **GitHub Environment `prod`.** Repository Settings, Environments, New environment `prod`; add these secrets. You can also require a reviewer there, so each release waits for your approval (Android and iOS each ask once).

   | Secret | Value |
   |--------|-------|
   | `FIREBASE_SERVICE_ACCOUNT` | the JSON of step 2, as plain text |
   | `GOOGLE_SERVICES_JSON_B64` | `base64 -i android/app/src/prod/google-services.json \| pbcopy` |
   | `ANDROID_KEYSTORE_B64` | `base64 -i android/signing/ever_moon_upload.jks \| pbcopy` |
   | `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD` | the keystore values |
   | iOS only, later: `GOOGLE_SERVICE_INFO_PLIST_B64` | `base64 -i ios/config/prod/GoogleService-Info.plist \| pbcopy` |
   | iOS only, later: `ASC_KEY_B64`, `ASC_KEY_ID`, `ASC_ISSUER_ID` | App Store Connect API key (the `.p8` as base64, its key id, the issuer id) |
   | iOS only, optional: `APPLE_TEAM_ID` | when the team in the Xcode project is not the one to sign with |

   Also add one **variable** (same page, Variables tab, not a secret): `ANDROID_SIGNING_SHA256`, the SHA256 line printed by `bash scripts/signing_fingerprints.sh`. The release then fails when the APK is signed with any other key. The same script prints the SHA-1 and SHA-256 to add under the prod Android app in Firebase (Project settings, Add fingerprint), which Google sign-in will need. Without the variable the check only reports the signer.

   No `.env` file is a secret: `assets/env/.env.*` are bundled into the app, so anyone with the APK can read them. CI copies the committed `.example` files; put non-secret prod values in `.env.prod.example`.
5. **Notifications.** Add any of these as **repository** secrets (Settings, Secrets and variables, Actions, Repository secrets), not in the environment, so the notify job does not ask for the prod approval again. The job sends to every channel that has its secrets and does nothing when none is set:

   | Channel | Secrets | How to get them |
   |---------|---------|-----------------|
   | Telegram | `TELEGRAM_BOT_TOKEN`, `TELEGRAM_CHAT_ID` | create a bot with BotFather, add it to the chat, read the chat id from `https://api.telegram.org/bot<token>/getUpdates` after sending a message |
   | Discord | `DISCORD_WEBHOOK_URL` | channel settings, Integrations, Webhooks, New Webhook, copy the URL |
   | Microsoft Teams | `TEAMS_WEBHOOK_URL` | channel, Workflows, "Post to a channel when a webhook request is received", copy the URL |

6. **iOS switch.** When the Apple account and the iOS secrets exist, set the repository **variable** `IOS_ENABLED` to `true` (Settings, Secrets and variables, Actions, tab Variables, New repository variable). It is not in any file. Until then the iOS job is skipped and a release stays green. The testers' devices must be registered in the Apple account (ad-hoc export).

## Build dev on your machine

Needs Ruby from `.ruby-version` (rbenv: `rbenv install` in the repository) and Bundler. Homebrew's Ruby 4.x does not work with Bundler on this Mac; use rbenv.

```bash
bundle config set --local path vendor/bundle   # once; the folder is gitignored
bundle install
bundle exec fastlane lanes
bundle exec fastlane android build_dev                       # APK only
FIREBASE_SERVICE_CREDENTIALS=/path/to/service-account.json \
  bundle exec fastlane android distribute_dev                # build and upload to the dev Firebase project
bundle exec ruby fastlane/test/evermoon_test.rb              # the helper tests
```

`dev` is uploaded to project `evermoon-dev`, so it needs a service account of that project and a tester group there. `prod` on your machine needs `android/key.properties`. On iOS, `build_*` signs with the Apple account logged in to Xcode unless `ASC_KEY_PATH`, `ASC_KEY_ID` and `ASC_ISSUER_ID` are all set.

## Changelog, artifacts and how long things stay

- The **GitHub Release** of each tag is the permanent changelog (no expiry). Its text comes from `scripts/release_notes.sh`: commits since the previous release, grouped as breaking changes, features, fixes and other changes. It is also the Firebase release note and the body of the notification.
- GitHub keeps workflow logs and artifacts for 90 days by default (changeable in the repository settings). This workflow uploads no artifact.
- The APK is not attached to the Release: a public repository would let anyone download the prod build. The build is in Firebase App Distribution; how long Firebase keeps a release was not verified.

## Not verified

- The workflows have not run on GitHub yet; the first tag run confirms them. `actionlint` is not installed. What ran locally: the YAML parses, the `prepare` step text runs correctly against a scratch repository (valid tag, tag different from `pubspec.yaml`, bad format, not a tag, commit not on `main`), and `scripts/distribution.sh`, `release_notes.sh` and `notify.sh` ran against a scratch repository with a fake origin on macOS's bash 3.2.
- Notifications: the Discord and Telegram requests and the Teams card were built and checked as valid JSON, never sent to a real service.
- iOS: only the Flutter step (`flutter build ios --no-codesign`) can be checked without an Apple account. Archive, signing, ad-hoc export and upload are unproven.
- The Xcode project's team id (`9W96R5ZZY4`) differs from the id in the older guide `doc/manual/FASTLANE_SETUP.md` (`GH2PAB3V62`); confirm which belongs to the account you will use.

## Keep out of the repository

Service account JSON, `google-services.json`, `GoogleService-Info.plist`, keystores, `key.properties`, `.p8` keys, webhook URLs. `.gitignore` covers the files; the workflows delete the files they write in a last step that always runs.

## Later

- Google Play (internal track) and TestFlight for prod: new lanes next to `distribute_prod`, using the keystore and the App Store Connect key already here.
