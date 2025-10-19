import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart'; 
import '../models/task.dart'; 
import 'add_task_screen.dart';
import 'edit_task_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userName;
  const HomeScreen({super.key, this.userName = 'Estudiante'});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Referencia a la caja de Hive
  final Box<Task> _taskBox = Hive.box<Task>('tasks');
  
  // --- FUNCIONES DE PERSISTENCIA ---
  
  void _toggleTaskCompletion(int index) {
    final Task taskToUpdate = _taskBox.getAt(index)!;
    taskToUpdate.isCompleted = !taskToUpdate.isCompleted;

    _taskBox.putAt(index, taskToUpdate); 
    
    final String message = taskToUpdate.isCompleted
      ? '¡Felicidades, ${widget.userName}! Tarea "${taskToUpdate.title}" completada. 🎉'
      : '¡Ánimo! Tarea restaurada a pendiente.';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(milliseconds: 1500),
        backgroundColor: taskToUpdate.isCompleted ? Colors.green : Colors.indigo,
      ),
    );
  }
  
  void _deleteTask(int index) {
    final Task deletedTask = _taskBox.getAt(index)!;
    final int deletedIndex = index;

    _taskBox.deleteAt(index);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tarea "${deletedTask.title}" eliminada.'),
        backgroundColor: Colors.red.shade700,
        action: SnackBarAction(
          label: 'DESHACER',
          textColor: Colors.white,
          onPressed: () {
            _taskBox.putAt(deletedIndex, deletedTask);
          },
        ),
      ),
    );
  }

  void _editTask(int index, Task task) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditTaskScreen(
          task: task,
          taskIndex: index,
        ),
      ),
    );
    
    if (result != null && result is Map) {
      final updatedTask = result['task'] as Task;
      final taskIndex = result['index'] as int;
      
      _taskBox.putAt(taskIndex, updatedTask); 
    }
  }

  // --- FUNCIÓN DE SALUDO ---

  String getPersonalizedGreeting() {
    final List<String> greetings = [
        '¡Hola, ${widget.userName}! 👋 ¿Listo para conquistar el día?',
        '¡Excelente, ${widget.userName}! Vamos por esas metas. 🚀',
        'A trabajar, ${widget.userName}. ¡Hoy es tu día! 💪',
        '¡Qué gusto verte, ${widget.userName}! Tienes tareas importantes. 😉',
        '¡El tiempo es oro, ${widget.userName}! A darle con todo. ⏰',
    ];
    return greetings[DateTime.now().hour % greetings.length]; 
  }

  @override
  Widget build(BuildContext context) {
    // 🔑 Colores del tema
    const Color primaryColor = Color.fromARGB(255, 55, 78, 107); 
    const Color backgroundColor = Color.fromARGB(255, 232, 232, 232); 
    const Color cardColor = Color.fromARGB(255, 212, 212, 212); 
    const Color textColor = Color.fromARGB(255, 59, 59, 59); 
    const Color secondaryTextColor = Color.fromARGB(255, 55, 78, 107); 

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: primaryColor, size: 30),
            onPressed: () async {
              final newTask = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddTaskScreen(),
                ),
              );
              
              if (newTask != null && newTask is Task) {
                _taskBox.add(newTask);
              }
            },
          ),
          const SizedBox(width: 10), // Pequeño espacio a la derecha
        ],
      ),
      
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // *** Saludo Personalizado ***
              Text(
                getPersonalizedGreeting(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              
              // Fecha y hora
              Text(
                'Hoy, ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                style: const TextStyle(
                  fontSize: 16,
                  color: secondaryTextColor,
                ),
              ),
              const SizedBox(height: 25),

              // Sección de Números Grandes
              _buildMetricCards(context, primaryColor, cardColor, textColor),
              const SizedBox(height: 25),
              
              // Título de la lista
              Text(
                'Mis Tareas',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 15),

              // *** Lista de Tareas con Interacción (Persistente) ***
              Expanded(
                child: ValueListenableBuilder(
                  valueListenable: _taskBox.listenable(), 
                  builder: (context, Box<Task> box, _) {
                    final List<Task> tasks = box.values.toList();
                    
                    if (tasks.isEmpty) {
                      return Center(
                        child: Text(
                          '¡Parece que no tienes tareas! \nPresiona "+" para empezar a conquistar el día.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 18, color: secondaryTextColor),
                        ),
                      );
                    }
                    
                    return ListView.builder(
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        return TaskCard(
                          task: task,
                          onToggle: () => _toggleTaskCompletion(index),
                          onDelete: () => _deleteTask(index),
                          onEdit: () => _editTask(index, task),
                          cardColor: cardColor,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // WIDGET Tarjetas de Métricas
  Widget _buildMetricCards(BuildContext context, Color primaryColor, Color cardColor, Color textColor) {
    final List<Task> allTasks = _taskBox.values.toList();
    final int completedCount = allTasks.where((t) => t.isCompleted).length;
    final int upcomingCount = allTasks.where((t) => !t.isCompleted).length;

    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            context,
            'Completas',
            completedCount.toString(),
            primaryColor,
            cardColor,
            textColor,
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _buildMetricCard(
            context,
            'Pendientes',
            upcomingCount.toString(),
            primaryColor,
            cardColor,
            textColor,
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
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Text(
            count,
            style: TextStyle(
              color: textColor,
              fontSize: 48,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
// ------------------------------------------------------------------
// WIDGET TASKCARD FINAL CORREGIDO
// ------------------------------------------------------------------

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onToggle; 
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final Color cardColor; 

  const TaskCard({
    super.key, 
    required this.task,
    required this.onToggle, 
    required this.onDelete, 
    required this.onEdit,
    required this.cardColor,
  }); 

  @override
  Widget build(BuildContext context) {
    const Color textColor = Color.fromARGB(255, 0, 0, 0); 
    const Color secondaryTextColor = Color.fromARGB(255, 0, 0, 0);
    
    return Dismissible(
      key: Key(task.title + task.dueDate.toString()), 
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
          // La opacidad en la tarjeta completada es más sutil
          color: task.isCompleted ? cardColor.withAlpha(150) : cardColor, // ✅ CORREGIDO: withOpacity por withAlpha
          borderRadius: BorderRadius.circular(15.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(76), // ✅ CORREGIDO: withOpacity(0.3) por withAlpha(76)
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            // Tira de color lateral
            Container(
              width: 8.0,
              height: 70.0,
              decoration: BoxDecoration(
                color: task.color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15.0),
                  bottomLeft: Radius.circular(15.0),
                ),
              ),
            ),
            
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    // TAREA 1: TOGGLE
                    GestureDetector(
                      onTap: onToggle, 
                      child: Icon(
                        task.isCompleted 
                          ? Icons.check_circle 
                          : Icons.radio_button_unchecked,
                        color: task.isCompleted ? Colors.green : secondaryTextColor, 
                      ),
                    ),
                    const SizedBox(width: 15),
                    
                    // TAREA 2: EDITAR
                    Expanded(
                      child: GestureDetector(
                        onTap: onEdit,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              task.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                decoration: task.isCompleted 
                                    ? TextDecoration.lineThrough 
                                    : TextDecoration.none,
                                color: textColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Hora: ${task.dueDate.hour}:${task.dueDate.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
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