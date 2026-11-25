# CI and CD

Plan: `docs/plans/0007-ci-cd-firebase-distribution.md`. One branch (`main`). GitHub builds and publishes only the **prod** flavor (Android now, iOS when an Apple Developer account exists) to Firebase App Distribution. **dev** builds are made on your machine when you need them.

## What runs

| Workflow                           | When                                                              | What                                                                                                                                                                                                                                                                                                                         |
|------------------------------------|-------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `.github/workflows/ci.yml`         | every pull request into `main`, and `main` after a merge          | formatting, build_runner, gen-l10n, `flutter analyze`, `flutter test --coverage`, `dart test` in `packages/lunar_calendar`, the SonarQube Cloud scan and its quality gate, the fastlane helper tests, `fastlane lanes`, and a grep that no version, Firebase app id or tester group is written in a workflow or the Fastfile |
| `.github/workflows/distribute.yml` | push to `main` of a release commit (`chore(release): <version>`), or push of a tag equal to the pubspec version (fallback), for example `1.0.1+2` | the release flow below                                                                                                                                                                                                                                                                                                       |

Shared steps are composite actions: `.github/actions/setup` (Flutter, Java, Ruby, env files) and `.github/actions/verify` (the checks of the first row, reused as the release gate).

## Pull requests

Titles follow Conventional Commits (`type(scope): summary`): squash merge makes the title the commit on `main`, and the changelog and the version bump are read from those titles. `.github/pull_request_template.md` fills the description of every new pull request with four sections (Summary, Changes, How it was checked, Notes). The release pull request is the exception: `release_prepare.sh` writes its own title and description, so the template does not apply to it.

## The release flow

`main` is protected by two repository rulesets: `main` accepts only pull requests (squash merge, the `check` job of CI must pass, no force push, no deletion), and tags matching `[0-9]*` cannot be moved, deleted or force-pushed (creating them is allowed). Neither ruleset has a bypass list. A release therefore goes through a pull request, and the merge of that pull request starts it: one command, no second step to wait for.

1. Merge your work into `main` (through pull requests).
2. **Prepare.** On `main`, run `bash scripts/release_prepare.sh` (add `--dry-run` to see every step without changing anything). It shows the current version, the Flutter in use, and the changes since the last release grouped by commit type. It suggests a bump from the Conventional Commit types (`feat` is minor, `fix` is patch, `!` or `BREAKING CHANGE` is major) and asks `Bump to 1.1.0 (y/n)`; `n` lets you type the version. After a final `Go ahead? (y/n)` it creates the branch `release/<x.y.z>`, sets `version:` in `pubspec.yaml` (the build number grows by one, because Android needs a higher code on every upload), commits `chore(release): <version>`, pushes the branch, returns to `main`, and opens the pull request with auto-merge turned on when the GitHub CLI (`gh`) is installed and signed in (otherwise it prints a link with the title and a description, the start of the changelog, already filled in)
3. **Merge.** Without `gh`, open the printed link (the title is `chore(release): <version>`, which squash merge uses as the commit title on `main`, so do not edit it), press Create pull request and then Enable auto-merge. When `check` passes it squash merges by itself, and that merge starts the release. Afterwards run `bash scripts/utils/git_helper.sh clean` (it works after any merged pull request, not only a release): it switches to `main`, pulls it, and deletes the local branches whose branch on origin is gone (GitHub deletes a branch when its pull request merges). Branches that were never pushed or still exist on origin are kept and listed; `--dry-run` shows the plan, `--all` also deletes those, `--yes` skips the question. Each deleted branch prints its commit so it can be restored with `git branch <name> <commit>`.
4. **Tag (fallback only).** Normally there is nothing to run: the workflow tags the commit after a successful build. `bash scripts/release_tag.sh` (also has `--dry-run`) is for the first release or for a run that has to start again from a tag. It fetches origin, reads the version from `pubspec.yaml` on `origin/main`, and refuses unless: the working tree is clean, the version is higher than the last release, the tag does not exist, and the newest commit on `origin/main` is the release commit (its title starts `chore(release): <version>`), so the tag cannot land on a different commit. After `Tag <version> on main? (y/n)` it moves to `main`, pulls with fast-forward only, creates an annotated tag on that commit and pushes the tag. The very first release has nothing to put on a branch: `release_prepare.sh` says so, and only the tag step is needed.
5. The merge (or the tag) starts **Distribute prod**:

