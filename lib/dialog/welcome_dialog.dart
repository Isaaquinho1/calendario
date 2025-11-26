import 'package:calendario/notifiers/theme_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

class WelcomeDialog extends StatefulWidget {
  final Box userBox;
  const WelcomeDialog({super.key, required this.userBox});

  @override
  State<WelcomeDialog> createState() => _WelcomeDialogState();
}

class _WelcomeDialogState extends State<WelcomeDialog> {
  final TextEditingController _nameController = TextEditingController();
  ThemeMode? _selectedTheme; // Para el feedback visual de los botones

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Inicializar el tema seleccionado basado en el estado actual de la app
    _selectedTheme = Provider.of<ThemeNotifier>(
      context,
      listen: false,
    ).currentTheme;
  }

  @override
  Widget build(BuildContext context) {
    // Obtenemos el notifier para poder llamarlo
    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
    // Obtenemos el tema actual para los colores del diálogo
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: theme.cardColor, // Color de tarjeta del tema
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Imagen de Remy
              SvgPicture.asset(
                'assets/alegre.svg', // Asegúrate de tener esta imagen en assets/
                height: 120,
              ),
              const SizedBox(height: 20),

              // 2. Mensaje de bienvenida
              Text(
                '¡Usuario nuevo, increíble!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface, // Color de texto del tema
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),
              Text(
                'Comencemos agregando tu nombre y eligiendo tu tema preferido.',
                style: TextStyle(
                  fontSize: 16,
                  color: theme
                      .colorScheme
                      .onSurfaceVariant, // Color de texto secundario
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 25),

              // 3. Campo de Nombre
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: '¿Cómo te llamas?',
                  hintText: 'Escribe tu nombre...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor:
                      theme.scaffoldBackgroundColor, // Fondo del textfield
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 20),

              // 4. Selectores de Tema
              Row(
                children: [
                  Expanded(
                    child: _buildThemeButton(
                      context: context,
                      notifier: themeNotifier,
                      mode: ThemeMode.light,
                      icon: Icons.wb_sunny_outlined,
                      text: 'Claro',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildThemeButton(
                      context: context,
                      notifier: themeNotifier,
                      mode: ThemeMode.dark,
                      icon: Icons.nightlight_outlined,
                      text: 'Oscuro',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // 5. Botón de "Comencemos"
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: theme.colorScheme.onPrimary,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  // Validar y guardar
                  if (_nameController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Por favor, ingresa tu nombre.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  // Guardar el nombre en Hive
                  widget.userBox.put('name', _nameController.text.trim());

                  // Cerrar el diálogo (esto reanudará la función signUserUp)
                  Navigator.pop(context);
                },
                child: const Text(
                  '¡Comencemos!',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget auxiliar para los botones de tema
  Widget _buildThemeButton({
    required BuildContext context,
    required ThemeNotifier notifier,
    required ThemeMode mode,
    required IconData icon,
    required String text,
  }) {
    final theme = Theme.of(context);
    final bool isSelected = _selectedTheme == mode;

    return OutlinedButton.icon(
      icon: Icon(icon),
      label: Text(text),
      style: OutlinedButton.styleFrom(
        foregroundColor: isSelected
            ? theme
                  .colorScheme
                  .onPrimary // Color de texto sobre fondo primario
            : theme.colorScheme.onSurface, // Color de texto normal
        backgroundColor: isSelected
            ? theme.primaryColor
            : Colors
                  .transparent, // Fondo de color primario si está seleccionado
        side: BorderSide(
          color: isSelected
              ? theme.primaryColor
              : theme.colorScheme.outline, // Borde estándar
          width: isSelected ? 2 : 1,
        ),
        minimumSize: const Size(100, 45),
      ),
      onPressed: () {
        // Actualizar el tema globalmente
        notifier.setTheme(mode);
        // Actualizar el estado local para el feedback visual
        setState(() {
          _selectedTheme = mode;
        });
      },
    );
  }
}
