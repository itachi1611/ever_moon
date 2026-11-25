# Plan 0007: CI and CD to Firebase App Distribution

Status (2026-11-20): implemented and running on GitHub. Revision 5 is the current release flow (merge of the release pull request starts the release); revision 6 adds SonarQube Cloud, pinned actions and Dependabot. Releases 1.0.0+1 to 1.2.0+7 are tagged on `origin`; Fox confirmed the notification previews on 1.2.0+7. Open: iOS (no Apple Developer account, `IOS_ENABLED` stays off), `gh` not installed on Fox's Mac, Firebase release retention unverified. Revisions 1 to 4 below are kept as history; where a later revision changes a decision, the row says "Superseded".

## Outcome

Revision 3 (the flow is superseded by revisions 4 and 5; the script was `distribution.sh`, renamed `release_firebase.sh` on 2026-11-19): `scripts/distribution/release/release_firebase.sh` bumps the version in `pubspec.yaml`, commits, tags `x.y.z+n` on `main` and pushes. The tag builds the **prod** flavor on GitHub Actions with fastlane, uploads it to Firebase App Distribution (project `evermoon-2cc28`), publishes a GitHub Release with the changelog and notifies the team. iOS only when the repository variable `IOS_ENABLED` is `true`. Every pull request into `main` runs format, analyze and tests. `dev` builds are made locally.

Revision 4 (2026-11-19): `main` is protected by a ruleset without a bypass list (pull requests only, squash merge, `check` must pass, no force push, no deletion) and release tags `[0-9]*` are immutable (no update, delete or force push; creation allowed). `scripts/distribution/release/release_firebase.sh` can no longer push to `main`, so it only creates `release/<x.y.z>` with the version bump and prints the pull request to open (titled `chore(release): <version>`); after the squash merge `scripts/distribution/release/release_tag.sh` checks that the newest commit on `origin/main` is that release commit and creates and pushes the tag. D-C19 below describes the original single-script flow.

Revision 5 (2026-11-19, Fox: "no second step to wait for"): the merge of the release pull request starts the release. `release_firebase.sh` opens the pull request with auto-merge (when `gh` is available); the push of the `chore(release): <version>` commit to `main` triggers `distribute.yml`, whose `prepare` job skips every other push, and the `release` job creates the tag on the built commit after a successful build. A pushed tag still works (`release_tag.sh`, the fallback for the first release or a re-run). Decision: the tag is created only after the build succeeds, so a failed run leaves no tag. Ordinary pushes to `main` use their own concurrency group so they cannot displace a waiting release.

Revision 6 (2026-11-19 to 11-20): `ci.yml` runs a SonarQube Cloud scan (coverage from `flutter test --coverage`) and its quality gate blocks merges (D-C25). The release notification carries a static moon banner on every channel plus the GitHub release preview (Teams embeds a shrunk copy, Discord and Telegram link it). Third-party actions are pinned to commit SHAs and Dependabot moves them monthly (D-C26).

Revision 2 (superseded): a tag `dev-*` or `prod-*` built that flavor.

## Scope

In:

- `ci.yml`: checks on pull requests and pushes to `main`, plus a smoke check of the fastlane setup.
- `distribute.yml`: build and upload, on tags `dev-*` and `prod-*` and by manual run.
- fastlane at the repository root: `Gemfile`, `Gemfile.lock`, `fastlane/{Fastfile,Appfile,Pluginfile,distribution.yml}` and helpers in `fastlane/lib/`. The Fastfile holds only lanes.
- Android lanes `build_dev`, `build_prod`, `distribute_dev`, `distribute_prod`; iOS lanes with the same names.
- A release signing configuration for the Android `prod` flavor.
- `docs/ci-cd.md`: secrets, first run, how to release, how to roll back.

Out: Google Play and TestFlight (prod goes to Firebase testers first), iOS signing that needs an Apple Developer account Fox does not have yet (the iOS lanes are written but unverified end to end), a `uat` flavor.

## Answers to Fox's questions (2026-11-17)