| Job       | Does                                                                                                                                                                                                                                                                    |
|-----------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `prepare` | for a tag: stops unless it is `x.y.z+n`, equals the version in `pubspec.yaml`, and its commit is on `main`; for a push to `main`: skips unless the commit title starts `chore(release): <version>` with that version in `pubspec.yaml` and no tag for it yet, so ordinary pushes end here; chooses the platforms; writes the changelog                                                                                                                       |
| `gate`    | the same checks as a pull request (format, analyze, tests)                                                                                                                                                                                                              |
| `android` | restores the prod secrets, builds the signed APK (`build_prod`), checks with `apksigner` that it is signed by the key whose SHA-256 is in the variable `ANDROID_SIGNING_SHA256`, then runs `distribute_prod` to upload it to the prod Firebase app and the tester group |
| `ios`     | the same with `fastlane ios distribute_prod`; runs only when the repository variable `IOS_ENABLED` is `true`                                                                                                                                                            |
| `release` | creates (or updates) the GitHub Release with the changelog, and creates the tag on the built commit when the run started from a push to `main`; it carries no APK                                                                                                                                                                               |
| `notify`  | tells the team how it went, whatever happened                                                                                                                                                                                                                           |

The version testers see is the one in `pubspec.yaml`; the tag only has to match it.

**When a release run fails.** A run that started from the merge to `main` creates the tag only after the build succeeded, so a failure leaves no tag and the same run can simply be re-run (Actions, the run, Re-run failed jobs). Once a tag exists it cannot be moved or deleted. A temporary failure (network, runner, Firebase): "Re-run failed jobs" on the run, or Actions, Distribute prod, Run workflow, from the tag. Both use the workflow file of the tagged commit, so a fix made later on `main` does not apply to them. A failure caused by code, tests, the workflow or the build itself: fix it through a pull request and release the next version (the unused build number is harmless). In an emergency, set the tag ruleset to Disabled in Settings, Rules, Rulesets, make the change, and set it back to Active; only for a tag that has not been released.

## Lanes

fastlane lives at the repository root (`Gemfile`, `Gemfile.lock`, `fastlane/`). The Fastfile contains only lanes; the code they use is in `fastlane/lib/`.

| Lane (per platform: `android`, `ios`) | Does                                                                                                                                |
|---------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------|
| `build_dev`, `build_prod`             | pub get, build_runner, then the release build (APK, or IPA through Xcode). No credentials needed. The artifact is left in `build/`. |
| `build_dev_aab`, `build_prod_aab`     | Android only: the same as an app bundle (`build/app/outputs/bundle/<flavor>Release/app-<flavor>-release.aab`)                       |
| `distribute_dev`, `distribute_prod`   | the matching `build_*`, then uploads to the flavor's Firebase app and tester group                                                  |

Parameters (optional): `build_name:1.0.0 build_number:61 notes:"text"`. Without them the version comes from `pubspec.yaml`. GitHub calls only `distribute_prod`; the `dev` lanes are for your machine.

## Where each value comes from

Nothing below is written in a workflow or the Fastfile; each has one source.

