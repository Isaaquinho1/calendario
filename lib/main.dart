import 'package:calendario/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

// ⬇️ 1. IMPORTA EL PAQUETE DE LOCALIZACIONES
import 'package:flutter_localizations/flutter_localizations.dart'; 

//import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'screens/splash_screen.dart';
import 'package:hive_flutter/hive_flutter.dart'; 
import 'package:intl/date_symbol_data_local.dart';
import 'models/task.dart'; 
import 'utils/notification_service.dart'; 

// 🔑 Declaración Global del Plugin de Notificaciones
//ate final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

void main() async {
WidgetsFlutterBinding.ensureInitialized();
 
 // 1. Inicialización de Firebase (ya existente)
  await Firebase.initializeApp(
     options: DefaultFirebaseOptions.currentPlatform,
 );
 
 // 2. Inicialización de Hive, Notificaciones y Formato de Fecha
 
  // ✅ Esto es para formatear fechas (Ej: "dd/MM/yyyy")
 await initializeDateFormatting('es', null); 
 
  await NotificationService.init(); // Inicializa Time Zones
 
 // 🔑 (Tu código de notificaciones comentado se queda igual)
/* ... */

 // Inicialización de Hive
 await Hive.initFlutter();
 Hive.registerAdapter(TaskAdapter()); // Asegúrate de que TaskAdapter exista
 //await Hive.openBox<Task>('tasks'); // Abre la caja que HomeScreen necesita
 await Hive.openBox('userBox');
 runApp(const MyApp());
}

class MyApp extends StatelessWidget {
 const MyApp({super.key});

 @override
 Widget build(BuildContext context) {
    // ⬅️ 2. APLICA LOS CAMBIOS DENTRO DE MATERIALAPP
    return const MaterialApp(
    debugShowCheckedModeBanner: false,
   
      // --- ⬇️ ESTO ES LO QUE TE DI (AGREGADO) ---
   
      // Establece español como idioma principal para los widgets
   locale: Locale('es', 'ES'), 
    
      // Configura los delegados de localización
   localizationsDelegates: [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
   ],
   
      // Define los idiomas soportados por tu app
   supportedLocales: [
    Locale('es', 'ES'), // Español
    Locale('en', 'US'), // Inglés (como respaldo)
   ],
      // --- ⬆️ FIN DE LO AGREGADO ---

   // La aplicación inicia con la nueva pantalla de carga
   home: SplashScreen(), 
  );
 }
}

