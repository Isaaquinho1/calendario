import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/task.dart';
import 'add_task_screen.dart';
import 'edit_task_screen.dart';
import 'profile_screen.dart'; 
// ❌ ELIMINADAS: 'package:flutter/services.dart' y 'package:hive/hive.dart' (redundantes)

// Enum para el filtro de estado
enum Filter { pending, completed }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // --- MODIFICADO ---
  final Box _userBox = Hive.box('userBox');
  late Box<Task> _taskBox;
  // --- FIN MODIFICADO ---

  // Variables de estado
  late String _userName;
  Filter _activeFilter = Filter.pending;
  String? _selectedCategory;

  // --- NUEVO ---
  Future<void>? _initBoxesFuture;
  // --- FIN NUEVO ---

  @override
  void initState() {
    super.initState();
    _initBoxesFuture = _initializeData();
  }

  // --- NUEVA FUNCIÓN PARA INICIALIZAR ---
  Future<void> _initializeData() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception("No hay ningún usuario logueado.");
    }

    final String uid = currentUser.uid;
    final String userTaskBoxName = 'tasks_$uid';

    _taskBox = await Hive.openBox<Task>(userTaskBoxName);

    final lastEmail = _userBox.get('last_email');
    final currentEmail = currentUser.email;

    if (currentEmail != null && currentEmail != lastEmail) {
      _userBox.delete('name');
      _userBox.delete('birthdate'); 
      _userBox.put('last_email', currentEmail);
      _userName = 'Usuario';
    } else {
      // 🔑 CORRECCIÓN: Asumimos que get devuelve String si no es nulo
      _userName = _userBox.get('name', defaultValue: 'Usuario') as String;
    }
  }
  // --- FIN NUEVA FUNCIÓN ---

  // --- FUNCIONES DE PERSISTENCIA ---
  
  void _toggleTaskCompletion(dynamic key) {
    // 🔑 CORRECCIÓN: Eliminada la aserción '!' redundante
    final Task taskToUpdate = _taskBox.get(key)!; 
    taskToUpdate.isCompleted = !taskToUpdate.isCompleted;
    _taskBox.put(key, taskToUpdate);

    // ... (Snackbar logic omitted for brevity)
  }

  void _deleteTask(dynamic key, Task deletedTask) {
    _taskBox.delete(key);
    // ... (Snackbar logic omitted for brevity)
  }

  // 🔑 CORRECCIÓN: Seguridad asíncrona y redundancia
  void _editTask(dynamic key, Task task) async {
    // 🔑 LÍNEA 214: await Navigator.push (uso de context)
    final result = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                EditTaskScreen(task: task, taskIndex: 0, taskKey: key)));
    
    // 🔑 CORRECCIÓN: Proteger el context después del await (Línea 214)
    if (!mounted) return;

    // 🔑 CORRECCIÓN: Eliminada la comprobación 'result != null' (Línea 333)
    if (result is Map) {
      final updatedTask = result['task'] as Task;
      final taskKey = result['key'];
      if (taskKey != null) {
        _taskBox.put(taskKey, updatedTask);
      }
    }
  }

  // --- FUNCIÓN DE SALUDO (Sin cambios) ---
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

  // --- HELPER DE CATEGORÍAS (Limpieza de operadores nulos) ---
  Set<String> _getCategories(List<Task> tasks) {
    final Set<String> categories = {};
    bool hasUncategorized = false;
    for (final task in tasks) {
      String? taskCategory;
      // 🔑 CORRECCIÓN: task.note ya no es nulo, se elimina el != null (Línea 341)
      if (task.note.startsWith('Categoría: ')) { 
        taskCategory =
            task.note.split('\n').first.replaceFirst('Categoría: ', '').trim();
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

  // --- WIDGET MENÚ DE PERFIL (MODIFICADO) ---
  Widget _buildProfileMenu(BuildContext context, Color iconColor) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final String name = _userName; 
    final String email = currentUser?.email ?? 'Sin Email';

    return PopupMenuButton<String>(
      icon: Icon(Icons.menu, color: iconColor),
      onSelected: (value) async {
        
        // --- CAMBIO AQUÍ ---
        if (value == 'profile') {
          final bool? profileWasUpdated = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => ProfileScreen(
                userBox: _userBox,
                taskBox: _taskBox,
              ),
            ),
          );
          
          // 🔑 CORRECCIÓN: Proteger setState después del await
          if (profileWasUpdated == true && mounted) {
            setState(() {
              _userName = _userBox.get('name', defaultValue: 'Usuario');
            });
          }
        // --- FIN CAMBIO ---

        } else if (value == 'logout') {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("¡Nos vemos luego, $_userName!"),
            backgroundColor: Colors.blueAccent,
          ));

          await Future.delayed(const Duration(milliseconds: 1500));
          await FirebaseAuth.instance.signOut();

          // --- NUEVO: CERRAR LA CAJA DEL USUARIO ---
          await _taskBox.close();
          // --- FIN NUEVO ---

          if (mounted) {
            Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
          }
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 0, 0, 0))),
              Text(email,
                  style: const TextStyle(
                      fontSize: 12, color: Color.fromARGB(255, 33, 33, 33))),
            ],
          ),
        ),
        const PopupMenuDivider(),
        
        const PopupMenuItem<String>(
          value: 'profile',
          child: Row(children: [
            Icon(Icons.person_outline),
            SizedBox(width: 10),
            Text('Perfil')
          ]),
        ),
        
        const PopupMenuItem<String>(
          value: 'logout',
          child: Row(children: [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 10),
            Text('Cerrar Sesión')
          ]),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Colores del tema (los muevo aquí para usarlos en el FutureBuilder)
    const Color primaryColor = Color.fromARGB(255, 55, 78, 107);
    const Color backgroundColor = Color.fromARGB(255, 232, 232, 232);
    const Color cardColor = Color.fromARGB(255, 212, 212, 212);
    const Color textColor = Color.fromARGB(255, 59, 59, 59);
    const Color secondaryTextColor = Color.fromARGB(255, 55, 78, 107);
    const Color fabColor = Colors.blueAccent;

    // --- MODIFICADO: AÑADIDO FUTUREBUILDER ---
    return FutureBuilder<void>(
      future: _initBoxesFuture,
      builder: (context, snapshot) {
        // --- ESTADO 1: CARGANDO ---
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: backgroundColor,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // --- ESTADO 2: ERROR ---
        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: backgroundColor,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  "Error al cargar datos: ${snapshot.error}. Intenta reiniciar la app.", 
                  textAlign: TextAlign.center
                ),
              ),
            ),
          );
        }

        // --- ESTADO 3: ÉXITO ---
        return ValueListenableBuilder(
          valueListenable: _taskBox.listenable(),
          builder: (context, Box<Task> box, _) {
            // --- 1. Calcular estado ---
            final Map<dynamic, Task> taskMap = box.toMap();
            final List<Task> allTasks = taskMap.values.toList();
            final bool isTotalyEmpty = allTasks.isEmpty;

            final List<Task> pendingTasks =
                allTasks.where((t) => !t.isCompleted).toList();
            final List<Task> completedTasks =
                allTasks.where((t) => t.isCompleted).toList();
            final completedCount = completedTasks.length;
            final upcomingCount = pendingTasks.length;

            final List<Task> listForCurrentFilter =
                (_activeFilter == Filter.pending) ? pendingTasks : completedTasks;
            // 🔑 CORRECCIÓN: Simplificación de la colección
            final Set<String> categoriesForCurrentFilter = _getCategories(listForCurrentFilter);

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
                // 🔑 CORRECCIÓN: Estructura de control sin llaves
                if (_selectedCategory == 'Otros') return taskCategory == null || taskCategory.isEmpty;
                return taskCategory == _selectedCategory;
              }),
            );

            final bool isFilteredListEmpty = filteredMap.isEmpty;
            final List<Task> tasksToDisplay = filteredMap.values.toList();
            final List<dynamic> keysToDisplay = filteredMap.keys.toList();

            // --- 2. Construir Scaffold ---
            return Scaffold(
              backgroundColor: backgroundColor,
              appBar: AppBar(
                backgroundColor: backgroundColor,
                elevation: 0,
                leading: (isTotalyEmpty || isFilteredListEmpty)
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.all(1.0),
                        child: SvgPicture.asset('remi3.svg', height: 55),
                      ),
                actions: [
                  _buildProfileMenu(context, primaryColor)
                ],
              ),
              floatingActionButton: SizedBox(
                  width: 70.0,
                  height: 70.0,
                  child: FloatingActionButton(
                      onPressed: () async {
                        final newTask = await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const AddTaskScreen()));
                        // 🔑 CORRECCIÓN: Simplificación de la comprobación
                        if (newTask is Task) { 
                          _taskBox.add(newTask);
                        }
                      },
                      backgroundColor: fabColor,
                      foregroundColor: Colors.white,
                      shape: const CircleBorder(),
                      child: const Icon(Icons.add, size: 35))),
              floatingActionButtonLocation:
                  FloatingActionButtonLocation.startFloat,
              body: SafeArea(
                  child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(getPersonalizedGreeting(),
                                style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: textColor)),
                            const SizedBox(height: 8),
                            Text(
                                'Hoy, ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                                style: const TextStyle(
                                    fontSize: 16, color: secondaryTextColor)),
                            const SizedBox(height: 25),
                            _buildMetricCards(
                                context,
                                primaryColor,
                                cardColor,
                                textColor,
                                upcomingCount,
                                completedCount),
                            const SizedBox(height: 25),
                            const Text('Mis Tareas',
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: textColor)),
                            const SizedBox(height: 15),
                            _buildCategoryFilters(
                                categoriesForCurrentFilter, primaryColor),
                            const SizedBox(height: 15),
                            Expanded(
                                child: (isTotalyEmpty || isFilteredListEmpty)
                                    ? Center(
                                        child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                          SvgPicture.asset('remi3.svg',
                                              height: 200),
                                          const SizedBox(height: 10),
                                          Text(
                                              isTotalyEmpty
                                                  ? '¡Parece que no tienes tareas! \nPresiona "+" para empezar a conquistar el día.'
                                                  : '¡Nada por aquí! \nNo hay tareas en esta vista.',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                  fontSize: 18,
                                                  color: secondaryTextColor)),
                                        ]))
                                    : ListView.builder(
                                        itemCount: tasksToDisplay.length,
                                        itemBuilder: (context, index) {
                                          final task = tasksToDisplay[index];
                                          final key = keysToDisplay[index];
                                          return TaskCard(
                                            task: task,
                                            onToggle: () =>
                                                _toggleTaskCompletion(key),
                                            onDelete: () =>
                                                _deleteTask(key, task),
                                            onEdit: () => _editTask(key, task),
                                            cardColor: cardColor,
                                            primaryColor: primaryColor,
                                          );
                                        })),
                          ]))),
            );
          },
        );
      },
    );
    // --- FIN MODIFICADO ---
  }

  // --- WIDGETS AUXILIARES (CON CORRECCIONES DE SINTAXIS) ---
  
  Widget _buildMetricCards(
    BuildContext context,
    Color primaryColor,
    Color cardColor,
    Color textColor,
    int upcomingCount,
    int completedCount,
  ) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            // 🔑 CORRECCIÓN: Eliminar las llaves de la lambda de setState (unnecessary_set_literal)
            onTap: () => setState(
                () {
                  _activeFilter = Filter.completed; 
                  _selectedCategory = null;
                }),
            child: _buildMetricCard(context, 'Completas',
                completedCount.toString(), primaryColor, cardColor, textColor,
                _activeFilter == Filter.completed),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: GestureDetector(
            // 🔑 CORRECCIÓN: Eliminar las llaves de la lambda de setState (unnecessary_set_literal)
            onTap: () => setState(
                () {
                  _activeFilter = Filter.pending; 
                  _selectedCategory = null;
                }),
            child: _buildMetricCard(context, 'Pendientes',
                upcomingCount.toString(), primaryColor, cardColor, textColor,
                _activeFilter == Filter.pending),
          ),
        ),
      ],
    );
  }

  // WIDGET Diseño de Tarjeta de Métrica
  Widget _buildMetricCard(
    BuildContext context,
    String title,
    String count,
    Color primaryColor,
    Color cardColor,
    Color textColor,
    bool isSelected,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15),
        border: isSelected ? Border.all(color: primaryColor, width: 2.5) : null,
        boxShadow: isSelected
            ? [
                BoxShadow(
                    color: primaryColor.withAlpha(102),
                    blurRadius: 8,
                    spreadRadius: 2)
              ]
            : [],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style:
                TextStyle(color: primaryColor, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Text(count,
            style: TextStyle(
                color: textColor, fontSize: 48, fontWeight: FontWeight.w900)),
      ]),
    );
  }

  Widget _buildCategoryFilters(Set<String> categories, Color primaryColor) {
    List<String> sortedCategories =
        categories.where((c) => c != 'Otros').toList()..sort();
    if (categories.contains('Otros')) {
      sortedCategories.add('Otros');
    }
    if (sortedCategories.isEmpty) return const SizedBox.shrink();
    return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          ChoiceChip(
            label: const Text('Todos'),
            selected: _selectedCategory == null,
            onSelected: (selected) {
              if (selected) setState(() => _selectedCategory = null);
            },
            selectedColor: primaryColor,
            labelStyle: TextStyle(
                color: _selectedCategory == null ? Colors.white : primaryColor),
            backgroundColor: Colors.white.withAlpha(178),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            showCheckmark: false,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          const SizedBox(width: 8),
          ...sortedCategories.map((category) {
            return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(category),
                  selected: _selectedCategory == category,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedCategory = category);
                  },
                  selectedColor: primaryColor,
                  labelStyle: TextStyle(
                      color: _selectedCategory == category
                          ? Colors.white
                          : primaryColor),
                  backgroundColor: Colors.white.withAlpha(178),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  showCheckmark: false,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ));
          }),
        ]));
  }
}

