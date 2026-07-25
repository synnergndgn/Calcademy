import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
val hasReleaseSigning = keystorePropertiesFile.isFile

if (hasReleaseSigning) {
    keystorePropertiesFile.inputStream().use(keystoreProperties::load)
}

fun releaseSigningProperty(name: String): String =
    keystoreProperties.getProperty(name)?.takeIf(String::isNotBlank)
        ?: throw GradleException("Missing '$name' in android/key.properties")

android {
    namespace = "com.aligundogan.calcademy"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.aligundogan.calcademy"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                keyAlias = releaseSigningProperty("keyAlias")
                keyPassword = releaseSigningProperty("keyPassword")
                storeFile = rootProject.file(releaseSigningProperty("storeFile"))
                storePassword = releaseSigningProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            if (hasReleaseSigning) {
                signingConfig = signingConfigs.getByName("release")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

val releaseBuildRequested =
    gradle.startParameter.taskNames.any { taskName ->
        taskName.contains("release", ignoreCase = true)
    }

if (releaseBuildRequested && !hasReleaseSigning) {
    throw GradleException(
        "Release signing is not configured. Copy android/key.properties.example " +
            "to android/key.properties and provide a private upload keystore outside Git.",
    )
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

// AdMob Retry 1.0 — startup crash fix.
//
// `com.google.android.gms:play-services-ads-api` (via google_mobile_ads) pins
// `androidx.work:work-runtime:2.7.0` (2021), which in turn pins
// `androidx.room:room-runtime:2.2.5` (2020). WorkManager's own AndroidX Startup
// initializer builds a Room database at process start, before Dart `main()`
// runs, so any failure there is an unavoidable startup crash — exactly the
// 1.0.0+6 failure:
//
//   Unable to get provider androidx.startup.InitializationProvider
//     Caused by: com.google.android.gms.internal.ads...
//     Caused by: Failed to create an instance of androidx.work.impl.WorkDatabase
//
// Room 2.2.5 predates R8 full mode (mandatory from AGP 8) and its consumer keep
// rules do not survive it, so the generated `WorkDatabase_Impl` loses the
// no-arg constructor Room looks up reflectively. Forcing current WorkManager
// pulls a Room release whose keep rules are written for full mode.
dependencies {
    implementation("androidx.work:work-runtime:2.11.2")
}

flutter {
    source = "../.."
}
