import 'package:calendario/componentes/my_button.dart';
import 'package:calendario/componentes/my_textfield.dart';
import 'package:calendario/componentes/square_tile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';



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

  // sign user in method
  void signUserUp() async{

    //MOSTRAR LA RUEDA DE CARGA
    showDialog(
      context: context, 
      builder: (context){
        return const Center(
          child:  CircularProgressIndicator(),
        );
      },
    );
   
   //crear nuevamente
    try {
      // checar si la contraseña es confirmada
      if (passwordController.text == confirmPasswordController.text){
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text, 
          password: passwordController.text,
      );
      } else {
        //show error message, passwords don't match
        showErrorMessage("contraseña no coincide");

      }
      //mostrar carga circular
      Navigator.pop(context);
    }on FirebaseAuthException catch (e){
      //mostrar carga circular
      Navigator.pop(context);
      //error de usuario
      showErrorMessage(e.code);
      }  
    }

   //error message to user
   void showErrorMessage(String message){
    showDialog(
      context: context, 
      builder: (context){
        return AlertDialog(
          backgroundColor: Colors.deepPurple,
          title: Center(
            child:  Text(
              message,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
   },
    ); 

  }

  //mostrar ventana emergente correo
  void wrongEmailMessage(){
    showDialog(
      context: context,
      builder: (context){
        return const AlertDialog(
          title: Text('Correo incorrecto'),
        );
      },
    );
  }

  //mostrar ventana emergente contraseña
    void wrongPasswordMessage(){
    showDialog(
      context: context,
      builder: (context){
        return const AlertDialog(
          title: Text('Contraseña incorrecta'),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 25),

              // remind logo
              Image.asset
              ('assets/remind.png',
                height: 200,
              ),

              // let's create an account for you
              Text(
                '¡Vamos, crea una cuenta para ti',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 25 ,
                ),
              ),

              const SizedBox(height: 50),

              Text(
                '¡Registrate ahora!',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 25,
                ),
              ),

              const SizedBox(height: 50),
              // username textfield
              MyTextField(
                controller: emailController,
                hintText: 'correo electronico',
                obscureText: false,
              ),

              const SizedBox(height: 10),

              // password textfield
              MyTextField(
                controller: passwordController,
                hintText: 'Contraseña',
                obscureText: true,
              ),

              const SizedBox(height: 10),

              // confirm password textfield
              MyTextField(
                controller: confirmPasswordController,
                hintText: 'Confirmar contraseña',
                obscureText: true,
              ),

              const SizedBox(height: 10),

              // sign in button
              MyButton(
                text: "registrarse",
                onTap: signUserUp,
              ),

              const SizedBox(height: 50),

              // or continue with
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Divider(
                        thickness: 0.5,
                        color: Colors.grey[400],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: Text(
                        'O continuar con',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        thickness: 0.5,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 50),

              // google + apple sign in buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  // google button
                  SquareTile(imagePath: 'assets/google.png'),

                  SizedBox(width: 25),

                  // apple button
                  SquareTile(imagePath: 'assets/apple.png')
                ],
              ),

              const SizedBox(height: 50),

              // not a member? register now
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '¿ya tengo una cuenta?',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  const SizedBox(width: 4),
                   GestureDetector(
                    onTap: widget.onTap,
                    child: const Text(
                    'Iniciar ahora',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                   ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  } 
}


