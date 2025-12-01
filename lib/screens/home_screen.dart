import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/task.dart';
import 'add_task_screen.dart';
import 'edit_task_screen.dart';
import 'profile_screen.dart';
import 'package:intl/intl.dart';

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
  // ignore: unused_field
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

  // ✅ FUNCIÓN 1: ELIMINAR CON DESHACER
  void _deleteTask(dynamic key, Task deletedTask) {
    // 1. Eliminar de la BD
    _taskBox.delete(key);

    // 2. Ocultar mensajes previos para que no se amontonen
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    // 3. Mostrar SnackBar con opción de deshacer
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Tarea eliminada',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.grey[850],
        duration: const Duration(seconds: 4), // Tiempo disponible para deshacer
        action: SnackBarAction(
          label: 'DESHACER',
          textColor: Colors.blueAccent, // Color del botón deshacer
          onPressed: () {
            // 4. RESTAURAR: Volvemos a guardar la tarea con su misma llave original
            _taskBox.put(key, deletedTask);

            // 5. Mensaje de confirmación
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('¡Tarea devuelta! 🫡'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
      ),
    );
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

  // ✅ FUNCIÓN 2: MOSTRAR DETALLES (VENTANA EMERGENTE)
  void _showTaskDetails(BuildContext context, Task task) {
    // Separamos la categoría de la nota para mostrarlo ordenado
    String category = 'Sin categoría';
    String description = task.note;

    if (task.note.startsWith('Categoría: ')) {
      final parts = task.note.split('\n');
      category = parts.first.replaceFirst('Categoría: ', '').trim();
      if (parts.length > 1) {
        description = parts.sublist(1).join('\n').trim();
      } else {
        description = 'Sin descripción adicional.';
      }
    }

    final String timeString =
        '${task.timeHour.toString().padLeft(2, '0')}:${task.timeMinute.toString().padLeft(2, '0')}';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          task.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hora
            Row(
              children: [
                const Icon(Icons.access_time, color: Colors.blueAccent),
                const SizedBox(width: 10),
                Text(
                  "Hora: $timeString",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            // Categoría
            Row(
              children: [
                const Icon(Icons.label_outline, color: Colors.orange),
                const SizedBox(width: 10),
                Text(
                  "Categoría: $category",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const Divider(height: 30, thickness: 1),
            // Descripción
            const Text(
              "Descripción:",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 5),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                description.isEmpty ? "Sin descripción." : description,
                style: const TextStyle(fontSize: 15, height: 1.4),
              ),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 55, 78, 107),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 10,
                ),
              ),
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(
                "Cerrar",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String getPersonalizedGreeting(String name) {
    final List<String> greetings = [
      '¡Hola, $name! 👋 ¿Listo para conquistar el día?',
      '¡Excelente, $name! Vamos por esas metas. 🚀',
      'A trabajar, $name. ¡Hoy es tu día! 💪',
      '¡Que gusto verte, $name! Tienes tareas importantes. 😉',
      '¡El tiempo es oro, $name! A darle con todo. ⏰',
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
    return ValueListenableBuilder(
      valueListenable: _userBox.listenable(keys: ['name']),
      builder: (context, Box box, _) {
        final String name = box.get('name', defaultValue: 'Usuario');
        final currentUser = FirebaseAuth.instance.currentUser;
        final String email = currentUser?.email ?? 'Sin Email';

        return PopupMenuButton<String>(
          icon: Icon(Icons.menu, color: iconColor),
          onSelected: (value) async {
            final navigator = Navigator.of(context);

            if (value == 'profile') {
              await navigator.push(
                MaterialPageRoute(
                  builder: (_) =>
                      ProfileScreen(userBox: _userBox, taskBox: _taskBox),
                ),
              );
            } else if (value == 'logout') {
              if (!mounted) return;

              final messenger = ScaffoldMessenger.of(context);
              messenger.showSnackBar(
                SnackBar(
                  content: Text("¡Nos vemos luego, $name!"),
                  backgroundColor: Colors.blueAccent,
                ),
              );

              await Future.delayed(const Duration(milliseconds: 1500));
              await FirebaseAuth.instance.signOut();
              await _taskBox.close();

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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color.fromARGB(255, 55, 78, 107);
    const Color backgroundColor = Color.fromARGB(255, 232, 232, 232);
    const Color cardColor = Color.fromARGB(255, 212, 212, 212);
    const Color textColor = Color.fromARGB(255, 59, 59, 59);
    const Color secondaryTextColor = Color.fromARGB(255, 55, 78, 107);
    const Color fabColor = Colors.blueAccent;

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 360;
    final isLargeScreen = screenWidth > 400;

    return FutureBuilder<void>(
      future: _initBoxesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: backgroundColor,
            body: Center(child: CircularProgressIndicator()),
          );
        }

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

        return ValueListenableBuilder(
          valueListenable: _taskBox.listenable(),
          builder: (context, Box<Task> box, _) {
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
                      ),
                actions: [_buildProfileMenu(context, primaryColor)],
              ),
              floatingActionButton: SizedBox(
                width: isSmallScreen ? 60.0 : 70.0,
                height: isSmallScreen ? 60.0 : 70.0,
                child: FloatingActionButton(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddTaskScreen(),
                      ),
                    );
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
                      ValueListenableBuilder(
                        valueListenable: _userBox.listenable(keys: ['name']),
                        builder: (context, Box box, _) {
                          final currentName = box.get(
                            'name',
                            defaultValue: 'Usuario',
                          );
                          return Text(
                            getPersonalizedGreeting(currentName),
                            style: TextStyle(
                              fontSize: isSmallScreen
                                  ? 20
                                  : isLargeScreen
                                  ? 26
                                  : 24,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          );
                        },
                      ),

                      SizedBox(height: screenHeight * 0.01),

                      Text(
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

                      Text(
                        'Mis Tareas',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 18 : 20,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.02),

                      _buildCategoryFilters(
                        categoriesForCurrentFilter,
                        primaryColor,
                        isSmallScreen: isSmallScreen,
                      ),
                      SizedBox(height: screenHeight * 0.02),

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

                                  // ✅ PASO 3: Pasamos el onTap para mostrar detalles
                                  return TaskCard(
                                    task: task,
                                    onToggle: () => _toggleTaskCompletion(key),
                                    onDelete: () => _deleteTask(key, task),
                                    onEdit: () => _editTask(key, task),
                                    onTap: () => _showTaskDetails(
                                      context,
                                      task,
                                    ), // <-- Click en tarjeta
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

  // --- WIDGETS AUXILIARES ---

  Widget _buildEmptyStateLogo(bool isSmallScreen, double screenHeight) {
    try {
      return SvgPicture.asset(
        'assets/curioso.svg',
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
// ✅ WIDGET TASKCARD ACTUALIZADO (Con detector de clicks)
// ------------------------------------------------------------------

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onTap; // Callback para abrir detalles

  final Color cardColor;
  final Color primaryColor;
  final bool isSmallScreen;

  const TaskCard({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
    required this.onTap, // Requerido ahora
    required this.cardColor,
    required this.primaryColor,
    this.isSmallScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    const Color textColor = Color.fromARGB(255, 0, 0, 0);
    const Color secondaryTextColor = Color.fromARGB(255, 0, 0, 0);
    final Color sideBarColor = task.isCompleted ? Colors.grey : (task.color);

    return Dismissible(
      key: UniqueKey(),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) => onDelete(),
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
            // Barra lateral de color
            Container(
              width: 6.0,
              height: isSmallScreen ? 60.0 : 70.0,
              decoration: BoxDecoration(
                color: sideBarColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15.0),
                  bottomLeft: Radius.circular(15.0),
                ),
              ),
            ),

            // ✅ CONTENIDO PRINCIPAL (Clickeable con InkWell)
            Expanded(
              child: InkWell(
                onTap: onTap, // Abre la ventana de detalles
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 10.0 : 12.0,
                    vertical: isSmallScreen ? 6.0 : 8.0,
                  ),
                  child: Row(
                    children: [
                      // Checkbox (Botón independiente, no abre detalles)
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

                      // Textos (Título y Hora)
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
                            Text(
                              'Hora: ${task.timeHour.toString().padLeft(2, '0')}:${task.timeMinute.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 12 : 14,
                                color: secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Botón Editar (Independiente)
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
            ),
          ],
        ),
      ),
    );
  }
}
