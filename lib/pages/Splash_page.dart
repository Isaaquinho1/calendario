import 'package:flutter/material.dart';
import 'dart:async';

class SplashPage extends StatefulWidget{
  const SplashPage ({super.key});

  @override
  // TODO: implement builder
  State<SplashPage> createState () => _SplashPagetate();
}

class _SplashPagetate extends State<SplashPage> {
 @override
  void initState() {
    super.initState();
    // ⏳ Espera 3 segundos y luego navega al Login
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacementNamed(context, '/login');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //backgroundColor: Colors.purple[200],
        // Contenedor principal que tiene un degradado de color.
 
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            
            // ⬇️ Aquí está el Hero que hará la animación entre Splash y Login
            Hero(
              tag: 'appLogo',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/remind.png',
                  width: 300,
                  height: 200,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Cargando, por favor espere......',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}