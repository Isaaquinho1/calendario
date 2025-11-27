// Archivo: android/app/build.gradle.kts

// =======================================================================
// FIX PARA AMBIGÜEDAD (Parte 1): La importación debe ir AL INICIO
// =======================================================================
import org.gradle.api.tasks.compile.JavaCompile

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
    // Mantener en 36 para compatibilidad con todas las librerías modernas
    compileSdk = 36 
    
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
        }
    }
}

flutter {
    source = "../.."
}

// 🔑 2. AÑADIR SECCIÓN DE DEPENDENCIAS Y LA LIBRERÍA DE DESUGARING
dependencies {
    // 🔑 AÑADIR LA DEPENDENCIA DE CORE DESUGARING
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    
     implementation("com.google.firebase:firebase-auth")

}

// =======================================================================
// FIX PARA AMBIGÜEDAD (Parte 2): Forzar al compilador a ignorar el error
// =======================================================================
tasks.withType<JavaCompile>().configureEach {
    options.compilerArgs.add("-Xlint:none")
}