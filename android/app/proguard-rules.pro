# Reglas existentes para androidx.window
-keep class androidx.window.** { *; }
-dontwarn androidx.window.**
-keep class androidx.window.sidecar.** { *; }
-keep class androidx.window.extensions.** { *; }
-dontwarn androidx.window.sidecar.**
-dontwarn androidx.window.extensions.**

# Reglas para GOOGLE PLAY CORE
-keep class com.google.android.play.core.** { *; }
-keep class com.google.android.play.** { *; }
-dontwarn com.google.android.play.core.**
-dontwarn com.google.android.play.**

# Reglas para Flutter deferred components
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }
-dontwarn io.flutter.embedding.engine.deferredcomponents.**

# Reglas generales de Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# --- REGLAS FALTANTES QUE NECESITAS AÑADIR ---

# Regla para Firebase (evita que se borre en release)
-keep class com.google.firebase.** { *; }

# Regla para flutter_local_notifications (LA MÁS IMPORTANTE PARA TU ERROR)
-keep class com.dexterous.flutterlocalnotifications.** { *; }