pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").reader(Charsets.UTF_8).use { properties.load(it) }
            val configuredPath = properties.getProperty("flutter.sdk")
            require(configuredPath != null) { "flutter.sdk not set in local.properties" }
            try {
                val decoded =
                    String(configuredPath.toByteArray(Charsets.ISO_8859_1), Charsets.UTF_8)
                if (decoded.contains('\uFFFD')) configuredPath else decoded
            } catch (_: Exception) {
                configuredPath
            }
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
    id("com.android.application") version "8.11.1" apply false
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false



    id("com.google.gms.google-services") version "4.4.1" apply false
    id("com.google.firebase.crashlytics") version "3.0.2" apply false
}

include(":app")
