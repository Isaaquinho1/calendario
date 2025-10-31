import 'package:calendario/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
// 🔑 Importaciones para la lógica de tareas y Hive
import 'package:hive_flutter/hive_flutter.dart'; 
import 'package:intl/date_symbol_data_local.dart';
import 'models/task.dart'; 
// 🔑 Importaciones de Localización
import 'package:flutter_localizations/flutter_localizations.dart'; 

import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Inicialización de Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // 2. Inicialización de Hive y Formato de Fecha
  await initializeDateFormatting('es', null);
  
  // ❌ ELIMINADA: await NotificationService.init(); (Causa conflicto de Gradle)
  
  // Inicialización de Hive
  await Hive.initFlutter();
  Hive.registerAdapter(TaskAdapter()); // Asegúrate de que TaskAdapter exista
  
  // Apertura de cajas necesarias
  await Hive.openBox<Task>('tasks'); // Box de Tareas
  await Hive.openBox('userBox'); // Box de Perfil

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      
      // 🔑 CONFIGURACIÓN DE LOCALIZACIÓN (ESPAÑOL)
      locale: Locale('es', 'ES'), 
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        Locale('es', 'ES'), // Español
        Locale('en', 'US'), // Inglés (como respaldo)
      ],
      
      // La aplicación inicia con la nueva pantalla de carga
      home: SplashScreen(), // Asumo que tienes una AuthWrapper o SplashScreen que llama a AuthPage
    );
  }
}

// ⚠️ NOTA: Este código asume que tu Splash Screen ahora es AuthWrapper,
// o que el SplashScreen debe ser colocado aquí. 
// Usaré el nombre 'AuthWrapper' por convención, pero si tu clase se llama SplashScreen,
// deberás ajustar la línea 'home: AuthWrapper()' a 'home: SplashScreen()'.