| Value                                 | Source                                                                                                                                                                                                                                                                                                                            |
|---------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Flutter version                       | `environment.flutter` in `pubspec.yaml` (exact, `3.47.1`). CI installs that version and `pub get` refuses any other Flutter locally, so CI and your machine cannot differ. `.fvmrc` stays `stable` and is only for choosing the SDK on your machine. To upgrade, change the pubspec line (and `fvm use <version>`), test, commit. |
| Ruby, Java version                    | `.ruby-version`, `.java-version`                                                                                                                                                                                                                                                                                                  |
| App version                           | `version:` in `pubspec.yaml`; the tag must equal it                                                                                                                                                                                                                                                                               |
| Flavors, Firebase project and app ids | `firebase.json` (written by `flutterfire configure`)                                                                                                                                                                                                                                                                              |
| Tester groups                         | `fastlane/distribution.yml`; `FIREBASE_TESTER_GROUPS` overrides it for one run                                                                                                                                                                                                                                                    |
| iOS bundle id                         | `ios/Flutter/<flavor>-Release.xcconfig`                                                                                                                                                                                                                                                                                           |
| Entry file                            | `lib/main_<flavor>.dart`                                                                                                                                                                                                                                                                                                          |
| Flutter command                       | `fvm flutter` when `fvm` is installed, otherwise `flutter`                                                                                                                                                                                                                                                                        |

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

   | Secret                                                                   | Value                                                                      |
   |--------------------------------------------------------------------------|----------------------------------------------------------------------------|
   | `FIREBASE_SERVICE_ACCOUNT`                                               | the JSON of step 2, as plain text                                          |
   | `GOOGLE_SERVICES_JSON_B64`                                               | `base64 -i android/app/src/prod/google-services.json \| pbcopy`            |
   | `ANDROID_KEYSTORE_B64`                                                   | `base64 -i android/signing/ever_moon_upload.jks \| pbcopy`                 |
   | `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD` | the keystore values                                                        |
   | iOS only, later: `GOOGLE_SERVICE_INFO_PLIST_B64`                         | `base64 -i ios/config/prod/GoogleService-Info.plist \| pbcopy`             |
   | iOS only, later: `ASC_KEY_B64`, `ASC_KEY_ID`, `ASC_ISSUER_ID`            | App Store Connect API key (the `.p8` as base64, its key id, the issuer id) |
   | iOS only, optional: `APPLE_TEAM_ID`                                      | when the team in the Xcode project is not the one to sign with             |

   Also add one **variable** (same page, Variables tab, not a secret): `ANDROID_SIGNING_SHA256`, the SHA256 line printed by `bash scripts/signing_fingerprints.sh`. The release then fails when the APK is signed with any other key. The same script prints the SHA-1 and SHA-256 to add under the prod Android app in Firebase (Project settings, Add fingerprint), which Google sign-in will need. Without the variable the check only reports the signer.

   No `.env` file is a secret: `assets/env/.env.*` are bundled into the app, so anyone with the APK can read them. CI copies the committed `.example` files; put non-secret prod values in `.env.prod.example`.
5. **Notifications.** Add any of these as **repository** secrets (Settings, Secrets and variables, Actions, Repository secrets), not in the environment, so the notify job does not ask for the prod approval again. The job sends to every channel that has its secrets and does nothing when none is set:

   | Channel         | Secrets                                  | How to get them                                                                                                                                 |
   |-----------------|------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------|
   | Telegram        | `TELEGRAM_BOT_TOKEN`, `TELEGRAM_CHAT_ID` | create a bot with BotFather, add it to the chat, read the chat id from `https://api.telegram.org/bot<token>/getUpdates` after sending a message |
   | Discord         | `DISCORD_WEBHOOK_URL`                    | channel settings, Integrations, Webhooks, New Webhook, copy the URL                                                                             |
   | Microsoft Teams | `TEAMS_WEBHOOK_URL`                      | channel, Workflows, "Post to a channel when a webhook request is received", copy the URL                                                        |

6. **iOS switch.** When the Apple account and the iOS secrets exist, set the repository **variable** `IOS_ENABLED` to `true` (Settings, Secrets and variables, Actions, tab Variables, New repository variable). It is not in any file. Until then the iOS job is skipped and a release stays green. The testers' devices must be registered in the Apple account (ad-hoc export).

## Code quality with SonarQube Cloud

CI sends the app to SonarQube Cloud after the tests and waits for its quality gate (`sonar.qualitygate.wait`). A failed gate fails the step, so the required check `check` blocks the merge and auto-merge waits. The scope is in `sonar-project.properties` (the app and the `lunar_calendar` sources; generated code and `lib/firebase` are excluded). Coverage comes from `flutter test --coverage` (`coverage/lcov.info`); the `verify` action writes it only when CI asks for it, the release gate does not. `packages/lunar_calendar` is analyzed but not counted in coverage, because its tests (`dart test`) are not in that report.

