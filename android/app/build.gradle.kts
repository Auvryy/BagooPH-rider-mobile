import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val riderApplicationId = providers.gradleProperty("riderApplicationId").orNull
    ?: providers.environmentVariable("RIDER_APPLICATION_ID").orNull
val validRiderApplicationId = riderApplicationId
    ?.takeIf { id ->
        id.matches(Regex("^[A-Za-z][A-Za-z0-9_]*(\\.[A-Za-z][A-Za-z0-9_]*)+$")) &&
            !id.startsWith("com.example.") && id != "com.example"
    }

val riderDebugCleartext = providers.environmentVariable("RIDER_DEBUG_CLEARTEXT").orNull ?: "true"
require(riderDebugCleartext in setOf("true", "false")) {
    "RIDER_DEBUG_CLEARTEXT must be true or false."
}

val riderReleaseKeyPropertiesFile = rootProject.file("key.properties")
val riderReleaseKeyProperties = Properties()
if (riderReleaseKeyPropertiesFile.isFile) {
    riderReleaseKeyPropertiesFile.inputStream().use(riderReleaseKeyProperties::load)
}

val riderReleaseStoreFileValue = riderReleaseKeyProperties.getProperty("storeFile")?.trim()
val riderReleaseStoreFile = riderReleaseStoreFileValue
    ?.takeIf(String::isNotEmpty)
    ?.let(rootProject::file)
val riderReleaseStorePassword = riderReleaseKeyProperties.getProperty("storePassword")
val riderReleaseKeyAlias = riderReleaseKeyProperties.getProperty("keyAlias")
val riderReleaseKeyPassword = riderReleaseKeyProperties.getProperty("keyPassword")
val riderReleaseSigningConfigured =
    riderReleaseStoreFile?.isFile == true &&
        !riderReleaseStorePassword.isNullOrBlank() &&
        !riderReleaseKeyAlias.isNullOrBlank() &&
        !riderReleaseKeyPassword.isNullOrBlank()

android {
    namespace = "com.example.bagoo_rider_mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Keep the existing package ID for ordinary debug builds until a real ID is supplied.
        applicationId = validRiderApplicationId ?: "com.example.bagoo_rider_mobile"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (riderReleaseSigningConfigured) {
            create("riderRelease") {
                storeFile = checkNotNull(riderReleaseStoreFile)
                storePassword = checkNotNull(riderReleaseStorePassword)
                keyAlias = checkNotNull(riderReleaseKeyAlias)
                keyPassword = checkNotNull(riderReleaseKeyPassword)
            }
        }
    }

    buildTypes {
        debug {
            manifestPlaceholders["riderDebugCleartext"] = riderDebugCleartext
        }
        release {
            // Without local release credentials, AGP leaves this variant unsigned.
            if (riderReleaseSigningConfigured) {
                signingConfig = signingConfigs.getByName("riderRelease")
            }
        }
    }
}

val riderAppProject = project
gradle.taskGraph.whenReady {
    val releasePackagingRequested = allTasks.any { task ->
        task.project == riderAppProject && task.name in setOf(
            "assembleRelease",
            "bundleRelease",
            "packageRelease",
            "packageReleaseBundle",
            "packageReleaseUniversalApk",
            "signReleaseApk",
            "signReleaseBundle",
        )
    }
    if (releasePackagingRequested) {
        val missingSettings = buildList {
            if (validRiderApplicationId == null) add("a valid, approved RIDER_APPLICATION_ID")
            if (riderReleaseStoreFile == null || !riderReleaseStoreFile.isFile) {
                add("an existing keystore file configured by storeFile in android/key.properties")
            }
            if (riderReleaseStorePassword.isNullOrBlank()) add("storePassword in android/key.properties")
            if (riderReleaseKeyAlias.isNullOrBlank()) add("keyAlias in android/key.properties")
            if (riderReleaseKeyPassword.isNullOrBlank()) add("keyPassword in android/key.properties")
        }
        if (missingSettings.isNotEmpty()) {
            throw org.gradle.api.GradleException(
                "Rider release packaging is disabled until these local settings are supplied: " +
                    missingSettings.joinToString("; ") + ". No release artifact was built.",
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
