// lib/screens/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:calendario/pages/auth_page.dart';
import 'package:flutter_svg/flutter_svg.dart'; // 🔑 Añadida importación para SVG

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
    await Future.delayed(const Duration(seconds: 3));

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
            
            // 🔑 NUEVO: Remi 2.svg
            SvgPicture.asset( // Usamos SvgPicture para archivos SVG
              'remi2.svg', 
              height: 200, // Ajusta la altura según necesites
            ),

            const SizedBox(height: 30), // Espacio después del SVG

            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
            ),
          ],
        ),
      ),
    );
  }
}