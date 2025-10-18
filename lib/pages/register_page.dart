import 'package:calendario/componentes/my_button.dart';
import 'package:calendario/componentes/my_textfield.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../screens/home_screen.dart'; // 🔑 Añadida importación para navegar a HomeScreen

class RegisterPage extends StatefulWidget {
  final Function()? onTap;
  const RegisterPage({super.key, required this.onTap});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // text editing controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // NUEVO: Estado para el checkbox de términos y condiciones
  bool _agreedToTerms = false;

  // ------------------------------------------------------------------
  // FUNCIÓN: Muestra mensajes de error al usuario (fondo morado)
  // ------------------------------------------------------------------
  void showErrorMessage(String message) {
    if (!mounted) return; // 🔑 Chequeo de seguridad al inicio
    
    showDialog(
      context: context,
      barrierDismissible: true, // Permitir cerrar al tocar fuera
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.deepPurple,
          title: const Center(
            child: Text(
              "Error de Registro", // Título en español para el diálogo
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          content: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          // Se han eliminado las acciones (el botón "Aceptar")
        );
      },
    );
  }

  // ------------------------------------------------------------------
  // FUNCIÓN: Mostrar mensaje de éxito (fondo verde)
  // ------------------------------------------------------------------
  void showSuccessMessage(String message) {
    if (!mounted) return; // 🔑 Chequeo de seguridad al inicio
    
    showDialog(
      context: context,
      barrierDismissible: true, // Permitir cerrar al tocar fuera
      builder: (dialogContext) { // Usamos 'dialogContext' para evitar ambigüedad
        
        // Cierra el diálogo y NAVEGA automáticamente después de un pequeño delay
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            // Cierra el diálogo
            Navigator.pop(dialogContext); 
            
            // NAVEGACIÓN A HOME SCREEN DESPUÉS DEL ÉXITO
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()), 
            );
          }
        });
        
        return AlertDialog(
          backgroundColor: Colors.green, // Color verde para indicar éxito
          title: const Center(
            child: Text(
              "Registro Exitoso", // Título de éxito
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          content: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        );
      },
    );
  }

  // ------------------------------------------------------------------
  // FUNCIÓN: Muestra el diálogo de Términos y Condiciones
  // ------------------------------------------------------------------
  void _showTermsAndConditionsDialog() {
    if (!mounted) return; // 🔑 Chequeo de seguridad
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            "Términos y Condiciones",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple),
          ),
          content: SingleChildScrollView(
            child: Text(
              "Gracias por usar Remind. Al crear una cuenta, usted acepta los siguientes términos:\n\n"
              "*1. Aceptación de Términos:* El uso de la aplicación implica la aceptación total de estos términos, los cuales pueden ser actualizados sin previo aviso.\n\n"
              "*2. Privacidad:* Sus datos (correo y contraseña) se almacenan de forma segura mediante Firebase Authentication y no serán compartidos con terceros sin su consentimiento, excepto por requerimiento legal.\n\n"
              "*3. Uso Adecuado:* La aplicación debe ser utilizada para fines lícitos y personales. Queda prohibido el uso indebido o malicioso del servicio.\n\n"
              "*4. Limitación de Responsabilidad:* No somos responsables por pérdidas o daños derivados del uso o la incapacidad de usar la aplicación.\n\n"
              "Presiona fuera del cuadro para cerrar.",
              style: TextStyle(color: Colors.grey[800], fontSize: 14),
            ),
          ),
        );
      },
    );
  }

  // ------------------------------------------------------------------
  // MÉTODO PRINCIPAL: sign user up method
  // ------------------------------------------------------------------
  void signUserUp() async {
    // 0. VALIDACIÓN DE ACEPTACIÓN DE TÉRMINOS
    if (!_agreedToTerms) {
      showErrorMessage("Debes aceptar los Términos y Condiciones para registrarte.");
      return;
    }

    // 1. VALIDACIÓN DE CAMPOS VACÍOS
    if (emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      showErrorMessage("Por favor, rellena todos los campos.");
      return;
    }

    // MOSTRAR LA RUEDA DE CARGA
    if (!mounted) return; // Chequeo antes de usar context para showDialog
    showDialog(
      context: context,
      barrierDismissible: false, // Evita que se cierre al tocar fuera
      builder: (context) {
        return const Center(
          child: CircularProgressIndicator(color: Colors.deepPurple),
        );
      },
    );

    // Intentar crear el usuario
    try {
      // 2. Verificar si las contraseñas coinciden
      if (passwordController.text != confirmPasswordController.text){
        
        // 🔑 CORRECCIÓN DE LA LÍNEA 152: Uso del context después de await/lógica.
        if (mounted) {
          Navigator.pop(context); // Cierra la rueda de carga
          showErrorMessage("Las contraseñas no coinciden.");
        }
        return; // Detener la función
      }

      // 3. Crear el usuario en Firebase
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      // Si es exitoso, quitar la rueda de carga y mostrar mensaje.
      // 🔑 CORRECCIÓN DE LA LÍNEA 159: Uso del context después de await/lógica.
      if (mounted) {
        Navigator.pop(context);
        showSuccessMessage("Cuenta registrada correctamente.");
      }

    } on FirebaseAuthException catch (e) {
      
      // Manejo de errores de Firebase
      if (mounted) {
        // Quitar la rueda de carga
        Navigator.pop(context);

        String errorMessage;
        // Traducir los códigos de error comunes de Firebase
        switch (e.code) {
          case 'weak-password':
            errorMessage = 'La contraseña es demasiado débil. Debe tener al menos 6 caracteres.';
            break;
          case 'email-already-in-use':
            errorMessage = 'El correo electrónico ya está registrado.';
            break;
          case 'invalid-email':
            errorMessage = 'El formato del correo electrónico es inválido.';
            break;
          case 'operation-not-allowed':
            errorMessage = 'El registro de usuarios está deshabilitado temporalmente.';
            break;
          default:
            errorMessage = 'Ocurrió un error inesperado. Código: ${e.code}';
            break;
        }
        showErrorMessage(errorMessage);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView( // Usar SingleChildScrollView para evitar desbordamiento
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 25),

                SvgPicture.asset(
                  'remi2.svg',
                  height: 150, // Ajustar la altura
                ),

                const SizedBox(height: 25),

                // 🔑 NUEVO TEXTO: ¡Hola, te damos la bienvenida a Remind!
                Text(
                  '¡Hola, te damos la bienvenida a Remind!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 22, // Tamaño más grande que el original (20)
                    fontWeight: FontWeight.bold, // Texto en negritas
                  ),
                ),

                const SizedBox(height: 30),

                // ❌ ELIMINADO: logo remi (remi.png)

                // 🔑 NUEVO TEXTO DE INSTRUCCIÓN (Reemplaza el texto '¡Regístrate')
                Text(
                  'Ingresa tu correo electrónico para comenzar',
                  style: TextStyle(
                    color: Colors.grey[700],
                    // Tamaño similar a un hintText (el que usa MyTextField)
                    fontSize: 16, 
                  ),
                ),
                
                const SizedBox(height: 30),

                // username textfield
                MyTextField(
                  controller: emailController,
                  hintText: 'Ingresar correo electrónico', // Corrección de acento
                  obscureText: false,
                ),

                const SizedBox(height: 10),

                // password textfield
                MyTextField(
                  controller: passwordController,
                  hintText: 'Ingresar contraseña',
                  obscureText: true,
                ),

                const SizedBox(height: 10),

                // confirm password textfield
                MyTextField(
                  controller: confirmPasswordController,
                  hintText: 'Confirmar contraseña',
                  obscureText: true,
                ),

                const SizedBox(height: 15),

                // NUEVO: Checkbox de Términos y Condiciones
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _agreedToTerms,
                        onChanged: (newValue) {
                          setState(() {
                            _agreedToTerms = newValue!;
                          });
                        },
                        activeColor: const Color.fromARGB(255, 58, 183, 100),
                      ),
                      Text(
                        'Acepto los ',
                        style: TextStyle(color: Colors.grey[700], fontSize: 14),
                      ),
                      GestureDetector(
                        onTap: _showTermsAndConditionsDialog, // Llama al diálogo
                        child: const Text(
                          'Términos y condiciones',
                          style: TextStyle(
                            color: Colors.blue, // Palabra clave en azul
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // sign in button
                MyButton(
                  text: "Registrarse", // Cambio a mayúscula
                  onTap: signUserUp,
                ),

                const SizedBox(height: 50),

                // already a member? login now
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '¿Ya tienes una cuenta?', // Texto más natural
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: widget.onTap,
                      child: const Text(
                        'Iniciar sesión', // Cambio de texto
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