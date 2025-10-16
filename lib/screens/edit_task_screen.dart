// lib/screens/edit_task_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Necesario para formatear fechas
import '../models/task.dart'; 

class EditTaskScreen extends StatefulWidget {
  final Task task;
  final int taskIndex; // Necesitamos el índice para actualizar la lista correctamente

  const EditTaskScreen({
    super.key, 
    required this.task,
    required this.taskIndex,
  });

  @override
  State<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  // Declaración de variables que se inicializarán desde la tarea pasada
  late TextEditingController _titleController;
  late TextEditingController _noteController;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late Color _selectedColor; 

  final List<Color> _colorPalette = [
    Colors.indigo,
    Colors.pink,
    Colors.teal,
    Colors.orange,
    Colors.purple,
  ];
  
  @override
  void initState() {
    super.initState();
    // 🔑 INICIALIZAR con los datos de la tarea existente (widget.task)
    _titleController = TextEditingController(text: widget.task.title);
    _noteController = TextEditingController(text: widget.task.note);
    _selectedDate = widget.task.dueDate;
    _selectedTime = TimeOfDay.fromDateTime(widget.task.dueDate);
    _selectedColor = widget.task.color;
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // --- Funciones de Seleccion de Fecha y Hora ---
  
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(DateTime.now().year - 5), 
      lastDate: DateTime(2101),
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
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }
  
  // Función para guardar la tarea
  void _updateTask() {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Oye! El título de la tarea es obligatorio.')),
      );
      return;
    }

    final updatedDueDate = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
    
    // 🔑 Crear la tarea actualizada, manteniendo el estado de completado original
    final updatedTask = Task(
      title: _titleController.text,
      note: _noteController.text,
      dueDate: updatedDueDate,
      color: _selectedColor,
      isCompleted: widget.task.isCompleted, 
    );
    
    // Regresa a la pantalla anterior, enviando la tarea actualizada y su índice
    Navigator.pop(context, {
      'task': updatedTask,
      'index': widget.taskIndex,
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Colors.indigo.shade700;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Editar Tarea'),
        backgroundColor: Colors.white,
        foregroundColor: primaryColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // 1. Campo de Título de Tarea
            _buildInputField(
              controller: _titleController,
              label: 'Título de la Tarea',
              hint: 'Ej: Estudiar para el examen de cálculo',
            ),
            const SizedBox(height: 20),
            
            // 2. Campo de Nota/Descripción
            _buildInputField(
              controller: _noteController,
              label: 'Nota (Opcional)',
              hint: 'Detalles importantes de la tarea',
              maxLines: 3,
            ),
            const SizedBox(height: 30),

            // 3. Selección de Fecha (Date Picker)
            _buildDateTimeRow(
              icon: Icons.calendar_today,
              label: 'Fecha',
              value: DateFormat('dd/MM/yyyy').format(_selectedDate),
              onTap: () => _selectDate(context),
            ),
            const SizedBox(height: 15),

            // 4. Selección de Hora (Time Picker)
            _buildDateTimeRow(
              icon: Icons.access_time,
              label: 'Hora',
              value: _selectedTime.format(context),
              onTap: () => _selectTime(context),
            ),
            const SizedBox(height: 30),
            
            // 5. Selección de Color 
            const Text(
              'Color de Categoría',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildColorPicker(),
            const SizedBox(height: 50),

            // 6. Botón Actualizar Tarea
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _updateTask,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                ),
                child: const Text(
                  'Actualizar Tarea',
                  style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Widgets Auxiliares (igual que AddTaskScreen) ---
  
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
  }) { /* ... */ return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.indigo.shade700, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimeRow({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) { /* ... */ return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: Colors.indigo.shade700),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                color: Colors.indigo.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildColorPicker() { /* ... */ return SizedBox(
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
                    ? Border.all(color: Colors.black, width: 2)
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