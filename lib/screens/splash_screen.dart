// lib/screens/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:calendario/pages/auth_page.dart';
import 'package:flutter_svg/flutter_svg.dart'; 

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // 🔑 Color principal: #72C1F3
  static const Color primarySplashColor = Color(0xFF72C1F3);
  
  // Asumo que el nombre de tu archivo es 'remi2.svg'
  static const String remiAssetPath = 'cara_remind.svg'; 

  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  // Función para manejar el tiempo de espera y la navegación (sin cambios)
  _navigateToHome() async {
    // Espera 3 segundos (para el efecto visual de Duolingo)
    await Future.delayed(const Duration(seconds: 3));

    // Muestra el mensaje de bienvenida y luego navega a AuthPage
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '¡Bienvenido a Remind!',
            textAlign: TextAlign.center,
          ),
          duration: Duration(seconds: 2), 
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
      // 🔑 Fondo completo del color del SVG (#72C1F3)
      backgroundColor: primarySplashColor, 
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 🔑 Mascota SVG (Dimensiones grandes y centradas)
            SvgPicture.asset( 
              remiAssetPath, 
              height: 250, // Dimensionar para que destaque en el centro
              width: 250,
            ),
            
            const SizedBox(height: 20), // Espacio entre mascota y texto

            // 🔑 Nombre de la aplicación (Estilo Duolingo)
            const Text(
              'Remind', // Puedes cambiar esto por el nombre oficial de la app
              style: TextStyle(
                color: Colors.white, // Texto en blanco o un color que contraste
                fontSize: 48,
                fontWeight: FontWeight.w900, // Fuente muy gruesa
                letterSpacing: 2.0,
              ),
            ),

            const SizedBox(height: 50), 
            
            // 🔑 Indicador de Carga (Color blanco para contrastar con el fondo azul)
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}