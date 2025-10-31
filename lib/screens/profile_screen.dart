import 'package:calendario/screens/edit_profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/task.dart'; // <-- Ajusta la ruta a tu modelo Task

class ProfileScreen extends StatefulWidget {
  final Box userBox;
  final Box<Task> taskBox;

  const ProfileScreen({
    super.key,
    required this.userBox,
    required this.taskBox,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Variables de estado
  bool _isLoading = false;
  late int _completedTasks;
  late String _userName;
  final _currentUser = FirebaseAuth.instance.currentUser;

  // --- NUEVO: Lista de iconos predefinidos ---
  final List<IconData> _profileIcons = [
    Icons.person,
    Icons.face,
    Icons.star,
    Icons.favorite,
    Icons.pets,
    Icons.emoji_emotions,
    Icons.eco,
  ];
  late int _selectedIconIndex; // Índice del icono actual
  // --- FIN NUEVO ---

  // Colores (definidos aquí para usarlos en toda la clase)
  final Color primaryColor = const Color.fromARGB(255, 55, 78, 107);
  final Color backgroundColor = const Color.fromARGB(255, 232, 232, 232);

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  // Carga o recarga los datos del perfil desde Hive
  void _loadProfileData() {
    setState(() {
      _userName = widget.userBox.get('name', defaultValue: 'Usuario');
      _completedTasks =
          widget.taskBox.values.where((t) => t.isCompleted).length;
      // --- NUEVO: Cargar índice del icono (0 por defecto) ---
      _selectedIconIndex = widget.userBox.get('profile_icon_index', defaultValue: 0);
      // Asegurarse de que el índice sea válido
      if (_selectedIconIndex < 0 || _selectedIconIndex >= _profileIcons.length) {
        _selectedIconIndex = 0;
      }
      // --- FIN NUEVO ---
    });
  }

  // --- NUEVO: Diálogo para seleccionar icono ---
  Future<void> _showIconPickerDialog() async {
    final int? selectedIndex = await showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text('Selecciona un icono de perfil'),
          children: <Widget>[
            // Usamos Wrap para que los iconos se ajusten si no caben en una línea
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Wrap(
                spacing: 20.0, // Espacio horizontal
                runSpacing: 20.0, // Espacio vertical
                alignment: WrapAlignment.center,
                children: List<Widget>.generate(_profileIcons.length, (index) {
                  return InkWell(
                    onTap: () {
                      Navigator.pop(context, index); // Devuelve el índice seleccionado
                    },
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor: _selectedIconIndex == index
                          ? primaryColor.withAlpha(102) // Resalta el actual
                          : Colors.grey.shade200,
                      child: Icon(
                        _profileIcons[index],
                        size: 35.0,
                        color: primaryColor,
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        );
      },
    );

    // Si el usuario seleccionó un icono
    if (selectedIndex != null && selectedIndex != _selectedIconIndex) {
      // Guardar el nuevo índice en Hive
      await widget.userBox.put('profile_icon_index', selectedIndex);
      // Actualizar la UI
      setState(() {
        _selectedIconIndex = selectedIndex;
      });
    }
  }
  // --- FIN NUEVO ---


  // --- FUNCIÓN PARA MOSTRAR DIÁLOGO DE RE-AUTENTICACIÓN (SIN CAMBIOS) ---
  Future<void> _showReauthDialog() async {
    final passwordController = TextEditingController();
    bool isDialogLoading = false; // Estado de carga solo para el diálogo

    

    // Se usa un StatefulBuilder para que el diálogo pueda tener su propio estado
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // El usuario debe confirmar o cancelar
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Confirmar identidad'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                      'Por favor, ingresa tu contraseña actual para continuar.'),
                  const SizedBox(height: 16),
                  if (isDialogLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Contraseña',
                        border: OutlineInputBorder(),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: isDialogLoading
                      ? null
                      : () async {
                          if (_currentUser == null ||
                              _currentUser.email == null) {return;
                              }

                          setDialogState(() {
                            isDialogLoading = true;
                          });

                          try {
                            // 1. Crear la credencial
                            final credential = EmailAuthProvider.credential(
                              email: _currentUser.email!,
                              password: passwordController.text.trim(),
                            );
                            
                            // 2. Re-autenticar al usuario
                            await _currentUser
                                .reauthenticateWithCredential(credential);

                            // 3. Éxito: cerrar diálogo y navegar
                            Navigator.pop(dialogContext); // Cierra el diálogo

                            // 4. Navegar a la pantalla de edición y esperar resultado
                            final bool? didUpdate = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditProfileScreen(
                                  userBox: widget.userBox,
                                ),
                              ),
                            );

                            // 5. Si se actualizó, recargar datos
                            if (didUpdate == true) {
                              _loadProfileData();
                            }
                          } on FirebaseAuthException catch (e) {
                            // 6. Error: mostrar snackbar
                            Navigator.pop(dialogContext); // Cierra el diálogo
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(e.code == 'wrong-password'
                                    ? 'Contraseña incorrecta.'
                                    : 'Error: ${e.message}'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                  child: const Text('Confirmar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

// --- FUNCIÓN PARA BORRAR CUENTA (MODIFICADA) ---
  Future<void> _deleteAccount() async {
    if (_currentUser == null) return;

    // 1. Mostrar diálogo de confirmación (SIN CAMBIOS)
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Estás seguro?'),
        content: const Text(
            'Esta acción es irreversible. Se borrará tu cuenta y todas tus tareas asociadas.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('BORRAR', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // 2. Si confirma, proceder a borrar
    setState(() {
      _isLoading = true;
    });

    try {
      // 2a. Borrar la caja de tareas del disco
      await widget.taskBox.deleteFromDisk();
      // 2b. Borrar el usuario de Firebase Auth
      await _currentUser.delete();

      // --- INICIO: CAMBIOS AQUÍ ---
      // 3. Mostrar mensaje de éxito (si aún está montado)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cuenta eliminada correctamente.'),
            backgroundColor: Colors.green, // Color verde para éxito
            duration: Duration(seconds: 2), // Duración del mensaje
          ),
        );
        // Esperamos un poco para que el usuario vea el mensaje
        await Future.delayed(const Duration(seconds: 2)); 
      }
      
      // 4. Enviar al usuario a la pantalla de login (si aún está montado)
      if (mounted) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/login', (route) => false);
      }
      // --- FIN: CAMBIOS AQUÍ ---

    } on FirebaseAuthException catch (e) {
      String message = 'Error: ${e.message}';
      if (e.code == 'requires-recent-login') {
        message =
            'Esta operación es sensible. Por favor, vuelve a iniciar sesión e inténtalo de nuevo.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } finally {
      // Quitar el spinner de carga si aún está montado
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Perfil'),
        backgroundColor: backgroundColor,
        elevation: 0,
        foregroundColor: primaryColor,
        actions: [
          // --- ICONO DE AJUSTES AÑADIDO ---
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showReauthDialog, // Llama al diálogo de contraseña
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // --- AVATAR (MODIFICADO) ---
                  GestureDetector( // <-- Envolver en GestureDetector
                    onTap: _showIconPickerDialog, // <-- Llamar al diálogo
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: primaryColor.withAlpha(127), // Fondo suave
                      child: Icon(
                        _profileIcons[_selectedIconIndex], // <-- Mostrar icono seleccionado
                        size: 60,
                        color: primaryColor
                      ),
                    ),
                  ),
                  // --- FIN MODIFICACIÓN AVATAR ---
                  const SizedBox(height: 12),

                  // --- TAREAS COMPLETADAS ---
                  Text(
                    '$_completedTasks',
                    style: const TextStyle(
                        fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'tareas completadas',
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  const SizedBox(height: 24),

                  // --- CAMPO DE USUARIO (SOLO VISUALIZACIÓN) ---
                  _buildProfileInfoTile(
                    icon: Icons.person_outline,
                    title: 'Usuario (Nombre)',
                    subtitle: _userName,
                  ),
                  const SizedBox(height: 16),

                  // --- EMAIL (SOLO VISUALIZACIÓN) ---
                  _buildProfileInfoTile(
                    icon: Icons.email_outlined,
                    title: 'Email',
                    subtitle: _currentUser?.email ?? '...',
                  ),
                  const SizedBox(height: 40), // Más espacio

                  // --- BOTÓN BORRAR CUENTA ---
                  TextButton(
                    onPressed: _isLoading ? null : _deleteAccount,
                    child: const Text(
                      'Borrar mi cuenta',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- SPINNER DE CARGA ---
          if (_isLoading)
            Container(
              color: Colors.black.withAlpha(127),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  // --- WIDGET AUXILIAR PARA MOSTRAR DATOS (SIN CAMBIOS) ---
  Widget _buildProfileInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(127),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: primaryColor),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
