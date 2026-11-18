import java.util.Properties

// Release signing of the prod flavor. The values come from android/key.properties
// on a developer machine and from ANDROID_KEYSTORE_* variables on CI.
val keystoreProperties = Properties().apply {
    val propertiesFile = rootProject.file("key.properties")
    if (propertiesFile.exists()) propertiesFile.inputStream().use { load(it) }
}

fun releaseSetting(property: String, variable: String): String? =
    keystoreProperties.getProperty(property) ?: System.getenv(variable)

val releaseStorePath = releaseSetting("storeFile", "ANDROID_KEYSTORE_PATH")
val releaseKeyReady = releaseStorePath?.let { file(it).exists() } == true

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.fox.evermoon"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    // The release-time lint check (lintVitalAnalyze*) crashed on CI with a
    // NoSuchMethodError inside Android Lint itself, which failed the build. Lint is
    // not a release gate here; flutter analyze is.
    lint {
        checkReleaseBuilds = false
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.fox.evermoon"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            storeFile = releaseStorePath?.let { file(it) }
            storePassword = releaseSetting("storePassword", "ANDROID_KEYSTORE_PASSWORD")
            keyAlias = releaseSetting("keyAlias", "ANDROID_KEY_ALIAS")
            keyPassword = releaseSetting("keyPassword", "ANDROID_KEY_PASSWORD")
        }
    }

    flavorDimensions += "env"
    productFlavors {
        create("dev") {
            dimension = "env"
            applicationIdSuffix = ".dev"
            versionNameSuffix = "-dev"
            // Testers' builds install over local debug builds, so dev keeps
            // the debug key (docs/ci-cd.md).
            signingConfig = signingConfigs.getByName("debug")
        }
        create("prod") {
            dimension = "env"
            // No suffix — applicationId stays as defined in defaultConfig.
            // Without a keystore only debug builds fall back to the debug key;
            // the guard below stops a release build.
            signingConfig = signingConfigs.getByName(if (releaseKeyReady) "release" else "debug")
        }
    }
}

// A prod release must never go out signed with the debug key.
tasks.configureEach {
    if (name == "validateSigningProdRelease" && !releaseKeyReady) {
        doFirst {
            throw GradleException(
                "Prod release needs a keystore: set storeFile, storePassword, keyAlias and " +
                    "keyPassword in android/key.properties, or the ANDROID_KEYSTORE_PATH, " +
                    "ANDROID_KEYSTORE_PASSWORD, ANDROID_KEY_ALIAS and ANDROID_KEY_PASSWORD " +
                    "variables (docs/ci-cd.md).",
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
