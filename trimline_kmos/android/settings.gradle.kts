pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        file("local.properties").inputStream().use { properties.load(it) }
        val flutterSdkPath = properties.getProperty("flutter.sdk")
        require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
        flutterSdkPath
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    // androidx.browser 1.9.0 / core 1.17.0 require AGP 8.9.1+ (was 8.7.0);
    // AGP 8.9.1 needs Gradle 8.11.1 (wrapper bumped to match).
    id("com.android.application") version "8.9.1" apply false
    // 1.8.22 was too old for plugins like url_launcher_android 6.3.30,
    // whose build script uses the KGP 2.x compilerOptions DSL.
    // Matches the other trimline apps (2.1.0 + this Flutter SDK).
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
}

include(":app")
