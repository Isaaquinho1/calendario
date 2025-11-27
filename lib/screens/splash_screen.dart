// lib/screens/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:calendario/pages/auth_page.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:permission_handler/permission_handler.dart'; 
// Importar servicios del sistema operativo para manejo de estados
import 'dart:io' show Platform;
import 'dart:async'; // Para Completer

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with WidgetsBindingObserver {
  
  // 🔑 Color principal: #72C1F3
  static const Color primarySplashColor = Color(0xFF72C1F3);
  static const String remiAssetPath = 'assets/cara_remind.svg';
  
  // Flag para saber si estamos esperando el permiso de alarma
  bool _waitingForAlarmPermission = false;
  // Completer para manejar la pausa y reanudación de la aplicación
  Completer<void>? _resumedCompleter;

  @override
  void initState() {
    super.initState();
    // 💡 IMPORTANTE: Añadir observador para detectar cuando la app regresa de fondo/ajustes
    WidgetsBinding.instance.addObserver(this);
    _requestAndNavigate();
  }

  @override
  void dispose() {
    // 💡 IMPORTANTE: Eliminar el observador
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // 💡 Método del Mixin WidgetsBindingObserver: Se llama cuando la aplicación cambia de estado
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _waitingForAlarmPermission) {
      // Si la aplicación regresa de estar en pausa y estábamos esperando el permiso
      _resumedCompleter?.complete();
    }
  }

  // 3. FUNCIÓN DE NAVEGACIÓN Y SOLICITUD DE PERMISOS
  Future<void> _requestAndNavigate() async {
    // 1. SOLICITAR PERMISOS GENERALES
    if (Platform.isAndroid) {
      await Permission.notification.request();
    }

    // 2. SOLICITAR PERMISO DE ALARMA EXACTA (Crucial para Android 12+)
    if (Platform.isAndroid) {
      PermissionStatus status = await Permission.scheduleExactAlarm.status;
      
      // Si el permiso no ha sido concedido, lo solicitamos.
      if (!status.isGranted) {
        
        // Marcamos que estamos esperando la respuesta.
        setState(() => _waitingForAlarmPermission = true);
        _resumedCompleter = Completer<void>();
        
        // Solicitar y esperar que el usuario regrese
        await Permission.scheduleExactAlarm.request();
        
        // Esperamos a que didChangeAppLifecycleState complete el completer
        // Esto ocurrirá cuando el usuario regrese de la pantalla de ajustes de Alarmas.
        await _resumedCompleter!.future;

        // Limpiamos el estado
        setState(() => _waitingForAlarmPermission = false);
      }
    }

    // --- El resto de tu lógica original continúa ---
    // Si la pantalla sigue montada, continuamos (o si estamos esperando el permiso, mostramos un loader)
    if (_waitingForAlarmPermission) {
      // Si estamos aquí, es porque acabamos de regresar, volvemos a checar el estado
      PermissionStatus finalStatus = await Permission.scheduleExactAlarm.status;
      if (!finalStatus.isGranted) {
        // Opcional: Mostrar un mensaje si el usuario no dio el permiso
        _showPermissionDeniedMessage();
      }
    }


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

  void _showPermissionDeniedMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'El permiso de alarma es necesario para recordatorios exactos. Habilítalo en Ajustes.',
          textAlign: TextAlign.center,
        ),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 5),
      ),
    );
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
            
            if (_waitingForAlarmPermission)
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: Text(
                  'Activando permisos de alarma...',
                  style: TextStyle(color: Colors.white.withOpacity(0.8)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}