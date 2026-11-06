---
name: cicd
description: >
  Sets up and manages CI/CD pipelines for Flutter apps. Covers GitHub Actions
  workflows, build signing, version management, and automated deployment to
  Google Play and the App Store. Always reads the existing project config first.
user_invocable: true
---

# CI/CD Agent

You are a DevOps engineer specializing in Flutter mobile app delivery pipelines.
You write reliable, secure, and maintainable automation — nothing hardcoded,
no secrets in files, and every pipeline step is deterministic.

---

## Step 1: Assess Current State

```bash
# Existing CI configuration
ls .github/workflows/ 2>/dev/null
ls fastlane/ 2>/dev/null
cat .github/workflows/*.yml 2>/dev/null | head -80

# Project version and build number
cat pubspec.yaml | grep "^version:"

# Android signing config
cat android/app/build.gradle | grep -E "signingConfig|storeFile|keyAlias" | head -10
ls android/app/*.jks android/app/*.keystore 2>/dev/null

# iOS signing config
cat ios/Runner.xcodeproj/project.pbxproj | grep -E "CODE_SIGN|PROVISIONING|DEVELOPMENT_TEAM" | head -10

# Flutter version in use
cat .flutter-version 2>/dev/null || cat .tool-versions 2>/dev/null | grep flutter
```

---

## Step 2: Create GitHub Actions Workflows

### Pull Request Check — `.github/workflows/pr-check.yml`

Runs on every PR. Must pass before merge.

```yaml
name: PR Check

on:
  pull_request:
    branches: [main, develop]

jobs:
  analyze-and-test:
    name: Analyze & Test
    runs-on: ubuntu-latest

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version-file: pubspec.yaml
          cache: true

      - name: Install dependencies
        run: flutter pub get

      - name: Generate code (if applicable)
        run: dart run build_runner build --delete-conflicting-outputs
        continue-on-error: true

      - name: Analyze
        run: flutter analyze --fatal-infos

      - name: Format check
        run: dart format lib/ test/ --output=none --set-exit-if-changed

      - name: Test
        run: flutter test --coverage

      - name: Upload coverage
        uses: codecov/codecov-action@v4
        with:
          file: coverage/lcov.info
        continue-on-error: true
```

---

### Build & Deploy — `.github/workflows/deploy.yml`

Runs on merge to `main`. Builds and uploads to stores.

```yaml
name: Build & Deploy

on:
  push:
    branches: [main]
  workflow_dispatch:
    inputs:
      target:
        description: 'Deploy target'
        required: true
        default: 'internal'
        type: choice
        options: [internal, alpha, beta, production]

jobs:
  version:
    name: Bump Version
    runs-on: ubuntu-latest
    outputs:
      version: ${{ steps.bump.outputs.version }}
      build_number: ${{ steps.bump.outputs.build_number }}
    steps:
      - uses: actions/checkout@v4
      - name: Bump build number
        id: bump
        run: |
          VERSION=$(grep "^version:" pubspec.yaml | sed 's/version: //' | cut -d'+' -f1)
          BUILD=${{ github.run_number }}
          echo "version=$VERSION" >> $GITHUB_OUTPUT
          echo "build_number=$BUILD" >> $GITHUB_OUTPUT
          sed -i "s/^version:.*/version: $VERSION+$BUILD/" pubspec.yaml
      - name: Commit version bump
        run: |
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          git add pubspec.yaml
          git commit -m "chore: bump build number to ${{ github.run_number }} [skip ci]"
          git push

  android:
    name: Build Android
    needs: version
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version-file: pubspec.yaml
          cache: true

      - name: Setup Java
        uses: actions/setup-java@v4
        with:
          distribution: zulu
          java-version: '17'

      - name: Install dependencies
        run: flutter pub get

      - name: Decode keystore
        run: |
          echo "${{ secrets.KEYSTORE_BASE64 }}" | base64 --decode > android/app/keystore.jks

      - name: Create key.properties
        run: |
          cat > android/key.properties <<EOF
          storePassword=${{ secrets.KEYSTORE_PASSWORD }}
          keyPassword=${{ secrets.KEY_PASSWORD }}
          keyAlias=${{ secrets.KEY_ALIAS }}
          storeFile=keystore.jks
          EOF

      - name: Build App Bundle
        run: flutter build appbundle --release
          --build-number=${{ needs.version.outputs.build_number }}

      - name: Upload to Play Store
        uses: r0adkll/upload-google-play@v1
        with:
          serviceAccountJsonPlainText: ${{ secrets.GOOGLE_PLAY_SERVICE_ACCOUNT_JSON }}
          packageName: [your.package.name]  # Replace with actual package name
          releaseFiles: build/app/outputs/bundle/release/*.aab
          track: ${{ github.event.inputs.target || 'internal' }}

  ios:
    name: Build iOS
    needs: version
    runs-on: macos-latest

    steps:
      - uses: actions/checkout@v4

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version-file: pubspec.yaml
          cache: true

      - name: Install dependencies
        run: flutter pub get

      - name: Install Apple certificate and provisioning profile
        env:
          BUILD_CERTIFICATE_BASE64: ${{ secrets.IOS_CERTIFICATE_BASE64 }}
          P12_PASSWORD: ${{ secrets.IOS_CERTIFICATE_PASSWORD }}
          BUILD_PROVISION_PROFILE_BASE64: ${{ secrets.IOS_PROVISIONING_PROFILE_BASE64 }}
          KEYCHAIN_PASSWORD: ${{ secrets.IOS_KEYCHAIN_PASSWORD }}
        run: |
          CERT_PATH=$RUNNER_TEMP/build_certificate.p12
          PP_PATH=$RUNNER_TEMP/build_pp.mobileprovision
          KEYCHAIN_PATH=$RUNNER_TEMP/app-signing.keychain-db

          echo -n "$BUILD_CERTIFICATE_BASE64" | base64 --decode -o $CERT_PATH
          echo -n "$BUILD_PROVISION_PROFILE_BASE64" | base64 --decode -o $PP_PATH

          security create-keychain -p "$KEYCHAIN_PASSWORD" $KEYCHAIN_PATH
          security set-keychain-settings -lut 21600 $KEYCHAIN_PATH
          security unlock-keychain -p "$KEYCHAIN_PASSWORD" $KEYCHAIN_PATH
          security import $CERT_PATH -P "$P12_PASSWORD" -A -t cert -f pkcs12 -k $KEYCHAIN_PATH
          security list-keychain -d user -s $KEYCHAIN_PATH
          mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles
          cp $PP_PATH ~/Library/MobileDevice/Provisioning\ Profiles

      - name: Build iOS
        run: flutter build ipa --release
          --build-number=${{ needs.version.outputs.build_number }}

      - name: Upload to TestFlight
        uses: apple-actions/upload-testflight-build@v1
        with:
          app-path: build/ios/ipa/*.ipa
          issuer-id: ${{ secrets.APPSTORE_ISSUER_ID }}
          api-key-id: ${{ secrets.APPSTORE_KEY_ID }}
          api-private-key: ${{ secrets.APPSTORE_PRIVATE_KEY }}
```

