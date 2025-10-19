// lib/componentes/my_textfield.dart

import 'package:flutter/material.dart';

class MyTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  // 🔑 NUEVOS CAMPOS: Para el ícono de visibilidad
  final Widget? suffixIcon; // Ícono a mostrar al final
  final String? errorText;  // Mensaje de error (si aplica)

  const MyTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.obscureText,
    this.suffixIcon, // Añadir al constructor
    this.errorText,  // Añadir al constructor
  });

  @override
  Widget build(BuildContext context) {
    // 🔑 Colores del tema (Tomados de un contexto minimalista)
    const Color primaryColor = Color.fromARGB(255, 55, 78, 107); 
    const Color cardColor = Color.fromARGB(255, 212, 212, 212);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: TextStyle(color: primaryColor), // Estilo del texto
        decoration: InputDecoration(
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: cardColor),
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: primaryColor, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          fillColor: Colors.white,
          filled: true,
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey[500]),
          errorText: errorText, // Muestra el error
          
          // 🔑 INTEGRACIÓN DEL ÍCONO DE VISIBILIDAD (al final del campo)
          suffixIcon: suffixIcon, 
        ),
      ),
    );
  }
}