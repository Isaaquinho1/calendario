// lib/screens/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:calendario/pages/auth_page.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:permission_handler/permission_handler.dart'; // <-- 1. IMPORTAR EL PAQUETE

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // 🔑 Color principal: #72C1F3
  static const Color primarySplashColor = Color(0xFF72C1F3);

  // 🔑 CORRECCIÓN: Usaremos la ruta completa para el asset
  static const String remiAssetPath = 'assets/cara_remind.svg';

  @override
  void initState() {
    super.initState();
    // 2. CAMBIAMOS EL NOMBRE DE LA FUNCIÓN QUE SE LLAMA
    _requestAndNavigate();
  }

  // 3. FUNCIÓN ACTUALIZADA
  Future<void> _requestAndNavigate() async {
    // 4. AÑADIMOS LA LÓGICA DE PERMISOS
    // Pedimos el permiso de notificación al usuario.
    // Esto mostrará el diálogo del sistema en Android 13+
    await Permission.notification.request();

    // --- El resto de tu lógica original continúa ---

    // Espera 3 segundos (para el efecto visual de Duolingo)
    await Future.delayed(const Duration(seconds: 3));

    // Muestra el mensaje de bienvenida y luego navega a AuthPage
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Bienvenido a Remind!', textAlign: TextAlign.center),
          duration: Duration(seconds: 2),
        ),
      );

      // Espera 2.5 segundos para que el usuario pueda leer el mensaje
      await Future.delayed(const Duration(milliseconds: 2500));

      // Navega a la página de autenticación (AuthPage)
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AuthPage()),
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
            // 🔑 CORRECCIÓN DE LA RUTA: SvgPicture.asset('assets/cara_remind.svg')
            SvgPicture.asset(
              remiAssetPath,
              height: 250, // Dimensionar para que destaque en el centro
              width: 250,
            ),

            const SizedBox(height: 20), // Espacio entre mascota y texto
            // 🔑 Nombre de la aplicación (Estilo Duolingo)
            const Text(
              'Remind',
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
