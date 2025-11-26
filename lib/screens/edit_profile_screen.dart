import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class EditProfileScreen extends StatefulWidget {
  final Box userBox;

  const EditProfileScreen({super.key, required this.userBox});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  // Controladores
  late TextEditingController _nameController;
  final _passwordController = TextEditingController();
  final _currentPasswordController = TextEditingController();

  // Variables de estado
  bool _isLoading = false;
  bool _isDeleting = false;
  final _currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.userBox.get('name', defaultValue: 'Usuario'),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _currentPasswordController.dispose();
    super.dispose();
  }

  // --- Diálogo para pedir la contraseña actual ---
  Future<String?> _showReauthDialog({bool forDelete = false}) async {
    _currentPasswordController.clear();

    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(
          forDelete ? 'Confirmar eliminación' : 'Confirmar identidad',
          style: TextStyle(fontSize: isSmallScreen ? 18 : 20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              forDelete
                  ? 'Esta acción es irreversible. Para eliminar tu cuenta, ingresa tu contraseña:'
                  : 'Para cambiar tu contraseña, por favor ingresa tu contraseña actual.',
              style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _currentPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Contraseña actual',
                border: const OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 12 : 16,
                  vertical: isSmallScreen ? 12 : 16,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: Text(
              'Cancelar',
              style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx, _currentPasswordController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: forDelete ? Colors.red : null,
            ),
            child: Text(
              forDelete ? 'Eliminar' : 'Confirmar',
              style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
            ),
          ),
        ],
      ),
    );
  }

  // --- FUNCIÓN PARA ACTUALIZAR PERFIL ---
  Future<void> _updateProfile() async {
    final user = _currentUser;
    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    String successMessage = '';

    final bool nameChanged =
        _nameController.text.trim() !=
        (user.displayName ?? widget.userBox.get('name'));
    final bool passwordChanged = _passwordController.text.trim().isNotEmpty;

    try {
      if (nameChanged) {
        await user.updateDisplayName(_nameController.text.trim());
        await widget.userBox.put('name', _nameController.text.trim());
        successMessage += 'Nombre actualizado. ';
      }

      if (passwordChanged) {
        final currentPassword = await _showReauthDialog();
        if (currentPassword == null || currentPassword.isEmpty) {
          throw Exception('Autenticación cancelada.');
        }

        AuthCredential credential = EmailAuthProvider.credential(
          email: user.email!,
          password: currentPassword,
        );
        await user.reauthenticateWithCredential(credential);
        await user.updatePassword(_passwordController.text.trim());
        successMessage += 'Contraseña actualizada. ';
      }

      if (successMessage.isEmpty) {
        successMessage = 'No se realizaron cambios.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = e.message ?? 'Ocurrió un error.';
      if (e.code == 'wrong-password') {
        errorMessage = 'Contraseña actual incorrecta. Inténtalo de nuevo.';
      } else if (e.code == 'requires-recent-login') {
        errorMessage = 'Por seguridad, debes iniciar sesión nuevamente.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
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

  // --- FUNCIÓN PARA ELIMINAR CUENTA (CORREGIDA) ---
  Future<void> _deleteAccount() async {
    final user = _currentUser;
    if (user == null) return;

    // 1. Diálogo de confirmación inicial
    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: const Text(
            '¿Eliminar cuenta?',
            style: TextStyle(color: Colors.red),
          ),
          content: const Text(
            'Esta acción NO se puede deshacer. Se eliminarán todos tus datos permanentemente.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Eliminar permanentemente'),
            ),
          ],
        );
      },
    );

    if (confirmDelete != true) return;

    setState(() => _isDeleting = true);

    try {
      // 2. Re-autenticación obligatoria antes de borrar
      final currentPassword = await _showReauthDialog(forDelete: true);
      if (currentPassword == null || currentPassword.isEmpty) {
        throw Exception('Eliminación cancelada.');
      }

      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // 3. Borrar de Firebase y cerrar sesión localmente por seguridad
      await user.delete();
      await FirebaseAuth.instance.signOut();

      // 4. Limpiar datos locales
      await widget.userBox.clear();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cuenta eliminada correctamente. Adiós.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      // Espera breve para que el usuario vea el mensaje
      await Future.delayed(const Duration(milliseconds: 1500));

      if (!mounted) return;

      // 5. ✅ NAVEGACIÓN CORRECTA AL LOGIN
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login', // ⚠️ Asegúrate de que en main.dart tu ruta se llame así
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'No se pudo eliminar la cuenta.';
      if (e.code == 'wrong-password') {
        errorMessage = 'Contraseña incorrecta.';
      } else if (e.code == 'requires-recent-login') {
        errorMessage =
            'Por seguridad, cierra sesión y vuelve a entrar para poder eliminar tu cuenta.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted && !e.toString().contains('cancelada')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Colores
    const Color primaryColor = Color.fromARGB(255, 55, 78, 107);
    const Color backgroundColor = Color.fromARGB(255, 232, 232, 232);

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 360;

    final user = _currentUser;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Editar Perfil',
          style: TextStyle(fontSize: isSmallScreen ? 18 : 20),
        ),
        backgroundColor: backgroundColor,
        elevation: 0,
        foregroundColor: primaryColor,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.all(isSmallScreen ? 16.0 : 20.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Avatar
                    Container(
                      width: isSmallScreen ? 80 : 100,
                      height: isSmallScreen ? 80 : 100,
                      decoration: BoxDecoration(
                        // ignore: deprecated_member_use
                        color: primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: primaryColor, width: 2),
                      ),
                      child: Icon(
                        Icons.person,
                        size: isSmallScreen ? 40 : 50,
                        color: primaryColor,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.03),

                    // Campo Nombre
                    TextField(
                      controller: _nameController,
                      style: TextStyle(fontSize: isSmallScreen ? 16 : 18),
                      decoration: InputDecoration(
                        labelText: 'Usuario (Nombre)',
                        labelStyle: TextStyle(
                          fontSize: isSmallScreen ? 14 : 16,
                        ),
                        border: const OutlineInputBorder(),
                        prefixIcon: Icon(
                          Icons.person_outline,
                          size: isSmallScreen ? 20 : 24,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 12 : 16,
                          vertical: isSmallScreen ? 16 : 20,
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),

                    // Campo Email (Solo lectura)
                    TextField(
                      controller: TextEditingController(text: user?.email),
                      readOnly: true,
                      style: TextStyle(fontSize: isSmallScreen ? 16 : 18),
                      decoration: InputDecoration(
                        labelText: 'Email (No editable)',
                        labelStyle: TextStyle(
                          fontSize: isSmallScreen ? 14 : 16,
                        ),
                        border: const OutlineInputBorder(),
                        prefixIcon: Icon(
                          Icons.email_outlined,
                          size: isSmallScreen ? 20 : 24,
                        ),
                        filled: true,
                        fillColor: Colors.grey[200],
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 12 : 16,
                          vertical: isSmallScreen ? 16 : 20,
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),

                    // Campo Nueva Contraseña
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      style: TextStyle(fontSize: isSmallScreen ? 16 : 18),
                      decoration: InputDecoration(
                        labelText: 'Nueva Contraseña (opcional)',
                        labelStyle: TextStyle(
                          fontSize: isSmallScreen ? 14 : 16,
                        ),
                        border: const OutlineInputBorder(),
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          size: isSmallScreen ? 20 : 24,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 12 : 16,
                          vertical: isSmallScreen ? 16 : 20,
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.03),

                    // Botón Actualizar
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _updateProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            vertical: isSmallScreen ? 14 : 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _isLoading ? 'Actualizando...' : 'Actualizar Perfil',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 16 : 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.05),

                    // Botón Eliminar Cuenta
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isDeleting ? null : _deleteAccount,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            vertical: isSmallScreen ? 14 : 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _isDeleting ? 'Eliminando...' : 'Eliminar Cuenta',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 16 : 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                  ],
                ),
              ),
            ),
          ),

          // Spinner de carga
          if (_isLoading || _isDeleting)
            Container(
              // ignore: deprecated_member_use
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _isDeleting ? Colors.red : Colors.blueAccent,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
