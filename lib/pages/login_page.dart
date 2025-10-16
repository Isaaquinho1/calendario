import 'package:calendario/componentes/my_button.dart';
import 'package:calendario/componentes/my_textfield.dart';
import 'package:calendario/componentes/square_tile.dart';
//import 'package:calendario/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';


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

  // ------------------------------------------------------------------
  // FUNCIÓN MODIFICADA: Muestra mensaje de éxito (se cierra automáticamente)
  // ------------------------------------------------------------------
  void showSuccessMessage(String message) {
    showDialog(
      context: context,
      builder: (context) {
        // Cierra el diálogo automáticamente después de 2 segundos
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });

        return AlertDialog(
          backgroundColor: Colors.green, // Color verde para el éxito
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
          // Quitamos el botón ya que se cierra automáticamente
        );
      },
    );
  }

  // ------------------------------------------------------------------
  // FUNCIÓN MODIFICADA: TRADUCE LOS CÓDIGOS DE ERROR DE FIREBASE
  // ------------------------------------------------------------------
  void showErrorMessage(String errorCode) {
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
      case 'empty-password': // La contraseña está vacía
        message = 'La contraseña no puede estar vacía.';
        break;
      case 'missing-credentials': // Ambos campos vacíos
        message = 'El correo electrónico y la contraseña son requeridos.';
        break;
      case 'network-request-failed': // Problema de red
        message = 'Error de conexión. Verifique su conexión a Internet.';
        break;
      case 'unknown': // Error desconocido
      case 'unknown-error':
        message = 'Ocurrió un error inesperado. Por favor, intente de nuevo.';
        break;
      default:
        message = 'Ocurrió un error inesperado ($errorCode). Por favor, intente de nuevo.';
        break;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 11, 50, 193),
          title: Center(
            child: Text(
              message, // Muestra el mensaje traducido
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Aceptar", style: TextStyle(color: Colors.white)),
            ),
          ],
          actionsAlignment: MainAxisAlignment.center,
        );
      },
    );
  }

  // método para iniciar sesión de usuario
  void signUserIn() async {
    // ------------------------------------------------------------------
    // VALIDACIÓN: Verificar campos vacíos antes de la conexión
    // ------------------------------------------------------------------
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
          child: CircularProgressIndicator(color: Colors.deepPurple),
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
      // Se debe usar 'if (mounted)' para asegurar que el widget sigue en el árbol.
      if (mounted) {
        Navigator.pop(context);
        // 2. MUESTRA EL MENSAJE DE ÉXITO 🎉
        showSuccessMessage('¡Iniciaste sesión correctamente! Bienvenida.');
      }
    } on FirebaseAuthException catch (e) {
      // Si hay un error, cierra el indicador de carga y muestra el mensaje de error
      if (mounted) {
        Navigator.pop(context);
      }
      showErrorMessage(e.code);
    }
  }

  // Las funciones 'wrongEmailMessage' y 'wrongPasswordMessage' ya no son necesarias
  // porque 'showErrorMessage' maneja todos los casos.
  void wrongEmailMessage() {}
  void wrongPasswordMessage() {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: Center(
          // Permite el desplazamiento vertical para pantallas pequeñas
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 50),

                // logo de la aplicación
                Image.asset(
                  'assets/remind.png',
                  height: 150, // Ajustado para centrar mejor
                ),

                const SizedBox(height: 10),

                // mensaje de bienvenida
                Text(
                  '¡Bienvenido de nuevo!', // Mensaje ligeramente más amigable
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 25,
                  ),
                ),

                const SizedBox(height: 10),

                                               // logo de la aplicación
                Image.asset(
                  'assets/remi.png',
                  height: 150,
                ),
                const SizedBox(height: 30),

                // mensaje de bienvenida
                Text(
                '¡Iniciar sesión!',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 25,
                  ),
                ),
                
                const SizedBox(height: 30),

                // campo de texto para correo
                MyTextField(
                  controller: emailController,
                  hintText: 'Ingresar correo electrónico', // Corregido
                  obscureText: false,
                ),

                const SizedBox(height: 10),

                // campo de texto para contraseña
                MyTextField(
                  controller: passwordController,
                  hintText: 'Ingresar contraseña', // Corregido el typo
                  obscureText: true,
                ),

                const SizedBox(height: 10),

                // ¿olvidaste la contraseña?
/*                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '¿Has olvidado tu contraseña?',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),*/

                const SizedBox(height: 25),

                // botón de inicio de sesión
                MyButton(
                  text: "Iniciar Sesión",
                  onTap: signUserIn,
                ),

                const SizedBox(height: 50),

                // ¿no eres miembro? registrarse ahora
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '¿No eres miembro?',
                      style: TextStyle(color: Colors.grey[700]),
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