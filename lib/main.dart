import 'package:calendario/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'screens/splash_screen.dart';
import 'package:hive_flutter/hive_flutter.dart'; 
import 'package:intl/date_symbol_data_local.dart';
import 'models/task.dart'; 
import 'utils/notification_service.dart'; 

// 🔑 Declaración Global del Plugin de Notificaciones
late final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Inicialización de Firebase (ya existente)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // 2. Inicialización de Hive, Notificaciones y Formato de Fecha
  await initializeDateFormatting('es', null);
  await NotificationService.init(); // Inicializa Time Zones
  
  // 🔑 Inicialización del Plugin de Notificaciones
  flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('app_icon');
  const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings();
  const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS);

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Inicialización de Hive
  await Hive.initFlutter();
  Hive.registerAdapter(TaskAdapter()); // Asegúrate de que TaskAdapter exista
  await Hive.openBox<Task>('tasks'); // Abre la caja que HomeScreen necesita

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      // La aplicación inicia con la nueva pantalla de carga
      home: SplashScreen(), 
    );
  }
}

