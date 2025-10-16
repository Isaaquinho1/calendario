// lib/screens/add_task_screen.dart

import 'package:flutter/material.dart';
import '../models/task.dart'; 
import 'package:intl/intl.dart';
import '../utils/notification_service.dart';
import '../main.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  // Los Controladores y las variables que cambian (Date, Time, Color)
  // NO deben ser final, a pesar de la advertencia.
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  Color _selectedColor = Colors.orange.shade700; 
  
  // Variables para los selectores de Recordar y Repetir
  String _selectedReminder = 'Ninguno';
  String _selectedRepetition = 'Ninguno';

  // Opciones de Recordatorio
  final List<String> _reminderOptions = const [
    'Ninguno',
    '5 minutos antes',
    '10 minutos antes',
    '15 minutos antes',
    '20 minutos antes',
    '30 minutos antes',
    '45 minutos antes',
    '1 hora antes',
  ];

  // Opciones de Repetición
  final List<String> _repetitionOptions = const [
    'Ninguno',
    'Diariamente',
    'Semanalmente',
    'Mensualmente',
  ];

  // Colores del Tema (Las variables no utilizadas han sido eliminadas o corregidas)
  static const Color primaryColor = Color(0xFF555FD0); 
  static const Color backgroundColor = Color(0xFF2B2C33); 
  static const Color cardColor = Color(0xFF3B3C45); 
  static const Color whiteCardColor = Color(0xFFE8E8E8); 
  static const Color darkTextColor = Color(0xFF444444); 
  static const Color textColor = Colors.white; 
  static const Color secondaryTextColor = Color(0xFFAAAAAA);

  // Paleta de colores (Se mantiene, se usa en el picker)
  final List<Color> _colorPalette = const [
    Colors.orange, // Simplificado para evitar .shade
    Colors.indigo,
    Colors.teal,
    Colors.pink,
    Colors.purple,
  ];

  // --- Funciones de Seleccion de Fecha y Hora ---
  
  // La lógica del DatePicker/TimePicker no cambia, solo su Builder para el tema oscuro
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: primaryColor,
              onSurface: textColor,
              surface: backgroundColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: primaryColor,
              onSurface: textColor,
              surface: backgroundColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }
  
  // Función para mostrar el selector de opciones (Recordar/Repetir)
  Future<void> _showOptionSelector(
      BuildContext context, List<String> options, String current, Function(String) onSelect) async {
    final String? selected = await showModalBottomSheet<String>(
      context: context,
      builder: (BuildContext context) {
        return Container(
          color: cardColor,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: options.map((String option) {
              return ListTile(
                title: Text(
                  option,
                  style: TextStyle(color: current == option ? primaryColor : textColor),
                ),
                onTap: () {
                  Navigator.pop(context, option);
                },
              );
            }).toList(),
          ),
        );
      },
    );
    if (selected != null) {
      onSelect(selected);
    }
  }

  // --- Función para guardar la tarea (ACTUALIZADA con nuevos campos) ---
  void _saveTask() {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Oye! El título de la tarea es obligatorio.')),
      );
      return;
    }

    final newDueDate = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
    
    // El modelo Task ahora usa los parámetros this. para inicializar los campos
    final newTask = Task(
      title: _titleController.text,
      note: _noteController.text,
      dueDate: newDueDate,
      color: _selectedColor,
      reminderInterval: _selectedReminder,
      repetitionFrequency: _selectedRepetition,
    );
    
    NotificationService.scheduleNotification(newTask, flutterLocalNotificationsPlugin);

    Navigator.pop(context, newTask);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: null, 
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 10.0, top: 5.0),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: cardColor, 
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_ios_new, 
                color: textColor,
                size: 20,
              ),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 15.0, top: 5.0),
            child: GestureDetector(
              onTap: _saveTask,
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: cardColor, 
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check, 
                  color: primaryColor, 
                  size: 25,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Título Central: "Agregar Nueva Tarea"
            Center(
              child: Text(
                'Agregar Nueva Tarea',
                style: const TextStyle(
                  color: textColor, 
                  fontSize: 20, 
                  fontWeight: FontWeight.w900, 
                ),
              ),
            ),
            const SizedBox(height: 30),
            
            // 1. CAMPOS DE TEXTO COMBINADOS (TÍTULO Y DESCRIPCIÓN)
            _buildCombinedInputCard(
              titleController: _titleController,
              noteController: _noteController,
              cardColor: cardColor,
            ),
            const SizedBox(height: 30),

            // 2. SELECTOR DE FECHA (Color blanco agrisado)
            _buildSelectorCard(
              title: 'Fecha',
              value: DateFormat('dd MMMM, yyyy', 'es').format(_selectedDate), 
              icon: Icons.calendar_today,
              onTap: () => _selectDate(context),
              cardColor: whiteCardColor,
              primaryColor: darkTextColor,
              secondaryColor: primaryColor,
            ),
            const SizedBox(height: 15),

            // 3. SELECTOR DE HORA (Color blanco agrisado)
            _buildSelectorCard(
              title: 'Hora',
              value: _selectedTime.format(context),
              icon: Icons.access_time,
              onTap: () => _selectTime(context),
              cardColor: whiteCardColor,
              primaryColor: darkTextColor,
              secondaryColor: primaryColor,
            ),
            const SizedBox(height: 15),
            
            // 4. SELECTOR DE RECORDAR
            _buildSelectorCard(
              title: 'Recordar',
              value: _selectedReminder,
              icon: Icons.notifications_active,
              onTap: () {
                _showOptionSelector(context, _reminderOptions, _selectedReminder, (value) {
                  setState(() => _selectedReminder = value);
                });
              },
              cardColor: whiteCardColor,
              primaryColor: darkTextColor,
              secondaryColor: primaryColor,
            ),
            const SizedBox(height: 15),

            // 5. SELECTOR DE REPETIR
            _buildSelectorCard(
              title: 'Repetir',
              value: _selectedRepetition,
              icon: Icons.repeat,
              onTap: () {
                _showOptionSelector(context, _repetitionOptions, _selectedRepetition, (value) {
                  setState(() => _selectedRepetition = value);
                });
              },
              cardColor: whiteCardColor,
              primaryColor: darkTextColor,
              secondaryColor: primaryColor,
            ),
            const SizedBox(height: 30),

            // 6. SELECTOR DE PRIORIDAD (Penúltimo lugar)
            _buildPrioritySelector(
              title: 'Prioridad',
              cardColor: whiteCardColor,
            ),
            const SizedBox(height: 30),

            // 7. TEXTO DE HASTAGS
            const Text(
              'Agregar Hashtags',
              style: TextStyle(
                color: secondaryTextColor,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(15), 
              ),
              child: Text(
                '#trabajo #personal #estudio', 
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // WIDGET Selector Card (Fecha/Hora/Recordar/Repetir)
  Widget _buildSelectorCard({
    required String title,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
    required Color cardColor,
    required Color primaryColor,
    required Color secondaryColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Icon(icon, color: primaryColor),
            const SizedBox(width: 15),
            Text(
              title,
              style: TextStyle(fontSize: 16, color: primaryColor, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                color: secondaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Transform.rotate(
              angle: -45 * (3.1415926535 / 180), 
              child: Icon(Icons.arrow_right_alt, color: secondaryColor, size: 25),
            ),
          ],
        ),
      ),
    );
  }

  // WIDGET Selector de Prioridad
  Widget _buildPrioritySelector({
    required String title,
    required Color cardColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {},
            child: Row(
              children: [
                Icon(Icons.priority_high, color: darkTextColor),
                const SizedBox(width: 15),
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, color: darkTextColor, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  width: 15,
                  height: 15,
                  decoration: BoxDecoration(
                    color: _selectedColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Transform.rotate(
                  angle: -45 * (3.1415926535 / 180),
                  child: const Icon(Icons.arrow_right_alt, color: primaryColor, size: 25),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          _buildColorPicker(),
        ],
      ),
    );
  }

  // WIDGET Campos de Texto Combinados (Corrección de withOpacity)
  Widget _buildCombinedInputCard({
    required TextEditingController titleController,
    required TextEditingController noteController,
    required Color cardColor,
  }) {
    const TextStyle labelStyle = TextStyle(
      color: secondaryTextColor,
      fontSize: 16,
      fontWeight: FontWeight.w700,
    );
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          const Text('Título', style: labelStyle),
          TextField(
            controller: titleController,
            style: const TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
            cursorColor: primaryColor,
            decoration: InputDecoration(
              hintText: 'Escribe el título...',
              hintStyle: TextStyle(color: secondaryTextColor.withAlpha(127)), // ✅ Corregido (withOpacity -> withAlpha)
              border: InputBorder.none,
              contentPadding: const EdgeInsets.only(top: 5, bottom: 5),
            ),
          ),
          
          // Línea divisoria
          Divider(color: secondaryTextColor.withAlpha(76), height: 20), // ✅ Corregido (withOpacity -> withAlpha)
          
          // Nota/Descripción
          const Text('Descripción', style: labelStyle),
          TextField(
            controller: noteController,
            maxLines: 4,
            style: const TextStyle(color: textColor, fontSize: 16),
            cursorColor: primaryColor,
            decoration: InputDecoration(
              hintText: 'Escribe algunos detalles...',
              hintStyle: TextStyle(color: secondaryTextColor.withAlpha(127)), // ✅ Corregido (withOpacity -> withAlpha)
              border: InputBorder.none,
              contentPadding: const EdgeInsets.only(top: 5, bottom: 5),
            ),
          ),
        ],
      ),
    );
  }

  // WIDGET Selector de Color (El cuerpo de la función es el mismo)
  Widget _buildColorPicker() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _colorPalette.length,
        itemBuilder: (context, index) {
          final color = _colorPalette[index];
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedColor = color;
              });
            },
            child: Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(right: 15),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: _selectedColor == color
                    ? Border.all(color: Colors.black, width: 3)
                    : null,
              ),
              child: _selectedColor == color
                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                  : null,
            ),
          );
        },
      ),
    );
  }
}