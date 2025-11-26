// ignore_for_file: unused_element, use_build_context_synchronously
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart'; // 1. IMPORTANTE: Paquete SVG
import 'package:hive/hive.dart';
import '../models/task.dart';

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
  // Controladores
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _newPasswordController;

  // Visibilidad de contraseñas
  bool _obscureNewPassword = true;

  final _currentUser = FirebaseAuth.instance.currentUser;
  // --- COLORES Y ESTILOS ---
  final Color primaryColor = const Color.fromARGB(255, 55, 78, 107);
  final Color backgroundColor = const Color.fromARGB(255, 232, 232, 232);
  // Definimos colores para los textos del diálogo si no existen globalmente
  final Color darkTextColor = const Color(0xFF2D3142);
  final Color textColor = const Color(0xFF9C9C9C);

  // --- LISTA DE ICONOS ---

  final List<Map<String, dynamic>> _profileIcons = [
    {'icon': Icons.person, 'name': 'Persona', 'color': Colors.blue},
    {'icon': Icons.face, 'name': 'Cara', 'color': Colors.orange},
    {'icon': Icons.star, 'name': 'Estrella', 'color': Colors.yellow},
    {'icon': Icons.favorite, 'name': 'Corazón', 'color': Colors.red},
    {'icon': Icons.pets, 'name': 'Mascota', 'color': Colors.brown},
    {'icon': Icons.emoji_emotions, 'name': 'Emoji', 'color': Colors.amber},
    {'icon': Icons.eco, 'name': 'Naturaleza', 'color': Colors.green},
    {'icon': Icons.sports_soccer, 'name': 'Fútbol', 'color': Colors.green},
    {
      'icon': Icons.sports_basketball,
      'name': 'Baloncesto',
      'color': Colors.orange,
    },
    {'icon': Icons.sports_baseball, 'name': 'Béisbol', 'color': Colors.red},
    {'icon': Icons.sports_tennis, 'name': 'Tenis', 'color': Colors.yellow},
    {
      'icon': Icons.sports_esports,
      'name': 'Videojuegos',
      'color': Colors.purple,
    },
    {'icon': Icons.music_note, 'name': 'Música', 'color': Colors.pink},
    {'icon': Icons.movie, 'name': 'Cine', 'color': Colors.indigo},
    {'icon': Icons.book, 'name': 'Libros', 'color': Colors.brown},
    {'icon': Icons.computer, 'name': 'Tecnología', 'color': Colors.blueGrey},
    {'icon': Icons.restaurant, 'name': 'Comida', 'color': Colors.orange},
    {'icon': Icons.local_cafe, 'name': 'Café', 'color': Colors.brown},
    {'icon': Icons.directions_car, 'name': 'Auto', 'color': Colors.red},
    {'icon': Icons.flight, 'name': 'Viajes', 'color': Colors.blue},
    {'icon': Icons.work, 'name': 'Trabajo', 'color': Colors.grey},
    {'icon': Icons.school, 'name': 'Estudio', 'color': Colors.deepPurple},
    {'icon': Icons.health_and_safety, 'name': 'Salud', 'color': Colors.green},
    {'icon': Icons.architecture, 'name': 'Arte', 'color': Colors.pink},
    {
      'icon': Icons.nightlight_round,
      'name': 'Noche',
      'color': Colors.deepPurple,
    },
  ];

  late int _selectedIconIndex;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _newPasswordController = TextEditingController();

    _loadProfileData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _newPasswordController.dispose();

    super.dispose();
  }

  void _loadProfileData() {
    final name = widget.userBox.get('name', defaultValue: 'Usuario');
    _nameController.text = name;
    _emailController.text = _currentUser?.email ?? '';

    setState(() {
      _completedTasks = widget.taskBox.values
          .where((t) => t.isCompleted)
          .length;
      _selectedIconIndex = widget.userBox.get(
        'profile_icon_index',
        defaultValue: 0,
      );

      if (_selectedIconIndex < 0 ||
          _selectedIconIndex >= _profileIcons.length) {
        _selectedIconIndex = 0;
      }
    });
  }

  // --- VALIDACIÓN DE CONTRASEÑA ---

  String? _validateNewPassword(String password) {
    if (password.isEmpty) return null;
    if (password.length < 8) return 'Mínimo 8 caracteres.';
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'Debe tener al menos 1 mayúscula.';
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'Debe tener al menos 1 número.';
    }
    return null;
  }

  // ==========================================

  //     NUEVAS ALERTAS PERSONALIZADAS (SVG)

  // ==========================================

  // 1. Alerta Informativa / Éxito (Con o sin Auto-cierre)

  Future<void> _showCustomInfoDialog({
    required String title,
    required String subtitle,
    String assetName = 'assets/alegre.svg',
    bool autoClose = false,
    Color? titleColor,
  }) async {
    await showDialog(
      context: context,

      barrierDismissible: !autoClose,

      builder: (dialogContext) {
        if (autoClose) {
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted && Navigator.canPop(dialogContext)) {
              Navigator.pop(dialogContext);
            }
          });
        }

        return Dialog(
          backgroundColor: Colors.white,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),

          child: Padding(
            padding: const EdgeInsets.all(25.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  assetName,
                  height: 100,
                  placeholderBuilder: (context) =>
                      const Icon(Icons.info, size: 80, color: Colors.blue),
                ),

                const SizedBox(height: 20),

                Text(
                  title,

                  style: TextStyle(
                    color: titleColor ?? darkTextColor,

                    fontSize: 20,

                    fontWeight: FontWeight.w900,
                  ),

                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 10),

                Text(
                  subtitle,

                  style: TextStyle(color: textColor, fontSize: 16),

                  textAlign: TextAlign.center,
                ),

                if (!autoClose) ...[
                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: () => Navigator.pop(dialogContext),

                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,

                      foregroundColor: Colors.white,

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),

                    child: const Text('Aceptar'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // 2. Alerta de Confirmación (Si / No)

  Future<bool?> _showCustomConfirmationDialog({
    required String title,

    required String subtitle,

    String assetName =
        'assets/triste.svg', // Puedes cambiar por una imagen de duda/alerta
  }) async {
    return showDialog<bool>(
      context: context,

      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),

          child: Padding(
            padding: const EdgeInsets.all(25.0),

            child: Column(
              mainAxisSize: MainAxisSize.min,

              children: [
                SvgPicture.asset(
                  assetName,

                  height: 100,

                  placeholderBuilder: (context) => const Icon(
                    Icons.help_outline,

                    size: 80,

                    color: Colors.orange,
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  title,

                  style: TextStyle(
                    color: darkTextColor,

                    fontSize: 20,

                    fontWeight: FontWeight.w900,
                  ),

                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 10),

                Text(
                  subtitle,

                  style: TextStyle(color: textColor, fontSize: 16),

                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,

                  children: [
                    TextButton(
                      onPressed: () =>
                          Navigator.pop(dialogContext, false), // NO

                      child: const Text(
                        'No',

                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),

                    ElevatedButton(
                      onPressed: () => Navigator.pop(dialogContext, true), // SI

                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,

                        foregroundColor: Colors.white,

                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),

                      child: const Text('Sí, eliminar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 3. Alerta con Input (Para pedir contraseña)

  Future<String?> _showCustomPasswordPrompt({
    required String title,

    required String subtitle,
  }) async {
    String? password;

    await showDialog(
      context: context,

      barrierDismissible: false,

      builder: (context) {
        final passCtrl = TextEditingController();

        bool obscure = true;

        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.white,

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),

              child: Padding(
                padding: const EdgeInsets.all(25.0),

                child: Column(
                  mainAxisSize: MainAxisSize.min,

                  children: [
                    // Puedes usar otro icono aquí, ej: candado
                    SvgPicture.asset(
                      'assets/tushe.svg',

                      height: 80,

                      placeholderBuilder: (context) =>
                          const Icon(Icons.lock, size: 60, color: Colors.blue),
                    ),

                    const SizedBox(height: 15),

                    Text(
                      title,

                      style: TextStyle(
                        color: darkTextColor,

                        fontSize: 18,

                        fontWeight: FontWeight.w900,
                      ),

                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 5),

                    Text(
                      subtitle,

                      style: TextStyle(color: textColor, fontSize: 14),

                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 15),

                    TextField(
                      controller: passCtrl,

                      obscureText: obscure,

                      decoration: InputDecoration(
                        labelText: 'Contraseña',

                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),

                        suffixIcon: IconButton(
                          icon: Icon(
                            obscure ? Icons.visibility_off : Icons.visibility,
                          ),

                          onPressed: () => setState(() => obscure = !obscure),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,

                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),

                          child: const Text('Cancelar'),
                        ),

                        const SizedBox(width: 10),

                        ElevatedButton(
                          onPressed: () {
                            password = passCtrl.text;

                            Navigator.pop(context);
                          },

                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,

                            foregroundColor: Colors.white,

                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),

                          child: const Text('Confirmar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    return password;
  }

  // --- LÓGICA DE ACTUALIZACIÓN MODIFICADA ---

  Future<void> _updateProfile() async {
    if (_nameController.text.trim().isEmpty) {
      _showCustomInfoDialog(
        title: "Error",

        subtitle: "El nombre no puede estar vacío",

        titleColor: Colors.red,
      );

      return;
    }

    String newPass = _newPasswordController.text.trim();

    // Validar contraseña

    if (newPass.isNotEmpty) {
      String? error = _validateNewPassword(newPass);

      if (error != null) {
        _showCustomInfoDialog(
          title: "Contraseña inválida",

          subtitle: error,

          titleColor: Colors.red,
        );

        return;
      }
    }

    UserCredential? credential;

    // Si cambia contraseña, pedir la actual con el nuevo diseño

    if (newPass.isNotEmpty &&
        _currentUser != null &&
        _currentUser.email != null) {
      final currentPass = await _showCustomPasswordPrompt(
        title: 'Seguridad',

        subtitle: 'Escriba su contraseña actual para confirmar los cambios.',
      );

      if (currentPass == null) return; // Canceló

      if (currentPass == newPass) {
        _showCustomInfoDialog(
          title: "Error",

          subtitle: "La nueva contraseña no puede ser igual a la actual.",

          titleColor: Colors.red,
        );

        return;
      }

      setState(() => _isLoading = true);

      try {
        AuthCredential cred = EmailAuthProvider.credential(
          email: _currentUser.email!,

          password: currentPass,
        );

        credential = await _currentUser.reauthenticateWithCredential(cred);
      } catch (e) {
        setState(() => _isLoading = false);

        _showCustomInfoDialog(
          title: "Error de autenticación",

          subtitle: "La contraseña actual es incorrecta.",

          titleColor: Colors.red,
        );

        return;
      }
    } else {
      setState(() => _isLoading = true);
    }

    try {
      await widget.userBox.put('name', _nameController.text.trim());

      await widget.userBox.put('profile_icon_index', _selectedIconIndex);

      if (_currentUser != null) {
        await _currentUser.updateDisplayName(_nameController.text.trim());

        if (newPass.isNotEmpty && credential != null) {
          await _currentUser.updatePassword(newPass);

          _newPasswordController.clear();

          // ALERTA: CONTRASEÑA ACTUALIZADA (Auto cierre opcional)

          if (mounted) {
            await _showCustomInfoDialog(
              title: "¡Éxito!",

              subtitle: "Contraseña actualizada correctamente.",

              autoClose: true,
            );
          }
        } else {
          // ALERTA: USUARIO ACTUALIZADO (Auto cierre opcional)

          if (mounted) {
            await _showCustomInfoDialog(
              title: "¡Éxito!",

              subtitle: "Usuario actualizado correctamente.",

              autoClose: true,
            );
          }
        }
      }
    } catch (e) {
      _showCustomInfoDialog(
        title: "Error",

        subtitle: "No se pudo actualizar: $e",

        titleColor: Colors.red,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- LÓGICA DE ELIMINACIÓN MODIFICADA ---

  Future<void> _deleteAccountProcess() async {
    if (_currentUser == null || _currentUser.email == null) return;

    // 1. ALERTA PERSONALIZADA: ¿Desea eliminar?

    final bool? desireToDelete = await _showCustomConfirmationDialog(
      title: "¿Desea eliminar cuenta?",

      subtitle: "Esta acción es irreversible y perderás tus datos.",
    );

    // SI DICE QUE NO

    if (desireToDelete != true) {
      if (mounted) {
        _showCustomInfoDialog(
          title: "¡Gracias!",

          subtitle: "Gracias por quedarte con nosotros.",

          autoClose: true, // Se cierra sola en 2 seg
        );
      }

      return;
    }

    // 2. SI DICE QUE SI: Pedir contraseña

    final currentPass = await _showCustomPasswordPrompt(
      title: 'Confirmar eliminación',

      subtitle:
          'Escriba su contraseña actual para borrar la cuenta definitivamente.',
    );

    if (currentPass == null || currentPass.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      AuthCredential cred = EmailAuthProvider.credential(
        email: _currentUser.email!,

        password: currentPass,
      );

      await _currentUser.reauthenticateWithCredential(cred);

      await widget.taskBox.deleteFromDisk();

      await _currentUser.delete();

      if (mounted) {
        // ALERTA FINAL: CUENTA ELIMINADA

        await _showCustomInfoDialog(
          title: "Cuenta eliminada",

          subtitle: "Tu cuenta ha sido borrada correctamente.",

          autoClose: true, // 2 segundos y se va
        );

        // Ya el dialogo de arriba hace el delay, navegamos al salir

        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        _showCustomInfoDialog(
          title: "Error",

          subtitle: "Contraseña errónea, intente de nuevo.",

          titleColor: Colors.red,
        );
      } else {
        _showCustomInfoDialog(
          title: "Error",

          subtitle: e.message ?? "Error desconocido",

          titleColor: Colors.red,
        );
      }
    } catch (e) {
      _showCustomInfoDialog(
        title: "Salir",

        subtitle: "Para salir regrese con la flecha.",

        titleColor: Colors.red,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- UI BUILD ---

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    final screenHeight = MediaQuery.of(context).size.height;

    final isSmallScreen = screenWidth < 360;

    return Scaffold(
      backgroundColor: backgroundColor,

      appBar: AppBar(
        title: const Text(
          'Perfil',

          style: TextStyle(fontWeight: FontWeight.bold),
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
                constraints: const BoxConstraints(maxWidth: 500),

                child: Column(
                  children: [
                    // AVATAR
                    GestureDetector(
                      onTap: _showIconPickerDialog,

                      child: Container(
                        width: _getAvatarSize(screenWidth),

                        height: _getAvatarSize(screenWidth),

                        decoration: BoxDecoration(
                          color: _profileIcons[_selectedIconIndex]['color']
                              .withOpacity(0.2),

                          shape: BoxShape.circle,

                          border: Border.all(
                            color: _profileIcons[_selectedIconIndex]['color'],

                            width: 3,
                          ),
                        ),

                        child: Icon(
                          _profileIcons[_selectedIconIndex]['icon'],

                          size: _getAvatarIconSize(screenWidth),

                          color: _profileIcons[_selectedIconIndex]['color'],
                        ),
                      ),
                    ),

                    TextButton(
                      onPressed: _showIconPickerDialog,

                      child: Text(
                        "Cambiar icono",

                        style: TextStyle(color: primaryColor),
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.02),

                    // STATS
                    Text(
                      '$_completedTasks',

                      style: TextStyle(
                        fontSize: isSmallScreen ? 32 : 36,

                        fontWeight: FontWeight.bold,

                        color: primaryColor,
                      ),
                    ),

                    const Text(
                      'tareas completadas',

                      style: TextStyle(
                        color: Colors.black54,

                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.04),

                    // FORMULARIO
                    _buildLabelAndField(
                      label: "Nombre de Usuario",

                      controller: _nameController,

                      icon: Icons.person_outline,
                    ),

                    SizedBox(height: screenHeight * 0.02),

                    _buildLabelAndField(
                      label: "Correo Electrónico",

                      controller: _emailController,

                      icon: Icons.email_outlined,

                      isReadOnly: true,
                    ),

                    SizedBox(height: screenHeight * 0.02),

                    _buildLabelAndField(
                      label: "Nueva Contraseña (Opcional)",

                      controller: _newPasswordController,

                      icon: Icons.lock_outline,

                      isPassword: true,

                      isObscured: _obscureNewPassword,

                      onToggleVisibility: () => setState(
                        () => _obscureNewPassword = !_obscureNewPassword,
                      ),
                    ),

                    if (_newPasswordController.text.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0, left: 4.0),

                        child: Text(
                          'Reglas: Mín 8 caracteres, 1 Mayúscula, 1 Número.',

                          style: TextStyle(
                            fontSize: 12,

                            color: Colors.grey[600],
                          ),
                        ),
                      ),

                    SizedBox(height: screenHeight * 0.04),

                    // BOTONES
                    SizedBox(
                      width: double.infinity,

                      child: ElevatedButton(
                        onPressed: _updateProfile,

                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,

                          foregroundColor: Colors.white,

                          padding: const EdgeInsets.symmetric(vertical: 16),

                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),

                        child: const Text(
                          'ACTUALIZAR DATOS',

                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.02),

                    SizedBox(
                      width: double.infinity,

                      child: TextButton(
                        onPressed: _deleteAccountProcess,

                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,

                          padding: const EdgeInsets.symmetric(vertical: 16),

                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),

                            side: const BorderSide(color: Colors.red, width: 1),
                          ),
                        ),

                        child: const Text(
                          'ELIMINAR CUENTA',

                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),

          if (_isLoading)
            Container(
              color: Colors.black.withAlpha(127),

              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  // --- HELPERS VISUALES ---

  Widget _buildLabelAndField({
    required String label,

    required TextEditingController controller,

    required IconData icon,

    bool isReadOnly = false,

    bool isPassword = false,

    bool isObscured = false,

    VoidCallback? onToggleVisibility,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),

          child: Text(
            label,

            style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
          ),
        ),

        Container(
          decoration: BoxDecoration(
            color: Colors.white,

            borderRadius: BorderRadius.circular(12),

            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),

                blurRadius: 5,

                offset: const Offset(0, 2),
              ),
            ],
          ),

          child: TextField(
            controller: controller,

            readOnly: isReadOnly,

            obscureText: isPassword ? isObscured : false,

            onChanged: isPassword ? (val) => setState(() {}) : null,

            style: TextStyle(
              color: isReadOnly ? Colors.grey[600] : Colors.black87,
            ),

            decoration: InputDecoration(
              prefixIcon: Icon(
                icon,

                color: isReadOnly ? Colors.grey : primaryColor,
              ),

              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        isObscured ? Icons.visibility_off : Icons.visibility,

                        color: Colors.grey,
                      ),

                      onPressed: onToggleVisibility,
                    )
                  : null,

              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),

                borderSide: BorderSide.none,
              ),

              filled: true,

              fillColor: isReadOnly ? Colors.grey[100] : Colors.white,

              hintText: isPassword ? 'Escribe nueva contraseña' : null,

              contentPadding: const EdgeInsets.symmetric(
                vertical: 16,

                horizontal: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showIconPickerDialog() async {
    final screenWidth = MediaQuery.of(context).size.width;

    final int? selectedIndex = await showDialog<int>(
      context: context,

      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),

          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: screenWidth * 0.9,

              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),

            child: Padding(
              padding: const EdgeInsets.all(16),

              child: Column(
                children: [
                  Text(
                    'Elige tu avatar',

                    style: TextStyle(
                      fontSize: 20,

                      fontWeight: FontWeight.bold,

                      color: primaryColor,
                    ),
                  ),

                  const SizedBox(height: 16),

                  Expanded(
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,

                            crossAxisSpacing: 10,

                            mainAxisSpacing: 10,

                            childAspectRatio: 0.9,
                          ),

                      itemCount: _profileIcons.length,

                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () => Navigator.pop(context, index),

                          child: Container(
                            decoration: BoxDecoration(
                              color: _selectedIconIndex == index
                                  ? _profileIcons[index]['color'].withOpacity(
                                      0.2,
                                    )
                                  : Colors.grey[100],

                              borderRadius: BorderRadius.circular(12),

                              border: Border.all(
                                color: _selectedIconIndex == index
                                    ? _profileIcons[index]['color']
                                    : Colors.transparent,

                                width: 2,
                              ),
                            ),

                            child: Icon(
                              _profileIcons[index]['icon'],

                              color: _profileIcons[index]['color'],

                              size: 30,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (selectedIndex != null)
      setState(() => _selectedIconIndex = selectedIndex);
  }

  double _getAvatarSize(double w) =>
      w < 340 ? 100 : (w < 400 ? 120 : (w < 500 ? 140 : 160));

  double _getAvatarIconSize(double w) =>
      w < 340 ? 45 : (w < 400 ? 55 : (w < 500 ? 65 : 75));
}