- **Helpers in the Fastfile.** They move to `fastlane/lib/`; the Fastfile keeps only lanes (D-C9).
- **`build_dev` vs `distribute_dev`.** `build_dev` runs `pub get`, build_runner and `flutter build apk` and stops; it needs no credentials. `distribute_dev` runs `build_dev` and then uploads the APK. The workflow calls only `distribute_*`; `build_*` is called by `distribute_*` and by hand (a local check, or a future build-only job). They stay separate so a build can be tried without Firebase credentials.
- **Hard-coded values.** Removed where a source of truth exists (D-C11). What remains is data in one named file, not code.

## Decisions

Decisions D-C1 to D-C8 are from revision 1; those revised are marked.

| ID    | Decision |
|-------|----------|
| D-C1  | Revised. Android and iOS, `dev` and `prod`. The tag is `<flavor>-<name>+<build>` and builds every enabled platform for that flavor; the tag is the single source for the version testers see. |
| D-C2  | Pull requests and `main` pushes only check; they never publish. |
| D-C3  | Dev release APKs are signed with Fox's debug key, restored from a secret in the `dev` environment, so builds install over each other and over local debug builds. The debug key is public (password `android`): consistency, not secrecy. |
| D-C4  | No app secret is needed in the build: `assets/env/.env.*` hold none, so CI copies the committed `.example` files. `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) are gitignored, so they come from secrets. |
| D-C5  | Generated code is gitignored, so every job runs build_runner and gen-l10n first. |
| D-C6  | Revised. Ruby is pinned by `.ruby-version`, Java by `.java-version`, Flutter by `environment.flutter` in `pubspec.yaml` (exact version, as `subosito/flutter-action` requires); no version number is written in a workflow. fastlane and its plugin are locked by a committed `Gemfile.lock` (Bundler works through rbenv Ruby 3.3.12 on Fox's Mac). Actions use major tags. |
| D-C7  | Secrets reach scripts through `env:`, never inside a shell command; files written from them are removed in a last step that always runs. |
| D-C8  | Revised. Tester groups live in `fastlane/distribution.yml`, one entry per flavor; the environment variable `FIREBASE_TESTER_GROUPS` overrides it. |
| D-C9  | One fastlane at the repository root instead of one under `android/` and one under `ios/`. Both platforms call `flutter build`, so nothing needs the platform folder as working directory, and one `Gemfile`, one lock file and one set of helpers serve both. Helpers are plain Ruby modules in `fastlane/lib/` (`require`d by absolute path from the Fastfile); the Fastfile contains no `def`. Shared steps are `private_lane`s. |
| D-C10 | Lane contract: `build_<flavor>` compiles and leaves the artifact in `build/`; `distribute_<flavor>` calls it and uploads. Parameters: `build_name`, `build_number`, `notes`. |
| D-C11 | Single sources of truth, read at run time: Flutter version, `pubspec.yaml`; Ruby, `.ruby-version`; Java, `.java-version`; Firebase project and app ids, `firebase.json` (written by `flutterfire configure`, key `flutter.platforms.dart`); iOS bundle id, `ios/Flutter/<flavor>-Release.xcconfig`; entry file, `lib/main_<flavor>.dart`; Flutter command, `fvm flutter` when `fvm` is installed and `flutter` otherwise (no `FLUTTER_CMD` variable). |
| D-C12 | GitHub Environments `dev` and `prod` hold secrets with the same names, so the workflow never builds a secret name from the flavor. `prod` can require a reviewer before the job starts. |
| D-C13 | Android `prod` release builds are signed with a release keystore read from `android/key.properties` (local) or `ANDROID_KEYSTORE_*` environment variables (CI). A `prod` release build without a keystore fails; it is never signed with the debug key. `dev` keeps D-C3. |
| D-C14 | iOS: `flutter build ios --release --no-codesign --flavor <f>` prepares the project, then fastlane `build_app` archives scheme `<f>` with configuration `Release-<f>`. Signing is automatic through an App Store Connect API key (`-allowProvisioningUpdates`); the export method is `ad-hoc` (Firebase needs the testers' device UDIDs registered). The team id comes from `APPLE_TEAM_ID` when set, otherwise from the Xcode project. No `match` repository (one developer). |
| D-C15 | `distribute_prod` uploads to the prod Firebase project's testers; Google Play and TestFlight come later and need no change to the lanes already here. |
| D-C16 | The iOS job runs only when the repository variable `IOS_ENABLED` is `true`, so a tag does not fail while there is no Apple Developer account. |

## Acceptance criteria

Revision 1 (unchanged): CD-1 `ci.yml` is green on a clean checkout. CD-2 a tag `dev-1.0.0+60` gives an APK with versionName `1.0.0-dev` and versionCode 60. CD-3 a tag that does not match `<flavor>-<x.y.z>+<n>` fails before any build. CD-4 the APK appears in App Distribution and `testers` is notified. CD-5 a second tag installs over the first. CD-6 no secret value appears in the repository or logs.

Revision 2:

- CD-7: `fastlane/Fastfile` contains lanes only (no `def`); `bundle exec fastlane lanes` lists `build_dev`, `build_prod`, `distribute_dev`, `distribute_prod` under both `android` and `ios`.
- CD-8: no literal Flutter, Ruby or Java version, Firebase app id or tester group appears in `.github/` or `fastlane/Fastfile`; the helpers return the Firebase ids found in `firebase.json` for every flavor and platform.
- CD-9: `build_prod` on Android gives an APK with `applicationId` `com.fox.evermoon` and versionName without `-dev`, signed with the release key (`apksigner verify --print-certs` shows the keystore's certificate, not the debug one); the same build without a keystore fails with a message naming the missing file.
- CD-10: a tag `prod-*` waits for the `prod` environment's approval when Fox enables it, and uses the `prod` secrets and the prod Firebase app.
- CD-11: with `IOS_ENABLED` not `true`, the iOS job is skipped and the tag run is green.
- CD-12: `flutter build ios --release --no-codesign --flavor dev` succeeds on Fox's Mac. Archive, signing and upload are not covered until an Apple Developer account exists.

## Slices

1. Refactor and Android prod: move to the root layout, helpers into `fastlane/lib/`, `distribution.yml`, Gradle release signing, lanes for dev and prod. Tests: Ruby unit tests of the helpers (`fastlane/test/`), `bundle exec fastlane lanes`, a local `build_prod` with a throw-away keystore, and the negative build without a keystore.
2. Workflows: `distribute.yml` with a `prepare` job, an Android job and a guarded iOS job through a composite action `.github/actions/setup`; `ci.yml` reads versions from the version files and runs the fastlane smoke check. Tests: YAML parse, `actionlint` when available, the hard-code grep of CD-8.
3. iOS lanes: Ruby side as D-C14; local compile of CD-12.
4. Documentation: `docs/ci-cd.md` rewritten for environments, secrets, tags and local runs; `docs/platform-notes.md` and `doc/manual/FASTLANE_SETUP.md` point to it.

## Risks and checks

| Risk | Assumption and check |
|------|----------------------|
| `flutter-version-file` rejects the pubspec line | Its README requires an exact version; the first CI run confirms. `pub get` also enforces the pin locally. |
| `private_lane` or `require` behaves differently inside fastlane's Fastfile loader | `bundle exec fastlane lanes` loads the real Fastfile (CD-7). |
| The Gradle guard misses `prodRelease` through Flutter's build | The negative build of CD-9 proves it. |
| Crashlytics mapping upload fails on the runner | First CI run; the local run shows it works without a login. |
| iOS lanes cannot be proven without an Apple Developer account | Marked unverified in `docs/ci-cd.md`; CD-12 covers only the compile step. |
| A tag is pushed from a branch other than `main` | Documented: tag `main` only. |
| The Xcode project's team id (`9W96R5ZZY4`) differs from the id in the older guide (`GH2PAB3V62`) | `APPLE_TEAM_ID` is never written in code; Fox confirms which one is his when he has the account. |

## Verification

Revision 1, run 2026-11-13: Fastfile syntax OK; both workflows parse; the `build_dev` commands built `app-dev-release.apk` (70.9 MB, `com.fox.evermoon.dev`, versionCode 60, versionName `1.0.0-dev`); `dart test` in `packages/lunar_calendar` passes (18). fastlane itself, the upload and the workflows had not run.

Revision 2, run 2026-11-17 on Fox's Mac (rbenv Ruby 3.3.12, Bundler 4.0.20, fastlane 2.242.0, Flutter 3.47.1 through fvm). Candidate: uncommitted working tree on `main` at `66b6d1c`.

| Criterion | Result | Evidence |
|-----------|--------|----------|
| CD-7 | Pass | `bundle exec fastlane lanes` loaded the real Fastfile and listed `build_dev`, `build_prod`, `distribute_dev`, `distribute_prod` under `android` and `ios`. The Fastfile has no `def`. A first run failed on `Fastlane::FastlaneFolder` (the class is `FastlaneCore::FastlaneFolder`); fixed. |
| CD-8 | Pass | The grep of `ci.yml` (versions, app ids, tester groups in `.github/` and the Fastfile) finds nothing; 16 helper tests pass, including all four Firebase app ids and both iOS bundle ids against values taken from the Firebase console and the Xcode project. The grep step first matched its own pattern text; fixed with `[:]`. |
| CD-9 | Pass | `build_prod` without a keystore failed in Gradle with the message naming `android/key.properties` and the `ANDROID_KEYSTORE_*` variables. With a throw-away keystore (`ANDROID_KEYSTORE_*`, deleted afterwards) it built `app-prod-release.apk`: `com.fox.evermoon`, versionCode 61, versionName `1.0.0`, signer SHA-256 `596B88…5A77` (the test keystore), not the debug certificate `F0142A…7EF0`. |
| CD-2 / D-C3 (regression) | Pass | `build_dev` built `com.fox.evermoon.dev`, versionCode 62, versionName `1.0.0-dev`, signed with the debug certificate `F0142A…7EF0`. |
| CD-12 | Pass for the Flutter step | `flutter build ios --release --no-codesign --flavor dev` built `Evermoon (Dev).app` (33.7 MB). Archive, signing and upload were not run. |
| CD-1, CD-3, CD-4, CD-5, CD-6, CD-10, CD-11 | Not run | They need GitHub (secrets, environments, a tag). The workflow files parse as YAML and the composite action is referenced by path; `actionlint` is not installed. |

Other checks: `ci.yml`, `distribute.yml`, `setup/action.yml` and `distribution.yml` parse (Ruby `YAML.safe_load`); `Gemfile.lock` covers `ruby`, `x86_64-linux-gnu` and `arm64-darwin`. The disk of the Mac was full (497 MB free) during the first prod build; with Fox's approval about 19 GB were freed (Android emulator system images, Xcode DerivedData, the project's `build/`). Not covered: the `private_lane` upload path (`firebase_app_distribution` call), `bundler-cache` and `flutter-version-file` on a runner, the `prod` environment approval.

## Revision 3 (2026-11-17)

Fox's decisions: one branch (`main`); GitHub builds only prod; `dev` stays local; no tag prefix; tag equals the pubspec version; Flutter version not written in `pubspec.yaml`; notifications to Teams, Telegram and Discord (no Slack); changelog on GitHub; format gate after a one-time format.

| ID    | Decision |
|-------|----------|
| D-C17 | Supersedes D-C1, D-C3, D-C12. The tag is `x.y.z+n` and must equal `version:` in `pubspec.yaml` and point to a commit on `main`; `prepare` fails otherwise. Only the `prod` flavor runs on GitHub, with secrets in the Environment `prod`. The `dev` lanes remain for local use. |
| D-C18 | Reverses the first attempt of revision 3 (read Flutter from `.fvmrc`). `.fvmrc` is `stable`, a channel, so GitHub could build with a newer Flutter than Fox's machine (3.47.1 locally, 3.48.0 later); Fox rejected rewriting `.fvmrc` and accepted a pin in `pubspec.yaml` instead. Flutter is `environment.flutter: 3.47.1` in `pubspec.yaml`; `.github/actions/setup` passes the file to `subosito/flutter-action` (`flutter-version-file`), `pub get` enforces it locally, and `release_firebase.sh` shows it and refuses to release without it. `.fvmrc` is unchanged (`stable`). |
| D-C19 | `scripts/distribution/release/release_firebase.sh` is the only way to release: checks branch `main`, clean tree, up to date with origin; shows the version, Flutter in use and the changes since the last tag; suggests a bump from Conventional Commits; asks `Bump to X (yes/no)` (no: manual entry, must be higher than the last release); raises the build number when the version changes; commits `chore(release): X+N`, tags, pushes. `--dry-run` changes nothing. |
| D-C20 | `scripts/distribution/release/release_notes.sh` builds the changelog (breaking, features, fixes, other) from commits since the previous tag, skipping `chore(release):`. The text is the Firebase note, the GitHub Release body and the notification body. |
| D-C21 | `scripts/distribution/notify/notify.sh` sends the result to every configured channel (`TEAMS_WEBHOOK_URL`, `TELEGRAM_BOT_TOKEN` and `TELEGRAM_CHAT_ID`, `DISCORD_WEBHOOK_URL`), truncates to each limit, and never fails the release (a failed send is a warning). The webhooks are repository secrets so the notify job does not wait for the prod approval. |
| D-C22 | The GitHub Release carries the changelog and no APK (a public repository would expose the prod build). Artifacts are not uploaded by the workflow, so retention is only the 90-day default of logs. |
| D-C23 | `ci.yml` runs on pull requests into `main` only. Shared checks live in the composite action `.github/actions/verify` (pub get, `dart format --set-exit-if-changed` on tracked Dart files, build_runner, gen-l10n, analyze, tests, `lunar_calendar` tests) and also gate the release. 19 files were formatted once so the gate starts green. `dart fix` and `dart migrate` are not used: the first rewrites code, the second no longer exists. |
| D-C24 | `.env.*` come from the committed `.example` files; they are bundled into the app and so are not secrets. |
| D-C25 | Revision 6. SonarQube Cloud analysis in `ci.yml` (organization and project key are repository variables, the token is a secret; Automatic Analysis is off). `sonar.qualitygate.wait=true` makes the gate fail the check, so it blocks the merge. New code is a number of days on the project; a pull request is judged on its own diff. |
| D-C26 | Revision 6. Supersedes "Actions use major tags" in D-C6. Every third-party action is pinned to a full commit SHA with its version in a trailing comment (SonarQube rated unpinned actions as a security issue); `.github/dependabot.yml` opens one grouped pull request a month (`chore(ci): ...`), including the local setup action. It started weekly; after its first pull request moved several actions to a new major, Fox changed it on 2026-11-20 to monthly and to ignore new majors (those are moved by hand). The majors that pull request already brought (checkout v7, setup-java v6, upload-pages-artifact v5, deploy-pages v5, Sonar scan v8.5.0) were kept, not rolled back; the next release run is their check. |

Criteria: CD-13 `prepare` accepts only a tag equal to the pubspec version on `main`. CD-14 `release_firebase.sh` behaves as D-C19 in every case listed below. CD-15 `release_notes.sh` groups commits and suggests the right bump. CD-16 `notify.sh` sends valid JSON, truncates, and exits 0 on failure. CD-17 the format gate, analyze and tests pass locally. CD-18 (needs GitHub) the first tag run completes and creates the Release.

Verification, 2026-11-17 on Fox's Mac and a scratch repository with a fake origin (bash 3.2, system PATH):

| Criterion | Result | Evidence |
|-----------|--------|----------|
| CD-13 | Pass | The `prepare` step text, extracted from `distribute.yml` and run in the scratch repository: valid tag gives `android=true`, `ios=false` (or `true` with `IOS_ENABLED`); tag different from pubspec, `v1.0`, a branch ref and a commit not on `main` each stop with an error. |
| CD-14 | Pass | Dirty tree (real and dry run); first release as it is; nothing to release; feat gives minor with an invalid answer re-asked; fix and docs give patch with a bad manual version rejected; breaking gives major; cancel; dry run; wrong branch; behind origin. A missing `.fvmrc` and a SIGPIPE risk in the branch check were found and fixed. |
| CD-15 | Pass | Grouping, `--bump`, `--max-chars`; release commits skipped after a first run showed them as noise. |
| CD-16 | Pass | Dry-run payloads parse as JSON with quotes, backslashes and Vietnamese text; truncation marker; a closed port gives a warning and exit 0. The Teams card format and real delivery are not tested. |
| CD-17 | Pass | `dart format` on all tracked Dart files clean; `flutter analyze` clean; 204 app tests pass; the helper tests pass (16). |
| CD-18 | Not run | Needs GitHub. All `.github/**/*.yml` parse; `actionlint` is not installed. |

Not verified: any workflow run on GitHub, Teams, Telegram and Discord delivery, iOS archive, signing and upload, Firebase's release retention. `flutter-version-file: pubspec.yaml` has not run on a runner (its README requires an exact version, which is what the pin is).

## Update 2026-11-20: what ran on GitHub

CD-18 passes: the prod secrets and webhooks were set up, and releases 1.0.0+1 to 1.2.0+7 are tagged on `origin` (tags listed with `git ls-remote --tags origin`). 1.2.0+7 was the first release through revision 5: Fox ran only `scripts/distribution/release/release_firebase.sh`, merged the pull request, and the workflow built, tagged, published the Release and notified; he confirmed the previews on 2026-11-19. The rulesets of revision 4 and the SonarQube gate (D-C25) are active; the first gate failure (unpinned action) was fixed by D-C26. Dependabot's first pull request (grouped, 5 updates) was merged on 2026-11-20 and moved `checkout` to v7, `setup-java` to v6, `upload-pages-artifact` and `deploy-pages` to v5 and the Sonar scan action to v8.5.0.

Not recorded as checked: CD-1 to CD-6, CD-10 and CD-11 one by one (the successful releases imply most of them, but no evidence was written down); a release run after the action bump; the failure path ("Re-run failed jobs" leaves no tag); Firebase's release retention; iOS archive, signing and upload.

## Update 2026-11-25: scripts regrouped, Google Play added

| ID | Decision |
|----|----------|
| D-C27 | The scripts are grouped by purpose under `scripts/`: `lib/common.sh` (shared helpers, sourced), `setup/`, `utils/` (`git_helper.sh` with a `clean` command) and `distribution/` (the release, build, upload and notification scripts, split further later). Behavior of the release scripts and the workflow is unchanged; only the paths moved and the shared helpers were extracted. |
| D-C28 | Distribution is prod only and has two flows, behind one entry point `scripts/distribution/release/release.sh [firebase\|play]`. **firebase** is `release_firebase.sh` (renamed from `release_prepare.sh`): it opens the release pull request, and the merge makes GitHub build prod, upload to Firebase App Distribution, tag and notify. There is no local Firebase upload script (a first draft, `firebase.sh`, was removed because the release pull request already does this). **play** is `release_play.sh`: it builds the prod bundle and uploads it to a Google Play track chosen by the user (internal, alpha, beta, production) from this machine. Google Play is local only and manual: nothing publishes to it automatically. The Play work is the lane `publish_play` and `Evermoon::Play`, which uploads only the bundle (no listing, images or release notes). Credentials are a Google Play service account JSON in `PLAY_SERVICE_CREDENTIALS`, kept outside the repository. Local builds for testing (dev or prod, apk or aab) are `scripts/utils/build.sh`. The dev lanes and the dev entry of `fastlane/distribution.yml` are kept for reference. Scripts are grouped in `scripts/{lib,setup,utils,distribution}`. Decided by Fox on 2026-11-25. |

Checks run 2026-11-25 (Fox's Mac, scratch repositories with a fake origin and a fake `bundle`): 113 shell checks over the distribution scripts in their final layout (release_notes, release_firebase and release_tag dry runs and a real tag, release.sh, release_play.sh, build.sh, notify dry run), 57 over `git_helper.sh` and the setup scripts, 28 Ruby tests (9 new for `Evermoon::Play`), `fastlane lanes` lists `publish_play`, all workflow YAML parses and every script path in the workflows exists. Not checked: the workflow after the move (the next release is its test) and a real upload to Google Play (needs the Play Console setup in `docs/ci-cd.md`).

## Blockers and next action

- Fox: set up the Google Play side (service account, API access, the first bundle uploaded by hand) with Claude, then try `bash scripts/distribution/release/release_play.sh internal --validate`.
- Fox: install `gh` (`brew install gh`, `gh auth login`) so `release_firebase.sh` opens the pull request and turns on auto-merge by itself; without it he presses Enable auto-merge once on GitHub.
- The next release is the check of the action bump (checkout v7, setup-java v6); read its run before trusting it.
- iOS waits for an Apple Developer account (`IOS_ENABLED` stays unset).
