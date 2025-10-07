import 'package:calendario/pages/login_page.dart';
import 'package:calendario/pages/register_page.dart';
import 'package:flutter/material.dart';

class LoginOrRegisterPage extends StatefulWidget{
  const LoginOrRegisterPage({super.key});

  @override
  State<LoginOrRegisterPage> createState () => _LoginOrRegisterPageState();
}

class _LoginOrRegisterPageState extends State<LoginOrRegisterPage>{

  // iniciando la muestra de la pagina de registro
  bool showLoginPage = true;

  // alternar  ntre registro y ingreso
  void togglePages(){
    setState(() {
      showLoginPage = !showLoginPage;
    });
  }

  @override
  Widget build(BuildContext context){
    if (showLoginPage){
      return LoginPage(
        onTap: togglePages ,
      );
          } else{
      return RegisterPage(
        onTap: togglePages,
      );
    }
  }
  
}