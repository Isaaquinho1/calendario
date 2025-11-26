import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/task.dart';
import 'add_task_screen.dart';
import 'edit_task_screen.dart';
import 'profile_screen.dart';
import 'package:intl/intl.dart'; // Import intl para formatear

// Enum para el filtro de estado
enum Filter { pending, completed }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Box _userBox = Hive.box('userBox');
  late Box<Task> _taskBox;

  // Variables de estado
  late String _userName;
  Filter _activeFilter = Filter.pending;
  String? _selectedCategory;

  Future<void>? _initBoxesFuture;

  @override
  void initState() {
    super.initState();
    _initBoxesFuture = _initializeData();
  }

  Future<void> _initializeData() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception("No hay ningún usuario logueado.");
    }

    final String uid = currentUser.uid;
    final String userTaskBoxName = 'tasks_$uid';

    // Abrimos la caja de tareas específica del usuario
    _taskBox = await Hive.openBox<Task>(userTaskBoxName);

    final lastEmail = _userBox.get('last_email');
    final currentEmail = currentUser.email;

    if (currentEmail != null && currentEmail != lastEmail) {
      _userBox.delete('name');
      _userBox.delete('birthdate');
      _userBox.put('last_email', currentEmail);
      _userName = 'Usuario';
    } else {
      _userName = _userBox.get('name', defaultValue: 'Usuario') as String;
    }
  }

  void _toggleTaskCompletion(dynamic key) {
    final Task taskToUpdate = _taskBox.get(key)!;
    taskToUpdate.isCompleted = !taskToUpdate.isCompleted;
    _taskBox.put(key, taskToUpdate);
  }

  void _deleteTask(dynamic key, Task deletedTask) {
    _taskBox.delete(key);
  }

  void _editTask(dynamic key, Task task) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            EditTaskScreen(task: task, taskIndex: 0, taskKey: key),
      ),
    );

    if (!mounted) return;

    if (result is Map) {
      final updatedTask = result['task'] as Task;
      final taskKey = result['key'];
      if (taskKey != null) {
        _taskBox.put(taskKey, updatedTask);
      }
    }
  }

  String getPersonalizedGreeting() {
    final List<String> greetings = [
      '¡Hola, $_userName! 👋 ¿Listo para conquistar el día?',
      '¡Excelente, $_userName! Vamos por esas metas. 🚀',
      'A trabajar, $_userName. ¡Hoy es tu día! 💪',
      '¡Que gusto verte, $_userName! Tienes tareas importantes. 😉',
      '¡El tiempo es oro, $_userName! A darle con todo. ⏰',
    ];
    return greetings[DateTime.now().hour % greetings.length];
  }

  Set<String> _getCategories(List<Task> tasks) {
    final Set<String> categories = {};
    bool hasUncategorized = false;
    for (final task in tasks) {
      String? taskCategory;
      if (task.note.startsWith('Categoría: ')) {
        taskCategory = task.note
            .split('\n')
            .first
            .replaceFirst('Categoría: ', '')
            .trim();
      }
      if (taskCategory != null && taskCategory.isNotEmpty) {
        categories.add(taskCategory);
      } else {
        hasUncategorized = true;
      }
    }
    if (hasUncategorized) categories.add('Otros');
    return categories;
  }

  Widget _buildProfileMenu(BuildContext context, Color iconColor) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final String name = _userName;
    final String email = currentUser?.email ?? 'Sin Email';

    return PopupMenuButton<String>(
      icon: Icon(Icons.menu, color: iconColor),
      onSelected: (value) async {
        final navigator = Navigator.of(context);

        if (value == 'profile') {
          final bool? profileWasUpdated = await navigator.push<bool>(
            MaterialPageRoute(
              builder: (_) =>
                  ProfileScreen(userBox: _userBox, taskBox: _taskBox),
            ),
          );

          if (!mounted) return;

          if (profileWasUpdated == true) {
            setState(() {
              _userName = _userBox.get('name', defaultValue: 'Usuario');
            });
          }
        } else if (value == 'logout') {
          if (!mounted) return;

          final messenger = ScaffoldMessenger.of(context);

          messenger.showSnackBar(
            SnackBar(
              content: Text("¡Nos vemos luego, $_userName!"),
              backgroundColor: Colors.blueAccent,
            ),
          );

          await Future.delayed(const Duration(milliseconds: 1500));
          await FirebaseAuth.instance.signOut();

          await _taskBox.close(); // Cierra la caja de tareas del usuario

          if (!mounted) return;

          navigator.pushNamedAndRemoveUntil('/login', (route) => false);
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 0, 0, 0),
                ),
              ),
              Text(
                email,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color.fromARGB(255, 33, 33, 33),
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'profile',
          child: Row(
            children: [
              Icon(Icons.person_outline),
              SizedBox(width: 10),
              Text('Perfil'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, color: Colors.red),
              SizedBox(width: 10),
              Text('Cerrar Sesión'),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Colores del tema
    const Color primaryColor = Color.fromARGB(255, 55, 78, 107);
    const Color backgroundColor = Color.fromARGB(255, 232, 232, 232);
    const Color cardColor = Color.fromARGB(255, 212, 212, 212);
    const Color textColor = Color.fromARGB(255, 59, 59, 59);
    const Color secondaryTextColor = Color.fromARGB(255, 55, 78, 107);
    const Color fabColor = Colors.blueAccent;

    // Detección de tamaño de pantalla
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 360;
    final isLargeScreen = screenWidth > 400;

    return FutureBuilder<void>(
      future: _initBoxesFuture,
      builder: (context, snapshot) {
        // Estado de carga
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: backgroundColor,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Estado de error
        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: backgroundColor,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  "Error al cargar datos: ${snapshot.error}. Intenta reiniciar la app.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    color: textColor,
                  ),
                ),
              ),
            ),
          );
        }

        // Estado de éxito
        return ValueListenableBuilder(
          valueListenable: _taskBox.listenable(),
          builder: (context, Box<Task> box, _) {
            // Calcular estado
            final Map<dynamic, Task> taskMap = box.toMap();
            final List<Task> allTasks = taskMap.values.toList();
            final bool isTotalyEmpty = allTasks.isEmpty;

            final List<Task> pendingTasks = allTasks
                .where((t) => !t.isCompleted)
                .toList();
            final List<Task> completedTasks = allTasks
                .where((t) => t.isCompleted)
                .toList();
            final completedCount = completedTasks.length;
            final upcomingCount = pendingTasks.length;

            final List<Task> listForCurrentFilter =
                (_activeFilter == Filter.pending)
                ? pendingTasks
                : completedTasks;
            final Set<String> categoriesForCurrentFilter = _getCategories(
              listForCurrentFilter,
            );

            final Map<dynamic, Task> filteredMap = Map.fromEntries(
              taskMap.entries.where((entry) {
                final task = entry.value;
                bool passesToggleFilter = (_activeFilter == Filter.pending)
                    ? !task.isCompleted
                    : task.isCompleted;
                if (!passesToggleFilter) return false;

                if (_selectedCategory == null) return true;
                String? taskCategory;
                if (task.note.startsWith('Categoría: ')) {
                  taskCategory = task.note
                      .split('\n')
                      .first
                      .replaceFirst('Categoría: ', '')
                      .trim();
                }
                if (_selectedCategory == 'Otros') {
                  return taskCategory == null || taskCategory.isEmpty;
                }
                return taskCategory == _selectedCategory;
              }),
            );

            final bool isFilteredListEmpty = filteredMap.isEmpty;
            final List<Task> tasksToDisplay = filteredMap.values.toList();
            final List<dynamic> keysToDisplay = filteredMap.keys.toList();

            return Scaffold(
              backgroundColor: backgroundColor,
              appBar: AppBar(
                backgroundColor: backgroundColor,
                elevation: 0,
                leading: (isTotalyEmpty || isFilteredListEmpty)
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: EdgeInsets.all(isSmallScreen ? 4.0 : 8.0),
                        // child: _buildRemyLogo(isSmallScreen, screenHeight),
                      ),
                actions: [_buildProfileMenu(context, primaryColor)],
              ),
              floatingActionButton: SizedBox(
                width: isSmallScreen ? 60.0 : 70.0,
                height: isSmallScreen ? 60.0 : 70.0,
                child: FloatingActionButton(
                  onPressed: () async {
                    // add_task_screen se encarga de añadir a Hive
                    // y nos devuelve la tarea (por si la necesitamos)
                    // El ValueListenableBuilder se encargará de actualizar la UI
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddTaskScreen(),
                      ),
                    );
                    // El código de "if (newTask is Task)" se elimina
                    // porque AddTaskScreen ya lo guarda en la caja correcta.
                  },
                  backgroundColor: fabColor,
                  foregroundColor: Colors.white,
                  shape: const CircleBorder(),
                  child: Icon(Icons.add, size: isSmallScreen ? 30 : 35),
                ),
              ),
              floatingActionButtonLocation:
                  FloatingActionButtonLocation.startFloat,
              body: SafeArea(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 16.0 : 20.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // Saludo
                      Text(
                        getPersonalizedGreeting(),
                        style: TextStyle(
                          fontSize: isSmallScreen
                              ? 20
                              : isLargeScreen
                              ? 26
                              : 24,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.01),

                      // Fecha
                      Text(
                        // Usamos DateFormat para una fecha más legible
                        DateFormat(
                          'EEEE, dd MMMM, yyyy',
                          'es_ES',
                        ).format(DateTime.now()),
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 16,
                          color: secondaryTextColor,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.03),

                      // Tarjetas de métricas
                      _buildMetricCards(
                        context,
                        primaryColor,
                        cardColor,
                        textColor,
                        upcomingCount,
                        completedCount,
                        isSmallScreen: isSmallScreen,
                      ),
                      SizedBox(height: screenHeight * 0.03),

                      // Título "Mis Tareas"
                      Text(
                        'Mis Tareas',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 18 : 20,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.02),

                      // Filtros de categoría
                      _buildCategoryFilters(
                        categoriesForCurrentFilter,
                        primaryColor,
                        isSmallScreen: isSmallScreen,
                      ),
                      SizedBox(height: screenHeight * 0.02),

                      // Lista de tareas
                      Expanded(
                        child: (isTotalyEmpty || isFilteredListEmpty)
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildEmptyStateLogo(
                                      isSmallScreen,
                                      screenHeight,
                                    ),
                                    SizedBox(height: screenHeight * 0.02),
                                    Text(
                                      isTotalyEmpty
                                          ? '¡Parece que no tienes tareas! \nPresiona "+" para empezar a conquistar el día.'
                                          : '¡Nada por aquí! \nNo hay tareas en esta vista.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 16 : 18,
                                        color: secondaryTextColor,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                itemCount: tasksToDisplay.length,
                                itemBuilder: (context, index) {
                                  final task = tasksToDisplay[index];
                                  final key = keysToDisplay[index];
                                  return TaskCard(
                                    task: task,
                                    onToggle: () => _toggleTaskCompletion(key),
                                    onDelete: () => _deleteTask(key, task),
                                    onEdit: () => _editTask(key, task),
                                    cardColor: cardColor,
                                    primaryColor: primaryColor,
                                    isSmallScreen: isSmallScreen,
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
      },
    );
  }

  // --- WIDGETS AUXILIARES RESPONSIVOS ---

  // Widget para el logo en estado vacío
  Widget _buildEmptyStateLogo(bool isSmallScreen, double screenHeight) {
    try {
      return SvgPicture.asset(
        'assets/curioso.svg', // ⬅️ Revisa que esta ruta sea correcta
        height: screenHeight * 0.2,
        fit: BoxFit.contain,
        placeholderBuilder: (BuildContext context) => Container(
          width: screenHeight * 0.2,
          height: screenHeight * 0.2,
          decoration: BoxDecoration(
            // ignore: deprecated_member_use
            color: const Color.fromARGB(255, 55, 78, 107).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.task_alt,
            size: screenHeight * 0.1,
            color: const Color.fromARGB(255, 55, 78, 107),
          ),
        ),
      );
    } catch (e) {
      return Container(
        width: screenHeight * 0.2,
        height: screenHeight * 0.2,
        decoration: BoxDecoration(
          // ignore: deprecated_member_use
          color: const Color.fromARGB(255, 55, 78, 107).withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color.fromARGB(255, 55, 78, 107),
            width: 2,
          ),
        ),
        child: Icon(
          Icons.task_alt,
          size: screenHeight * 0.1,
          color: const Color.fromARGB(255, 55, 78, 107),
        ),
      );
    }
  }

  Widget _buildMetricCards(
    BuildContext context,
    Color primaryColor,
    Color cardColor,
    Color textColor,
    int upcomingCount,
    int completedCount, {
    required bool isSmallScreen,
  }) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() {
              _activeFilter = Filter.completed;
              _selectedCategory = null;
            }),
            child: _buildMetricCard(
              context,
              'Completas',
              completedCount.toString(),
              primaryColor,
              cardColor,
              textColor,
              _activeFilter == Filter.completed,
              isSmallScreen: isSmallScreen,
            ),
          ),
        ),
        SizedBox(width: isSmallScreen ? 12 : 15),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() {
              _activeFilter = Filter.pending;
              _selectedCategory = null;
            }),
            child: _buildMetricCard(
              context,
              'Pendientes',
              upcomingCount.toString(),
              primaryColor,
              cardColor,
              textColor,
              _activeFilter == Filter.pending,
              isSmallScreen: isSmallScreen,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String title,
    String count,
    Color primaryColor,
    Color cardColor,
    Color textColor,
    bool isSelected, {
    required bool isSmallScreen,
  }) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15),
        border: isSelected ? Border.all(color: primaryColor, width: 2.5) : null,
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: primaryColor.withAlpha(102),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.w600,
              fontSize: isSmallScreen ? 14 : 16,
            ),
          ),
          SizedBox(height: isSmallScreen ? 8 : 10),
          Text(
            count,
            style: TextStyle(
              color: textColor,
              fontSize: isSmallScreen ? 36 : 48,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilters(
    Set<String> categories,
    Color primaryColor, {
    required bool isSmallScreen,
  }) {
    List<String> sortedCategories =
        categories.where((c) => c != 'Otros').toList()..sort();
    if (categories.contains('Otros')) {
      sortedCategories.add('Otros');
    }
    if (sortedCategories.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ChoiceChip(
            label: Text(
              'Todos',
              style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
            ),
            selected: _selectedCategory == null,
            onSelected: (selected) {
              if (selected) setState(() => _selectedCategory = null);
            },
            selectedColor: primaryColor,
            labelStyle: TextStyle(
              color: _selectedCategory == null ? Colors.white : primaryColor,
            ),
            backgroundColor: Colors.white.withAlpha(178),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            showCheckmark: false,
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 10 : 12,
              vertical: isSmallScreen ? 6 : 8,
            ),
          ),
          SizedBox(width: isSmallScreen ? 6 : 8),
          ...sortedCategories.map((category) {
            return Padding(
              padding: EdgeInsets.only(right: isSmallScreen ? 6.0 : 8.0),
              child: ChoiceChip(
                label: Text(
                  category,
                  style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                ),
                selected: _selectedCategory == category,
                onSelected: (selected) {
                  if (selected) setState(() => _selectedCategory = category);
                },
                selectedColor: primaryColor,
                labelStyle: TextStyle(
                  color: _selectedCategory == category
                      ? Colors.white
                      : primaryColor,
                ),
                backgroundColor: Colors.white.withAlpha(178),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                showCheckmark: false,
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 10 : 12,
                  vertical: isSmallScreen ? 6 : 8,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------
// WIDGET TASKCARD RESPONSIVO (CORREGIDO)
// ------------------------------------------------------------------

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final Color cardColor;
  final Color primaryColor;
  final bool isSmallScreen;

  const TaskCard({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
    required this.cardColor,
    required this.primaryColor,
    this.isSmallScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    const Color textColor = Color.fromARGB(255, 0, 0, 0);
    const Color secondaryTextColor = Color.fromARGB(255, 0, 0, 0);

    // Determinar el color de la barra lateral (¡función de ejemplo!)
    // Asumiendo que Task tiene un campo 'color'
    final Color sideBarColor = task.isCompleted ? Colors.grey : (task.color);

    return Dismissible(
      key: UniqueKey(), // Usa UniqueKey si la lista puede cambiar dinámicamente
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        onDelete();
      },
      background: Container(
        color: Colors.red.shade700,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12.0),
        decoration: BoxDecoration(
          color: task.isCompleted ? cardColor.withAlpha(150) : cardColor,
          borderRadius: BorderRadius.circular(15.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(76),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 6.0,
              height: isSmallScreen ? 60.0 : 70.0,
              decoration: BoxDecoration(
                color: sideBarColor, // Usamos el color determinado
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15.0),
                  bottomLeft: Radius.circular(15.0),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 10.0 : 12.0,
                  vertical: isSmallScreen ? 6.0 : 8.0,
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: onToggle,
                      child: Icon(
                        task.isCompleted
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: task.isCompleted
                            ? Colors.green
                            : secondaryTextColor,
                        size: isSmallScreen ? 24 : 28,
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 10 : 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            task.title,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 16,
                              fontWeight: FontWeight.w600,
                              decoration: task.isCompleted
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                              color: textColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          SizedBox(height: isSmallScreen ? 2 : 4),

                          // ===============================================
                          // ✅✅✅ ¡AQUÍ ESTÁ LA CORRECCIÓN! ✅✅✅
                          // ===============================================
                          Text(
                            // Leemos 'timeHour' y 'timeMinute' en lugar de 'dueDate'
                            'Hora: ${task.timeHour.toString().padLeft(2, '0')}:${task.timeMinute.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 12 : 14,
                              color: secondaryTextColor,
                            ),
                          ),

                          // ===============================================
                          // FIN DE LA CORRECCIÓN
                          // ===============================================
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.edit_outlined,
                        color: primaryColor.withAlpha(204),
                        size: isSmallScreen ? 20 : 22,
                      ),
                      onPressed: onEdit,
                      tooltip: 'Editar Tarea',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