One-time setup:

1. Sign in to https://sonarcloud.io with GitHub, create or choose an organization, install the Sonar GitHub App for `ever_moon` and import the repository. Pick "With GitHub Actions" when asked how to analyze.
2. In the project, Administration, Analysis Method: turn **Automatic Analysis off** (it conflicts with the CI scan and cannot read the coverage file).
3. In the project, Administration, New Code: choose "Reference branch" and `main`, so a pull request is judged on the code it changes.
4. Create a token (account, Security, Generate tokens) and store it as the repository **secret** `SONAR_TOKEN`. Store the organization key and the project key as repository **variables** `SONAR_ORGANIZATION` and `SONAR_PROJECT_KEY` (Settings, Secrets and variables, Actions). Neither is in any file.
5. After the first run on `main`, the check name `check` stays the same, so the ruleset needs no change.

A pull request from a fork or from Dependabot gets no secret: the scan is skipped with a warning and `check` can still pass. The default "Sonar way" gate asks for 80 % coverage on new code and fails on new bugs, vulnerabilities, hotspots not reviewed and duplication above 3 %; copy it in Quality Gates and relax the coverage condition if UI code makes it too strict.

## Build dev on your machine

Needs Ruby from `.ruby-version` (rbenv: `rbenv install` in the repository) and Bundler. Homebrew's Ruby 4.x does not work with Bundler on this Mac; use rbenv.

```bash
bundle config set --local path vendor/bundle   # once; the folder is gitignored
bundle install
bundle exec fastlane lanes
bash scripts/build.sh                                        # asks flavor (prod/dev) and type (apk/aab), runs the lane
bundle exec fastlane android build_dev                       # APK only
bundle exec fastlane android build_dev_aab                   # app bundle only
FIREBASE_SERVICE_CREDENTIALS=/path/to/service-account.json \
  bundle exec fastlane android distribute_dev                # build and upload to the dev Firebase project
bundle exec ruby fastlane/test/evermoon_test.rb              # the helper tests
```

Java: Flutter ignores `JAVA_HOME` and uses the JDK of Android Studio (a newer JBR) unless told otherwise, which prints a Gradle "restricted method" warning and differs from CI. Point it at the JDK in `.java-version` once per machine: `fvm flutter config --jdk-dir "/Library/Java/JavaVirtualMachines/zulu-17.jdk/Contents/Home"` (it writes `jdk-dir` in `~/.config/flutter/settings`; delete that line to undo).

`dev` is uploaded to project `evermoon-dev`, so it needs a service account of that project and a tester group there. `prod` on your machine needs `android/key.properties`. On iOS, `build_*` signs with the Apple account logged in to Xcode unless `ASC_KEY_PATH`, `ASC_KEY_ID` and `ASC_ISSUER_ID` are all set.

## Changelog, artifacts and how long things stay

- The **GitHub Release** of each tag is the permanent changelog (no expiry). Its text comes from `scripts/release_notes.sh`: commits since the previous release, grouped as breaking changes, features, fixes and other changes. It is also the Firebase release note and the body of the notification.
- **Notification look.** Discord gets a colored embed (status color, fact fields, changelog) plus the release link in the message text, so Discord unfolds the repository preview. Telegram gets formatted text, buttons (release, run) and the release link preview. Teams gets a card with the status header, facts, changelog and two buttons. Every channel has two pictures. The **banner** is `docs/design/notify-banner.png` (the moon), at the top of all three: the first image of the Teams card, a first embed in Discord, and a photo Telegram receives just before the message (a link preview cannot share a message with a photo; the photo is sent silently). The **release preview** is the image of the GitHub release page (its `og:image`): Telegram unfolds the link itself, Discord gets the image URL in its embed, and the Teams card shows it at the bottom. The workflow reads the URL from the release page and requests it once first (GitHub draws it on the first request, which can take seconds). Teams does not load that URL even when it answers `200 image/png`, so for Teams `scripts/og_image_data_uri.sh` downloads the image, shrinks it to about 11 KB (ImageMagick, installed on the runner when missing) and embeds it as a data URI; `notify.sh` shortens the changelog so the whole message stays under the 28 KB limit of Teams, and drops the preview if it still does not fit. The banner is passed by its raw GitHub URL only when the file exists. The repository must be public for the pictures to load.
- GitHub keeps workflow logs and artifacts for 90 days by default (changeable in the repository settings). This workflow uploads no artifact.
- The APK is not attached to the Release: a public repository would let anyone download the prod build. The build is in Firebase App Distribution; how long Firebase keeps a release was not verified.

