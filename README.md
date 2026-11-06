# Evermoon

Flutter app to register yearly events on Vietnamese lunar dates, mainly death anniversaries ("giỗ"), and get reminded on the right day. The lunar calendar view is a supporting feature. Personal use first; optional login for backup and sync, share cards and family groups come later.

- Product context: [docs/PRODUCT_BRIEF.md](docs/PRODUCT_BRIEF.md)
- Project rules, architecture and conventions: [CLAUDE.md](CLAUDE.md)
- Decisions: [docs/adr/](docs/adr/) · Plans: [docs/plans/](docs/plans/) · Platform differences: [docs/platform-notes.md](docs/platform-notes.md)

## Status

Early development. The Flutter project was cloned from the author's base template and is being trimmed (see [plan 0002](docs/plans/0002-template-cleanup.md)). The lunar engine is a separate pure-Dart package, `packages/lunar_calendar` ([plan 0001](docs/plans/0001-lunar-package.md)); its Python oracle and reference implementation are done, the Dart port is pending.

Android is the main target. iOS code is kept but not built for now.

## Setup

Use [fvm](https://fvm.app) for every command (`.fvmrc` is `stable`); never run bare `flutter` or `dart`.

```sh
git clone git@github.com:itachi1611/ever_moon.git
cd ever_moon
fvm install
fvm flutter pub get
bash scripts/setup_env.sh        # creates assets/env/.env.<flavor> from the .example files
fvm flutter gen-l10n
fvm flutter pub run build_runner build --delete-conflicting-outputs
```

`assets/env/.env.*` are bundled into the app: put only non-secret configuration there.

## Flavors

Two flavors, `dev` and `prod`, each with its own entry file:

```sh
fvm flutter run --flavor dev -t lib/main_dev.dart
fvm flutter run --flavor prod -t lib/main_prod.dart
fvm flutter build apk --flavor prod -t lib/main_prod.dart --release
```

| Flavor | Android / iOS id | Firebase project |
|--------|------------------|------------------|
| dev    | `com.fox.evermoon.dev` | `evermoon-dev` |
| prod   | `com.fox.evermoon`     | `evermoon-2cc28` |

## Firebase

Firebase configuration files are git-ignored and generated per machine:

```sh
npm install -g firebase-tools
firebase login
fvm dart pub global activate flutterfire_cli
bash scripts/config_firebase.sh          # both flavors; pass `dev` or `prod` for one
```

This writes `lib/firebase/<flavor>/firebase_options.dart`, `google-services.json` and `GoogleService-Info.plist`. Enable Authentication, Cloud Messaging and Crashlytics in each project. The app must work without login; login is optional.

## Checks

```sh
fvm dart format lib
fvm dart analyze          # must report no issues
fvm flutter test
```

Lunar engine tests (Python oracle): see [tools/lunar_oracle/README.md](tools/lunar_oracle/README.md).

## Claude Code

Shared project settings, MCP servers (`.mcp.json`), skills (`moon-builder`, `s-flutter-optimized`) and agents live in `.claude/`. The `agent-engineering` and `dart-flutter` plugins are declared in `.claude/settings.json`.

## License

See [LICENSE](LICENSE).