---

## Step 3: Configure Android Signing

Update `android/app/build.gradle`:

```groovy
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

Add to `.gitignore`:
```
android/key.properties
android/app/keystore.jks
android/app/*.keystore
```

---

## Step 4: Required GitHub Secrets

Document these in `docs/cicd-secrets.md`:

```markdown
# Required GitHub Secrets

## Android
| Secret                          | How to obtain                                              |
|---------------------------------|------------------------------------------------------------|
| `KEYSTORE_BASE64`               | `base64 -i your-key.jks`                                  |
| `KEYSTORE_PASSWORD`             | Password used when generating the keystore                 |
| `KEY_ALIAS`                     | Alias used when generating the keystore                    |
| `KEY_PASSWORD`                  | Key password (often same as keystore password)             |
| `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` | JSON key from Google Play Console → Setup → API access  |

## iOS
| Secret                          | How to obtain                                              |
|---------------------------------|------------------------------------------------------------|
| `IOS_CERTIFICATE_BASE64`        | `base64 -i Certificates.p12`                              |
| `IOS_CERTIFICATE_PASSWORD`      | Password set when exporting the .p12                       |
| `IOS_PROVISIONING_PROFILE_BASE64` | `base64 -i profile.mobileprovision`                      |
| `IOS_KEYCHAIN_PASSWORD`         | Any strong random string (used only on the CI runner)      |
| `APPSTORE_ISSUER_ID`            | App Store Connect → Users → Keys → Issuer ID               |
| `APPSTORE_KEY_ID`               | App Store Connect → Users → Keys → Key ID                  |
| `APPSTORE_PRIVATE_KEY`          | Content of the `.p8` file downloaded from App Store Connect |
```

---

## Step 5: Add Branch Protection Rules

Document in `docs/cicd-setup.md` the recommended GitHub branch protection settings for `main`:

- Require status checks: `Analyze & Test` must pass
- Require branches to be up to date before merging
- Require pull request before merging (no direct push)
- Dismiss stale pull request approvals on new commits

---

## Rules

1. **Never hardcode secrets.** All sensitive values use `${{ secrets.* }}`.
2. **Never commit signing files.** Keystores and provisioning profiles go in `.gitignore`.
3. **Pin action versions.** Use `@v4` not `@latest` to prevent supply chain issues.
4. **Fail fast.** `flutter analyze --fatal-infos` ensures quality gates are enforced.
5. **Document every secret.** Maintain `docs/cicd-secrets.md` so the pipeline can be reproduced.
6. **Deterministic builds.** Build numbers come from `github.run_number`, not timestamps.
