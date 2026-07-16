import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// ✅ SỬ DỤNG TOOLCHAIN 17 - CÁCH HIỆN ĐẠI NHẤT
kotlin {
    jvmToolchain(17)
}

val envFile = project.rootProject.file("../.env")
val envProperties = Properties()
if (envFile.exists()) {
    envFile.inputStream().use { envProperties.load(it) }
}
val googleMapsApiKey = envProperties.getProperty("GOOGLE_MAPS_API_KEY") ?: ""

android {
    namespace = "com.traveladvisor.travel_advisor_mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    signingConfigs {
        getByName("debug") {
            storeFile = file("debug.keystore")
            storePassword = "android"
            keyAlias = "androiddebugkey"
            keyPassword = "android"
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "com.traveladvisor.travel_advisor_mobile"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["GOOGLE_MAPS_API_KEY"] = googleMapsApiKey
        multiDexEnabled = true
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            // Tắt R8/shrink: Mapbox + androidx.window tham chiếu vài class tùy chọn
            // không có trên classpath -> R8 fail. Bản test không cần minify.
            isMinifyEnabled = false
            isShrinkResources = false
        }
        getByName("debug") {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("androidx.appcompat:appcompat:1.6.1")
    implementation("com.google.android.material:material:1.9.0")
}

flutter {
    source = "../.."
}

// WORKAROUND: root android/build.gradle.kts redirects buildDir to
// ../../build/<module> for every subproject. The Flutter Gradle plugin
// resolves FlutterTask.intermediateDir (where app.so, the Dart AOT
// snapshot, is written) eagerly against the ORIGINAL buildDir, but its
// copyJniLibs<Variant> Sync task resolves its destination lazily against
// the REDIRECTED buildDir. That split means app.so lands in
// android/app/build/intermediates/flutter/<variant>/<abi>/ while AGP's
// packaging pipeline looks under build/app/intermediates/... — so
// libapp.so never reaches the APK and the release build crashes on
// launch with "VM snapshot invalid and could not be inferred from
// settings". This task bridges the two locations.
listOf("release", "profile").forEach { variantName ->
    val capitalized = variantName.replaceFirstChar { it.uppercase() }
    val fixTask =
        tasks.register<Copy>("fixFlutterLibapp$capitalized") {
            dependsOn("compileFlutterBuild$capitalized")
            listOf("arm64-v8a", "armeabi-v7a", "x86_64").forEach { abi ->
                from(project.projectDir.resolve("build/intermediates/flutter/$variantName/$abi")) {
                    include("app.so")
                    rename { "libapp.so" }
                    into(abi)
                }
            }
            into(layout.buildDirectory.dir("intermediates/flutter/$variantName/jniLibs"))
        }
    tasks.matching { it.name == "merge${capitalized}JniLibFolders" }.configureEach {
        dependsOn(fixTask)
    }
}
