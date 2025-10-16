import 'dart:async';
import 'package:calendario/firebase_options.dart';
import 'package:calendario/pages/auth_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// 🔑 Importaciones de HIVE, Modelos y Servicios
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

// -------------------------------------------------------------------
// WIDGET DE PANTALLA DE CARGA (SPLASH SCREEN) - Sin cambios funcionales
// -------------------------------------------------------------------

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  // Función para manejar el tiempo de espera y la navegación
  _navigateToHome() async {
    // Espera 3 segundos para mostrar el logo
    await Future.delayed(const Duration(seconds: 3)); // Reducido el tiempo de espera

    // Muestra el mensaje de bienvenida y luego navega a AuthPage
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '¡Bienvenidos a Remind!',
            textAlign: TextAlign.center,
          ),
          duration: Duration(seconds: 2), // Duración del mensaje
        ),
      );

      // Espera 2.5 segundos para que el usuario pueda leer el mensaje
      await Future.delayed(const Duration(milliseconds: 2500)); 

      // Navega a la página de autenticación (AuthPage)
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const AuthPage(),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Color de fondo de tu elección
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset ('assets/remind.png',
                height: 200,
              ),
            const SizedBox(height: 20),
            const Text(
              '¡Organiza, Recuerda y Sonríe!',
              style: TextStyle(
                color: Colors.black,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
               const SizedBox(height: 30),
                  Image.asset(
                  'assets/remi.png',
                  height: 150,
                ),
                const SizedBox(height: 30),

            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
            ),
          ],
        ),
      ),
    );
  }
}