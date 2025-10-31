import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
// No se necesitan imports de imagen

class EditProfileScreen extends StatefulWidget {
  final Box userBox;

  const EditProfileScreen({
    super.key,
    required this.userBox,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  // Controladores
  late TextEditingController _nameController;
  // Se eliminó _emailController
  final _passwordController = TextEditingController();
  final _currentPasswordController = TextEditingController(); // Aún necesario para cambiar contraseña

  // Variables de estado
  bool _isLoading = false;
  final _currentUser = FirebaseAuth.instance.currentUser;

  // Se eliminaron las variables y funciones de imagen

  @override
  void initState() {
    super.initState();
    // Cargar datos iniciales
    _nameController = TextEditingController(
      text: widget.userBox.get('name', defaultValue: 'Usuario'),
    );
    // Se eliminó la inicialización de _emailController
  }

  @override
  void dispose() {
    _nameController.dispose();
    // Se eliminó _emailController.dispose()
    _passwordController.dispose();
    _currentPasswordController.dispose();
    super.dispose();
  }

  // --- Diálogo para pedir la contraseña actual (SOLO SI CAMBIA CONTRASEÑA) ---
  Future<String?> _showReauthDialog() async {
    _currentPasswordController.clear();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar identidad'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'Para cambiar tu contraseña, por favor ingresa tu contraseña actual.'), // Texto ajustado
            const SizedBox(height: 16),
            TextField(
              controller: _currentPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Contraseña actual'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null), // Cancelar
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx, _currentPasswordController.text);
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  // --- FUNCIÓN PARA ACTUALIZAR PERFIL (SIMPLIFICADA) ---
  Future<void> _updateProfile() async {
    // 1. Obtenemos el usuario actual
    final user = _currentUser;
    if (user == null) return;
    
    setState(() { _isLoading = true; });

    String successMessage = ''; // Empezamos vacío

    // 1. Definir qué ha cambiado
    final bool nameChanged =
        _nameController.text.trim() != (user.displayName ?? widget.userBox.get('name'));
    // Se eliminó emailChanged
    final bool passwordChanged = _passwordController.text.trim().isNotEmpty;
    // Se eliminó imageChanged

    try {
      // --- A. Actualización de Nombre (no sensible) ---
      if (nameChanged) {
        await user.updateDisplayName(_nameController.text.trim());
        await widget.userBox.put('name', _nameController.text.trim());
        successMessage += 'Nombre actualizado. ';
      }

      // --- B. Actualización SENSIBLE (Solo Contraseña) ---
      if (passwordChanged) { // Solo si la contraseña cambió
        // B.1 Pedir contraseña actual
        final currentPassword = await _showReauthDialog();
        if (currentPassword == null || currentPassword.isEmpty) {
          throw Exception('Autenticación cancelada.');
        }

        // B.2 Re-autenticar al usuario
        AuthCredential credential = EmailAuthProvider.credential(
          email: user.email!, 
          password: currentPassword,
        );
        await user.reauthenticateWithCredential(credential);

        // B.3 Si la re-autenticación es exitosa, aplicar cambio de contraseña
        await user.updatePassword(_passwordController.text.trim()); 
        successMessage += 'Contraseña actualizada. ';
      }
      
      if (successMessage.isEmpty) {
        successMessage = 'No se realizaron cambios.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(successMessage), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true); // Regresa (y avisa que hubo cambios)
      }

    } on FirebaseAuthException catch (e) {
      String errorMessage = e.message ?? 'Ocurrió un error.';
      if (e.code == 'wrong-password') {
        errorMessage = 'Contraseña actual incorrecta. Inténtalo de nuevo.';
      }
      // Se eliminó el caso 'email-already-in-use'
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Colores
    const Color primaryColor = Color.fromARGB(255, 55, 78, 107);
    const Color backgroundColor = Color.fromARGB(255, 232, 232, 232);

    // Obtenemos el usuario aquí también para mostrar el email
    final user = _currentUser;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Editar Perfil'),
        backgroundColor: backgroundColor,
        elevation: 0,
        foregroundColor: primaryColor,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  
                  // Se eliminó el CircleAvatar

                  // --- CAMPO DE USUARIO (Nombre) ---
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Usuario (Nombre)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // --- CAMPO DE EMAIL (NO EDITABLE) ---
                  TextField(
                    controller: TextEditingController(text: user?.email ?? '...'), // Muestra el email actual
                    readOnly: true, // No se puede editar
                    decoration: const InputDecoration(
                      labelText: 'Email (No se puede cambiar)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email_outlined),
                      filled: true,
                      fillColor: Colors.black12, // Fondo grisáceo
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),

                  // --- CAMPO DE CONTRASEÑA ---
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Nueva Contraseña (dejar vacío para no cambiar)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- BOTÓN ACTUALIZAR ---
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _updateProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Actualizar'),
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
}
