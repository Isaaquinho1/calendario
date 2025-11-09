plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.calendario"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Soporte de Java 8 + desugaring
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_1_8.toString()
    }

    defaultConfig {
        applicationId = "com.example.calendario"
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // 🔑 Core desugaring (para compatibilidad con nuevas APIs Java)
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")

    // Ejemplo: dependencias de Firebase
    implementation(platform("com.google.firebase:firebase-bom:33.4.0"))
    implementation("com.google.firebase:firebase-auth")
}

// ✅ Agregamos repositorios explícitos para que el módulo 'app' los tenga disponibles
repositories {
    google()
    mavenCentral()
    gradlePluginPortal()
    maven { url = uri("https://storage.googleapis.com/download.flutter.io") }
}
