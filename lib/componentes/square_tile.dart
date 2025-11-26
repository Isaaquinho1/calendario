import 'package:flutter/material.dart'; // Importa los widgets de Material Design.

class SquareTile extends StatelessWidget {
  // Define un parámetro requerido para la ruta de la imagen.
  final String imagePath;
  final Function()? onTap;
  const SquareTile({
    super.key,
    required this.imagePath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20), // Añade relleno alrededor de la imagen.
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white), // Borde blanco.
        borderRadius: BorderRadius.circular(16), // Bordes muy redondeados.
        color: Colors.grey[200], // Color de fondo.
      ),
      child: Image.asset( // Muestra la imagen desde los assets del proyecto.
        imagePath,
        height: 40,
      ),
    );
  }
}