## Pinned actions

Every third-party action in `.github/` is pinned to a full commit SHA with the version in a trailing comment, for example `actions/checkout@<sha> # v7.0.1`. A tag such as `v7` can be moved to different code; a commit SHA cannot, and SonarQube Cloud rates an unpinned action as a security issue. Actions of this repository (`uses: ./.github/actions/...`) need no pin. The first pins (2026-11-19) kept the major versions then in use. Dependabot's first pull request (merged 2026-11-20) moved several to a new major: `checkout` v7, `setup-java` v6, `upload-pages-artifact` v5, `deploy-pages` v5 and the SonarQube scan action v8. The version in each trailing comment is the current one. The release workflow has not run since that bump.

`.github/dependabot.yml` opens one pull request on the first day of each month (it was weekly until 2026-11-20) that moves the SHAs and the version comments together (title `chore(ci): ...`). It ignores new major versions (an `ignore` rule for `version-update:semver-major`), so only minor and patch bumps arrive; read the release notes before merging. A new major is moved by hand: change the SHA and the version comment together (see below), then check the next release run. To stop Dependabot altogether, delete the file. To pin a new action by hand: `git ls-remote --tags https://github.com/<owner>/<repo>` and take the SHA of `refs/tags/<version>^{}` when that line exists (an annotated tag), otherwise of `refs/tags/<version>`.

## Not verified

- Verified on GitHub (2026-11-19): release 1.2.0+7 went through the push-to-`main` path. Fox ran only `release_prepare.sh` and merged the pull request; the tag `1.2.0+7` exists and Fox confirmed the run and the notification previews. So the `prepare` branch logic, the tag created by `gh release create --target` (the tag ruleset allows it) and the Release creation work. Not seen yet: a release run after the action bump of 2026-11-20 (checkout v7, setup-java v6), the skip path on an ordinary push to `main`, and a failed run followed by "Re-run failed jobs" (none of these is recorded as checked). `actionlint` is not installed. What ran locally before that: the YAML parses, the `prepare` step text runs correctly against a scratch repository (valid tag, tag different from `pubspec.yaml`, bad format, not a tag, commit not on `main`), and `scripts/release_prepare.sh`, `release_tag.sh`, `release_notes.sh` and `notify.sh` ran against a scratch repository with a fake origin on macOS's bash 3.2 (for the two release scripts: dry run and real run of each step, a release branch that already exists, tagging before the pull request is merged, tagging twice, a commit that lands after the release commit, and a dirty working tree). The rulesets were checked on GitHub: a direct push to `main` and the deletion of a release tag are rejected, and a pull request merged with `check` passing.
- Notifications: delivery to Teams, Discord and Telegram happened on real releases and Fox confirmed the previews look as designed (2026-11-19). Not recorded as checked: the message of a failed release, and the 28 KB limit of Teams with a very long changelog.
- iOS: only the Flutter step (`flutter build ios --no-codesign`) can be checked without an Apple account. Archive, signing, ad-hoc export and upload are unproven.
- The Xcode project's team id (`9W96R5ZZY4`) differs from the id in the older guide `doc/manual/FASTLANE_SETUP.md` (`GH2PAB3V62`); confirm which belongs to the account you will use.

## Keep out of the repository

Service account JSON, `google-services.json`, `GoogleService-Info.plist`, keystores, `key.properties`, `.p8` keys, webhook URLs. `.gitignore` covers the files; the workflows delete the files they write in a last step that always runs.

## Later

- Google Play (internal track) and TestFlight for prod: new lanes next to `distribute_prod`, using the keystore and the App Store Connect key already here.