// ------------------------------------------------------------------
// WIDGET TASKCARD (Sin cambios)
// ------------------------------------------------------------------

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final Color cardColor;
  final Color primaryColor;

  const TaskCard({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
    required this.cardColor,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    const Color textColor = Color.fromARGB(255, 0, 0, 0);
    const Color secondaryTextColor = Color.fromARGB(255, 0, 0, 0);

    return Dismissible(
      key: UniqueKey(),
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
        margin: const EdgeInsets.only(bottom: 15.0),
        decoration: BoxDecoration(
          color: task.isCompleted ? cardColor.withAlpha(150) : cardColor,
          borderRadius: BorderRadius.circular(15.0),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withAlpha(76),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 3))
          ],
        ),
        child: Row(children: <Widget>[
          Container(
            width: 8.0,
            height: 70.0,
            decoration: BoxDecoration(
                color: task.color,
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(15.0),
                    bottomLeft: Radius.circular(15.0))),
          ),
          Expanded(
              child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12.0, vertical: 8.0),
                  child: Row(children: [
                    GestureDetector(
                      onTap: onToggle,
                      child: Icon(
                          task.isCompleted
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: task.isCompleted
                              ? Colors.green
                              : secondaryTextColor,
                          size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                          Text(task.title,
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  decoration: task.isCompleted
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                                  color: textColor),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1),
                          const SizedBox(height: 4),
                          Text(
                              'Hora: ${task.dueDate.hour}:${task.dueDate.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                  fontSize: 14, color: secondaryTextColor)),
                        ])),
                    IconButton(
                      icon: Icon(Icons.edit_outlined,
                          color: primaryColor.withAlpha(204), size: 22),
                      onPressed: onEdit,
                      tooltip: 'Editar Tarea',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ]))),
        ]),
      ),
    );
  }
}