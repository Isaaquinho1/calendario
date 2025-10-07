import 'dart:async';
import 'package:calendario/firebase_options.dart';
import 'package:calendario/pages/auth_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
// WIDGET DE PANTALLA DE CARGA (SPLASH SCREEN)
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
    await Future.delayed(const Duration(seconds: 6));

    // Muestra el mensaje de bienvenida y luego navega a AuthPage
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '¡Bienvenidos a Remind!',
            textAlign: TextAlign.center,
          ),
          duration: Duration(seconds: 4), // Duración del mensaje
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
            // Reemplaza esto con el widget de tu logo real (ej. Image.asset('assets/logo.png'))
      Image.asset ('assets/remind.png',
                height: 200,
              ),
            const SizedBox(height: 20),
            const Text(
              'Sean bienvenidos a ¡Remind!',
              style: TextStyle(
                color: Colors.black,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 50),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
            ),
          ],
        ),
      ),
    );
  }
}