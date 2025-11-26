import 'package:calendario/componentes/my_button.dart';
import 'package:calendario/componentes/my_textfield.dart';

// Importaciones corregidas
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart'; // 🔑 Importación de SVG
import '../screens/home_screen.dart'; // 🔑 Importar la pantalla de destino

class LoginPage extends StatefulWidget {
  final Function()? onTap;
  const LoginPage({super.key, required this.onTap});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // controladores de edición de texto
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // 🔑 NUEVO ESTADO: Controla si la contraseña es visible
  bool _isPasswordVisible = false;

  // ------------------------------------------------------------------
  // FUNCIÓN 1: Muestra mensaje de éxito (se cierra automáticamente)
  // ------------------------------------------------------------------
  void showSuccessMessage(String message) {
    if (!mounted) return;

    final navigator = Navigator.of(context); // guarda el estado del Navigator

    showDialog(
      context: context,
      builder: (dialogContext) {
        final dialogNavigator = Navigator.of(
          dialogContext,
        ); // guarda otro navigator local

        Future.delayed(const Duration(seconds: 2), () {
          if (!mounted) return;

          dialogNavigator.pop(); // usa el navigator, no el context

          navigator.pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        });

        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 114, 193, 243),
          title: Center(
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  // ------------------------------------------------------------------
  // FUNCIÓN 2: TRADUCE LOS CÓDIGOS DE ERROR DE FIREBASE (CORRECCIÓN DE SEGURIDAD)
  // ------------------------------------------------------------------
  void showErrorMessage(String errorCode) {
    // 🔑 Chequeo de seguridad al inicio de la función
    if (!mounted) return;

    String message;

    switch (errorCode) {
      case 'user-not-found':
        message = 'Usuario no encontrado. Verifique su correo electrónico.';
        break;
      case 'wrong-password':
        message = 'Contraseña incorrecta. Verifique sus credenciales.';
        break;
      case 'invalid-email':
        message = 'El formato del correo electrónico es inválido.';
        break;
      case 'user-disabled':
        message = 'Esta cuenta ha sido deshabilitada.';
        break;
      case 'too-many-requests':
        message = 'Demasiados intentos. Inténtelo más tarde.';
        break;
      case 'missing-email':
        message = 'El campo de correo electrónico no puede estar vacío.';
        break;
      case 'empty-password':
        message = 'La contraseña no puede estar vacía.';
        break;
      case 'missing-credentials':
        message = 'El correo electrónico y la contraseña son requeridos.';
        break;
      case 'network-request-failed':
        message = 'Error de conexión. Verifique su conexión a Internet.';
        break;
      case 'unknown':
      case 'unknown-error':
        message = 'Ocurrió un error inesperado. Por favor, intente de nuevo.';
        break;
      default:
        message =
            'Correo y/o contraseña incorrecto, por favor, intente de nuevo';
        break;
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        // 🔑 CORREGIDO: Usamos 'dialogContext' para la limpieza del linter
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 114, 193, 243),
          title: Center(
            child: Text(
              message, // Muestra el mensaje traducido
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(
                dialogContext,
              ), // Usamos dialogContext para cerrar el diálogo
              child: const Text(
                "Aceptar",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
          actionsAlignment: MainAxisAlignment.center,
        );
      },
    );
  }

  // método para iniciar sesión de usuario
  void signUserIn() async {
    // ... (Validación de campos vacíos)
    if (emailController.text.isEmpty && passwordController.text.isEmpty) {
      showErrorMessage('missing-credentials');
      return;
    }
    if (emailController.text.isEmpty) {
      showErrorMessage('missing-email');
      return;
    }
    if (passwordController.text.isEmpty) {
      showErrorMessage('empty-password');
      return;
    }
    // ------------------------------------------------------------------

    // MOSTRAR LA RUEDA DE CARGA
    showDialog(
      context: context,
      barrierDismissible: false, // Evita que se cierre al tocar fuera
      builder: (context) {
        return const Center(
          child: CircularProgressIndicator(
            color: Color.fromARGB(255, 114, 193, 243),
          ),
        );
      },
    );

    // intentar iniciar sesión
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      // 1. Cierra el indicador de carga
      if (mounted) {
        Navigator.pop(context);
        // 2. MUESTRA EL MENSAJE DE ÉXITO y NAVEGA A HOME SCREEN
        showSuccessMessage('¡Has iniciado sesión correctamente!');
      }
    } on FirebaseAuthException catch (e) {
      // Si hay un error, cierra el indicador de carga y muestra el mensaje de error
      if (mounted) {
        Navigator.pop(context);
        showErrorMessage(e.code);
      }
    }
  }

  // Las funciones 'wrongEmailMessage' y 'wrongPasswordMessage' ya no son necesarias
  // porque 'showErrorMessage' maneja todos los casos.
  void wrongEmailMessage() {}
  void wrongPasswordMessage() {}

  // ------------------------------------------------------------------
  // MÉTODO BUILD (DISEÑO ACTUALIZADO)
  // ------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 50),

                // 🔑 NUEVO LOGO: Remi2.svg (reemplaza a remind.png y remi.png)
                SvgPicture.asset(
                  'assets/alegre.svg', // <-- ¡RUTA COMPLETA AHORA!
                  height: 250,
                ),

                const SizedBox(height: 40),

                // 🔑 NUEVO TEXTO UNIFICADO: Inicia sesión o regístrate
                const Text(
                  "¡Tu regreso alegra a Remy! \n ¡Vamos,  Iniciar sesión!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color.fromARGB(255, 0, 0, 0), // Tono de gris oscuro
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                // ❌ ELIMINADO: Mensajes antiguos ('¡Bienvenido de nuevo!' e '¡Iniciar sesión!')
                const SizedBox(height: 30),

                // campo de texto para correo
                MyTextField(
                  controller: emailController,
                  hintText: 'Ingresar correo electrónico', // Corregido
                  obscureText: false,
                ),

                const SizedBox(height: 10),

                // 🔑 CAMPO DE CONTRASEÑA CORREGIDO
                MyTextField(
                  controller: passwordController,
                  hintText: 'Ingresar contraseña',
                  // Usa el estado para ocultar/mostrar
                  obscureText: !_isPasswordVisible,
                  // 🔑 Ícono de visibilidad
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: const Color.fromARGB(255, 59, 59, 59),
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible =
                            !_isPasswordVisible; // Alternar visibilidad
                      });
                    },
                  ),
                ),

                const SizedBox(height: 10),

                const SizedBox(height: 25),

                // botón de inicio de sesión
                MyButton(text: "Iniciar Sesión", onTap: signUserIn),

                const SizedBox(height: 50),

                // ¿no eres miembro? registrarse ahora
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '¿No eres miembro?',
                      style: TextStyle(
                        color: const Color.fromARGB(255, 0, 0, 0),
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: widget.onTap,
                      child: const Text(
                        'Regístrate ahora',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
