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
  bool _isLoading = false;
  late int _completedTasks;
  late String _userName;
  final _currentUser = FirebaseAuth.instance.currentUser;

  final List<IconData> _profileIcons = [
    Icons.person,
    Icons.face,
    Icons.star,
    Icons.favorite,
    Icons.pets,
    Icons.emoji_emotions,
    Icons.eco,
  ];
  late int _selectedIconIndex;

  final Color primaryColor = const Color.fromARGB(255, 55, 78, 107);
  final Color backgroundColor = const Color.fromARGB(255, 232, 232, 232);

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  void _loadProfileData() {
    setState(() {
      _userName = widget.userBox.get('name', defaultValue: 'Usuario');
      _completedTasks =
          widget.taskBox.values.where((t) => t.isCompleted).length;
      _selectedIconIndex =
          widget.userBox.get('profile_icon_index', defaultValue: 0);
      if (_selectedIconIndex < 0 || _selectedIconIndex >= _profileIcons.length) {
        _selectedIconIndex = 0;
      }
    });
  }

  Future<void> _showIconPickerDialog() async {
    final int? selectedIndex = await showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text('Selecciona un icono de perfil'),
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Wrap(
                spacing: 20.0,
                runSpacing: 20.0,
                alignment: WrapAlignment.center,
                children: List<Widget>.generate(_profileIcons.length, (index) {
                  return InkWell(
                    onTap: () {
                      Navigator.pop(context, index);
                    },
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor: _selectedIconIndex == index
                          ? primaryColor.withAlpha(102)
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

    if (selectedIndex != null && selectedIndex != _selectedIconIndex) {
      await widget.userBox.put('profile_icon_index', selectedIndex);
      setState(() {
        _selectedIconIndex = selectedIndex;
      });
    }
  }

  Future<void> _deleteAccount() async {
    if (_currentUser == null) return;

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

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.taskBox.deleteFromDisk();
      await _currentUser.delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cuenta eliminada correctamente.'),
            backgroundColor: Colors.green,
          ),
        );
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return;
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Error: ${e.message}';
      if (e.code == 'requires-recent-login') {
        message =
            'Por seguridad, vuelve a iniciar sesión e inténtalo de nuevo.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
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

  // 🔹 NUEVO: función para abrir directamente la edición del perfil
  void _goToEditProfile() async {
    final bool? didUpdate = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(userBox: widget.userBox),
      ),
    );
    if (didUpdate == true) {
      _loadProfileData();
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
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: _showIconPickerDialog,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: primaryColor.withAlpha(127),
                      child: Icon(
                        _profileIcons[_selectedIconIndex],
                        size: 60,
                        color: primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
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

                  // 👇 Ahora el campo de Usuario es clickeable
                  GestureDetector(
                    onTap: _goToEditProfile,
                    child: _buildProfileInfoTile(
                      icon: Icons.person_outline,
                      title: 'Usuario (Nombre)',
                      subtitle: _userName,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildProfileInfoTile(
                    icon: Icons.email_outlined,
                    title: 'Email',
                    subtitle: _currentUser?.email ?? '...',
                  ),
                  const SizedBox(height: 40),

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
          if (_isLoading)
            Container(
              color: Colors.black.withAlpha(127),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

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
