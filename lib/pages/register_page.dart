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

  //  ESTADOS DE VISIBILIDAD PARA CADA CAMPO

  bool _isPasswordVisible = false;

  bool _isConfirmPasswordVisible = false;

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
          backgroundColor: const Color.fromARGB(255, 114, 193, 243),

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
    if (!mounted) return;

    // Guardamos el navigator principal
    final navigator = Navigator.of(context);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        // Guardamos también el navigator del diálogo
        final dialogNavigator = Navigator.of(dialogContext);

        // Cerramos el diálogo y navegamos después de 0.5s
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted) return;

          dialogNavigator.pop(); // Cierra el diálogo
          navigator.pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        });

        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 114, 193, 243),
          title: const Center(
            child: Text(
              "Registro Exitoso",
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
  // FUNCIÓN: Muestra el diálogo de Términos y Condiciones (ACTUALIZADO)
  // ------------------------------------------------------------------
  void _showTermsAndConditionsDialog() {
    if (!mounted) return; //  Chequeo de seguridad

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            "Términos, Condiciones y Privacidad", // Título actualizado
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
          content: SingleChildScrollView(
            child: Text('''Términos y condiciones para Remind
Última actualización: CDMX a 5 de octubre de 2025

Bienvenido a Remind, una aplicación móvil diseñada para ayudar a los usuarios a organizar sus actividades, administrar mejor su tiempo y aumentar su productividad de manera sencilla y práctica.
Al descargar, instalar o utilizar la aplicación Remind, aceptas los presentes Términos y condiciones. Si no estás de acuerdo con alguno de ellos, te recomendamos no utilizar la aplicación.

1. Objeto de la aplicación
Remind ofrece a los usuarios una herramienta digital para:
Crear recordatorios y tareas.
Gestionar un calendario integrado.
Organizar actividades personales o laborales.
Mejorar la productividad y reducir el estrés derivado de la desorganización.

2. Aceptación de los términos
El uso de Remind implica la aceptación plena y sin reservas de los presentes Términos y condiciones, así como de la Política de Privacidad asociada.

3. Requisitos de uso
La aplicación está disponible para dispositivos móviles con sistemas operativos Android e iOS.
Debes contar con acceso a internet para sincronizar algunos datos.
El usuario es responsable de mantener la seguridad de su dispositivo y credenciales de acceso.

4. Registro y cuenta de usuario
Algunas funciones pueden requerir la creación de una cuenta personal.
La información proporcionada debe ser veraz, completa y actualizada.
El usuario es responsable de la confidencialidad de sus credenciales y actividades dentro de la aplicación.

5. Licencia de uso
Remind otorga al usuario una licencia limitada, personal, no exclusiva e intransferible para utilizar la aplicación únicamente con fines personales y no comerciales.

6. Propiedad intelectual
Todos los derechos de propiedad intelectual relacionados con la aplicación, su diseño, logotipos, textos, interfaces y funciones pertenecen a Remind o a sus licenciantes. Queda prohibida su copia, distribución o modificación sin autorización expresa.

7. Uso aceptable
El usuario se compromete a:
No utilizar la aplicación para actividades ilegales o no autorizadas.
No intentar vulnerar la seguridad o el funcionamiento de la app.
No distribuir virus o software malicioso a través de la plataforma.

8. Disponibilidad y actualizaciones
Remind puede sufrir interrupciones, errores o limitaciones técnicas. Nos reservamos el derecho de actualizar, modificar o suspender temporal o permanentemente la aplicación en cualquier momento.

9. Limitación de responsabilidad
Remind es una herramienta de apoyo para la organización personal, pero no garantiza resultados específicos en la productividad del usuario.
No nos hacemos responsables de pérdidas, daños o consecuencias derivados del uso o la imposibilidad de uso de la aplicación.

10. Privacidad y datos personales
El tratamiento de los datos personales se regirá por nuestra Política de privacidad, disponible dentro de la aplicación.

11. Modificaciones
Remind se reserva el derecho de modificar estos Términos y condiciones en cualquier momento. Los cambios serán notificados a través de la aplicación y entrarán en vigor desde su publicación.

12. Legislación aplicable
Estos Términos se regirán por las leyes del país en el que la aplicación se encuentre registrada y cualquier controversia se someterá a los tribunales competentes de dicha jurisdicción.

----------------------------------------

Política de privacidad – Remind
Última actualización: CDMX a 5 de octubre de 2025

En Remind, valoramos y respetamos la privacidad de nuestros usuarios. Esta Política de privacidad explica cómo recopilamos, usamos, protegemos y compartimos la información personal que proporcionas al usar nuestra aplicación móvil.
Al utilizar Remind, aceptas los términos de esta política. Si no estás de acuerdo, te recomendamos no utilizar la aplicación.

1. Información que recopilamos
Remind puede recopilar los siguientes tipos de información:
a) Información proporcionada por el usuario
Nombre, correo electrónico y/o contraseña, en caso de crear una cuenta.
Datos opcionales que el usuario agregue en sus tareas, notas o recordatorios.
b) Información técnica y del dispositivo
Tipo de dispositivo, sistema operativo (Android o iOS), versión de la app e identificadores únicos.
Dirección IP, zona horaria y configuración del idioma.
c) Información de uso
Frecuencia de uso, funciones utilizadas, fechas de creación o modificación de tareas.
Errores o fallos técnicos que ayuden a mejorar la aplicación.

2. Finalidad del tratamiento de datos
Los datos recopilados se utilizan para:
Permitir el funcionamiento correcto de la aplicación.
Guardar y sincronizar recordatorios, tareas y eventos del calendario.
Mejorar la experiencia del usuario y la calidad del servicio.
Ofrecer notificaciones o alertas personalizadas.
Mantener la seguridad de las cuentas y prevenir usos indebidos.

3. Bases legales del tratamiento
El tratamiento de los datos personales se realiza sobre las siguientes bases:
Consentimiento del usuario, al crear una cuenta o usar la app.
Cumplimiento de obligaciones contractuales, para garantizar el funcionamiento del servicio.
Interés legítimo de Remind en mejorar y mantener la aplicación.

4. Compartición de información
Remind no vende, alquila ni comparte información personal con terceros, salvo en los siguientes casos:
Proveedores de servicios tecnológicos que apoyan el funcionamiento de la app (por ejemplo, servicios de almacenamiento en la nube o autenticación).
Cumplimiento legal, cuando sea requerido por una autoridad competente conforme a la ley.
En todos los casos, se aplican medidas para garantizar la confidencialidad y seguridad de los datos.

5. Seguridad de la información
Implementamos medidas técnicas y organizativas razonables para proteger la información personal contra pérdida, robo, acceso no autorizado, alteración o destrucción.
No obstante, ningún sistema es completamente seguro, por lo que no podemos garantizar la seguridad absoluta de la información transmitida por internet.

6. Derechos del usuario
El usuario puede ejercer en cualquier momento sus derechos de:
Acceso: conocer qué datos se están tratando.
Rectificación: corregir información inexacta o incompleta.
Cancelación: solicitar la eliminación de sus datos personales.
Oposición: oponerse al uso de sus datos para fines no esenciales.
Para ejercer estos derechos, puede contactarnos en: [remindapp@gmail.com]

7. Conservación de los datos
Los datos personales se conservarán mientras el usuario mantenga su cuenta activa o mientras sea necesario para brindar los servicios de la aplicación.
Si el usuario elimina su cuenta, los datos se eliminarán o anonimizarán dentro de un plazo razonable.

8. Uso de Cookies y tecnologías similares
Remind puede emplear cookies locales o tecnologías similares (como almacenamiento interno del dispositivo) para mejorar la experiencia del usuario, guardar preferencias y optimizar el rendimiento de la aplicación.

9. Enlaces a terceros
La aplicación puede contener enlaces a servicios o sitios web externos.
Remind no se responsabiliza por las prácticas de privacidad de dichos sitios; se recomienda leer sus políticas antes de proporcionar cualquier información.

10. Modificaciones a la política
Nos reservamos el derecho de actualizar esta Política de privacidad en cualquier momento.
Las modificaciones se notificarán dentro de la aplicación y entrarán en vigor desde su publicación.

11. Contacto
Si tienes preguntas, comentarios o solicitudes relacionadas con esta Política de privacidad, puedes comunicarte con nosotros a través de:
 📧 [remindapp@gmail.com]
 📱 Aplicación: Remind
 🌐 Disponible para: Android e iO
''', style: TextStyle(color: Colors.grey[800], fontSize: 14)),
          ),
          // --- MEJORA DE UI ---
          // Añadimos un botón explícito para cerrar el diálogo
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Cerrar",
                style: TextStyle(
                  color: Colors.deepPurple,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
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
      showErrorMessage(
        "Debes aceptar los Términos y Condiciones para registrarte.",
      );

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

      if (passwordController.text != confirmPasswordController.text) {
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

      //  CORRECCIÓN DE LA LÍNEA 159: Uso del context después de await/lógica.

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
            errorMessage =
                'La contraseña es demasiado débil. Debe tener al menos 8 caracteres, una mayuscula y un número.';

            break;

          case 'email-already-in-use':
            errorMessage = 'El correo electrónico ya está registrado.';

            break;

          case 'invalid-email':
            errorMessage = 'El formato del correo electrónico es inválido.';

            break;

          case 'operation-not-allowed':
            errorMessage =
                'El registro de usuarios está deshabilitado temporalmente.';

            break;

          default:
            errorMessage =
                'La contraseña es demasiado débil. Debe tener al menos 8 caracteres, una mayuscula y un número.';

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
          child: SingleChildScrollView(
            // Usar SingleChildScrollView para evitar desbordamiento
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,

              children: [
                const SizedBox(height: 25),

                SvgPicture.asset(
                  'assets/remi2.svg',

                  height: 150, // Ajustar la altura
                ),

                const SizedBox(height: 25),

                // NUEVO TEXTO: ¡Hola, te damos la bienvenida a Remind!
                Text(
                  '¡Hola, te damos la bienvenida a Remind!',

                  textAlign: TextAlign.center,

                  style: TextStyle(
                    color: const Color.fromARGB(255, 0, 0, 0),

                    fontSize: 22, // Tamaño más grande que el original (20)

                    fontWeight: FontWeight.bold, // Texto en negritas
                  ),
                ),

                const SizedBox(height: 30),

                // NUEVO TEXTO DE INSTRUCCIÓN (Reemplaza el texto '¡Regístrate')

                /*Text(

                  'Registrate',

                  style: TextStyle(

                    color: Colors.grey[700],

                    // Tamaño similar a un hintText (el que usa MyTextField)

                    fontSize: 16,

                  ),

                ),

               

                const SizedBox(height: 30),

*/

                // username textfield
                MyTextField(
                  controller: emailController,

                  hintText:
                      'Ingresar correo electrónico', // Corrección de acento

                  obscureText: false,
                ),

                const SizedBox(height: 10),

                // CAMPO DE CONTRASEÑA (passwordController)
                MyTextField(
                  controller: passwordController,

                  hintText: 'Ingresar contraseña',

                  // Usa el estado para ocultar/mostrar
                  obscureText: !_isPasswordVisible,

                  // Ícono de visibilidad
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

                // CAMPO DE CONFIRMACIÓN DE CONTRASEÑA (confirmPasswordController)
                MyTextField(
                  controller: confirmPasswordController,

                  hintText: 'Confirmar contraseña',

                  // Usa el estado de confirmación
                  obscureText: !_isConfirmPasswordVisible,

                  // Ícono de visibilidad
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isConfirmPasswordVisible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,

                      color: const Color.fromARGB(255, 59, 59, 59),
                    ),

                    onPressed: () {
                      setState(() {
                        _isConfirmPasswordVisible =
                            !_isConfirmPasswordVisible; // Alternar visibilidad
                      });
                    },
                  ),
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
                        onTap:
                            _showTermsAndConditionsDialog, // Llama al diálogo

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
