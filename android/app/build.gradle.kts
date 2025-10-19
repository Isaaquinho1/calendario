plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.calendario"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    // 🔑 1. HABILITAR SOPORTE DE COMPILACIÓN DE JAVA 8 Y CORE DESUGARING
    compileOptions {
        // Asegura la compatibilidad con Java 8
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
        
        // HABILITAR CORE DESUGARING (Requerido por flutter_local_notifications)
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_1_8.toString() // Cambiar a 1_8 para consistencia
    }

    defaultConfig {
        applicationId = "com.example.calendario"
        minSdk = 24 //flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

// 🔑 2. AÑADIR SECCIÓN DE DEPENDENCIAS Y LA LIBRERÍA DE DESUGARING
dependencies {
    // 🔑 AÑADIR LA DEPENDENCIA DE CORE DESUGARING
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.5.5")
    
    // Si tienes otras dependencias, añádelas aquí (ej. implementación de Firebase Auth)
    // implementation("com.google.firebase:firebase-auth")
}