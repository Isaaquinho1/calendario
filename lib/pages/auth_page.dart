import 'package:calendario/pages/home_page.dart';
import 'package:calendario/pages/login_or_register_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthPage extends StatelessWidget{
  const AuthPage({super.key});

@override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot){
          //usuario logeado
          if (snapshot.hasData){
            return HomePage();
          }

          //usuario no logeado  
          else {
            return LoginOrRegisterPage();
          }
        }
      ),
    );
    

  }

}