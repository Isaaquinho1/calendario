// lib/screens/add_task_screen.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import '../models/task.dart';
import 'package:intl/intl.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  // Controladores
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();

  // Variables de estado
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _selectedReminder = 'Ninguno';
  
  // Manejo de repetición con lista de booleanos
  List<bool> _selectedDays = List.filled(7, false); // [L, M, M, J, V, S, D]

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
    'Personalizado',
  ];

  // Colores del Tema
  static const Color primaryColor = Color.fromARGB(255, 55, 78, 107);
  static const Color backgroundColor = Color.fromARGB(255, 232, 232, 232);
  static const Color cardColor = Color.fromARGB(255, 212, 212, 212);
  static const Color whiteCardColor = Color.fromARGB(255, 212, 212, 212);
  static const Color darkTextColor = Color.fromARGB(255, 55, 78, 107);
  static const Color textColor = Color.fromARGB(255, 59, 59, 59);
  static const Color secondaryTextColor = Color.fromARGB(255, 59, 59, 59);

  // Nombres de los días para los botones
  final List<String> _dayNames = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  // --- Funciones de Seleccion de Fecha y Hora ---

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      locale: const Locale('es', 'ES'), // Pone el calendario en español
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith( // Mantenemos el tema oscuro para el calendario
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

// 🔑 FUNCIÓN _selectTime CORREGIDA: Ahora es async y funciona el await
  Future<void> _selectTime(BuildContext context) async {
    // 1. Inicializa las variables de estado basadas en la hora actual
    int selectedHour = _selectedTime.hourOfPeriod;
    if (selectedHour == 0) selectedHour = 12; // 12 AM se maneja como 12
    int selectedMinute = _selectedTime.minute;
    bool isAm = _selectedTime.period == DayPeriod.am;

    // Controladores para el estado inicial de los pickers
    final FixedExtentScrollController hourController =
        FixedExtentScrollController(initialItem: selectedHour - 1); // 1-12 -> 0-11
    final FixedExtentScrollController minuteController =
        FixedExtentScrollController(initialItem: selectedMinute); // 0-59

    // 2. Muestra un diálogo personalizado que devuelve un TimeOfDay
    final TimeOfDay? picked = await showDialog<TimeOfDay>(
      context: context,
      builder: (BuildContext context) {
        // 3. Usa StatefulBuilder para que el contenido del diálogo pueda actualizar su propio estado
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: cardColor, // Usa tu color de tarjeta
              title: const Text('Seleccionar Hora',
                  style: TextStyle(color: textColor)),
              contentPadding: const EdgeInsets.symmetric(vertical: 20),
              content: SizedBox(
                height: 200, // Altura fija para los pickers
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // --- Picker de Hora (1-12) ---
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: hourController,
                        itemExtent: 40,
                        onSelectedItemChanged: (int index) {
                          selectedHour = index + 1; // El índice es 0-11, el valor es 1-12
                        },
                        children: List.generate(
                            12,
                            (index) => Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                        color: textColor, fontSize: 22),
                                  ),
                                )),
                      ),
                    ),
                    const Text(':',
                        style: TextStyle(
                            color: textColor,
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),
                    // --- Picker de Minutos (0-59) ---
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: minuteController,
                        itemExtent: 40,
                        onSelectedItemChanged: (int index) {
                          selectedMinute = index;
                        },
                        looping: true, // Los minutos pueden dar la vuelta
                        children: List.generate(
                            60,
                            (index) => Center(
                                  child: Text(
                                    index.toString().padLeft(2, '0'), // Formato "00", "01", etc.
                                    style: const TextStyle(
                                        color: textColor, fontSize: 22),
                                  ),
                                )),
                      ),
                    ),
                    // --- Botones AM/PM ---
                    ToggleButtons(
                      direction: Axis.vertical, // Botones en vertical
                      isSelected: [isAm, !isAm], // [true, false] = AM, [false, true] = PM
                      onPressed: (int index) {
                        // Actualiza el estado *solo* del diálogo
                        setStateDialog(() {
                          isAm = index == 0; // 0 es AM, 1 es PM
                        });
                      },
                      borderRadius: BorderRadius.circular(10),
                      selectedColor: Colors.white,
                      fillColor: primaryColor.withAlpha(200), // Usa tu color primario
                      color: primaryColor,
                      constraints:
                          const BoxConstraints(minWidth: 50, minHeight: 40),
                      children: const [
                        Text('AM', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('PM', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(width: 10), // Pequeño espacio
                  ],
                ),
              ),
              actions: [
                TextButton(
                    child: const Text('Cancelar',
                        style: TextStyle(color: secondaryTextColor)),
                    onPressed: () {
                      Navigator.pop(context); // Devuelve null
                    }),
                TextButton(
                  child: const Text('Aceptar',
                      style: TextStyle(
                          color: primaryColor, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    // 4. Convierte el estado de 12h a 24h (TimeOfDay)
                    int hour24;
                    if (isAm) {
                      hour24 = (selectedHour == 12) ? 0 : selectedHour; // 12 AM es 0
                    } else {
                      hour24 = (selectedHour == 12) ? 12 : selectedHour + 12; // 12 PM es 12
                    }
                    // Devuelve el TimeOfDay seleccionado
                    Navigator.pop(
                        context, TimeOfDay(hour: hour24, minute: selectedMinute));
                  },
                ),
              ],
            );
          },
        );
      },
    );

    // 5. Esta lógica (la que ya tenías) no cambia
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }
  

  // --- Funciones de Selectores Personalizados (Recordar) ---

  // (Esta función se mantiene igual)
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

  // (Esta función se mantiene igual)
  Future<void> _showCustomReminderDialog() async {
    final TextEditingController reminderController = TextEditingController();

    final String? minutes = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: cardColor,
          title: const Text('Recordatorio Personalizado', style: TextStyle(color: textColor)),
          content: TextField(
            controller: reminderController,
            keyboardType: TextInputType.number,
            autofocus: true,
            style: const TextStyle(color: textColor),
            decoration: InputDecoration(
              hintText: 'Minutos antes',
              hintStyle: TextStyle(color: secondaryTextColor.withAlpha(150)),
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar', style: TextStyle(color: secondaryTextColor)),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: const Text('Aceptar', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.pop(context, reminderController.text);
              },
            ),
          ],
        );
      },
    );

    if (minutes != null && minutes.isNotEmpty) {
      final int? min = int.tryParse(minutes);
      if (min != null && min > 0) {
        setState(() {
          _selectedReminder = '$min minutos antes';
        });
      }
    }
  }
  
  // ⬅️ ELIMINADA: _showWeeklyRepetitionDialog()

  // ⬅️ NUEVO: Helper para convertir la lista de días en un String
  String _getRepetitionString() {
    final List<String> chosenDays = [];
    int selectedCount = 0;
    for (int i = 0; i < _selectedDays.length; i++) {
      if (_selectedDays[i]) {
        chosenDays.add(_dayNames[i]);
        selectedCount++;
      }
    }

    if (selectedCount == 0) {
      return 'Ninguno';
    } else if (selectedCount == 7) {
      return 'Diariamente';
    } else if (selectedCount == 5 && _selectedDays[5] == false && _selectedDays[6] == false) {
      return 'Entre semana';
    } else if (selectedCount == 2 && _selectedDays[5] == true && _selectedDays[6] == true) {
      return 'Fines de semana';
    } else {
      return 'Semanal: ${chosenDays.join(', ')}';
    }
  }


  // --- Función para guardar la tarea (ACTUALIZADA) ---
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
    
    // ⬅️ CAMBIO: Preparamos la nota con la categoría
    String note = _noteController.text;
    if (_categoryController.text.isNotEmpty) {
      note = "Categoría: ${_categoryController.text}\n\n${_noteController.text}";
    }

    final newTask = Task(
      title: _titleController.text,
      note: note, // ⬅️ CAMBIO: La nota ahora incluye la categoría
      dueDate: newDueDate,
      color: primaryColor, // ⬅️ CAMBIO: Color por defecto
      reminderInterval: _selectedReminder,
      repetitionFrequency: _getRepetitionString(), // ⬅️ CAMBIO: Usa el helper
    );

    //NotificationService.scheduleNotification(newTask, flutterLocalNotificationsPlugin);

    Navigator.pop(context, newTask);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        // ... (AppBar se mantiene igual)
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
      // 🔑 CORRECCIÓN: Estructura final del body para permitir el scroll
      body: SafeArea( 
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Imagen (se mantiene igual)
              Center(
                child: SvgPicture.asset(
                  'remi3.svg',
                  height: 150,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 15),

              // Título Central (se mantiene igual)
              const Center(
                child: Text(
                  'Agregar Nueva Tarea',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // 1. CAMPOS DE TEXTO
              _buildCombinedInputCard(
                titleController: _titleController,
                noteController: _noteController,
                cardColor: cardColor,
              ),
              const SizedBox(height: 30),

              // 2. SELECTOR DE FECHA
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

              // 3. SELECTOR DE HORA 
              _buildSelectorCard(
                title: 'Hora',
                value: _selectedTime.format(context),
                icon: Icons.access_time,
                onTap: () => _selectTime(context),
                cardColor: whiteCardColor,
                primaryColor: darkTextColor,
                secondaryColor: darkTextColor, 
              ),
              const SizedBox(height: 15),

              // 4. SELECTOR DE RECORDAR
              _buildSelectorCard(
                title: 'Recordar',
                value: _selectedReminder,
                icon: Icons.notifications_active,
                onTap: () {
                  _showOptionSelector(context, _reminderOptions, _selectedReminder, (value) {
                    if (value == 'Personalizado') {
                      _showCustomReminderDialog();
                    } else {
                      setState(() => _selectedReminder = value);
                    }
                  });
                },
                cardColor: whiteCardColor,
                primaryColor: darkTextColor,
                secondaryColor: primaryColor,
              ),
              const SizedBox(height: 15),

              // 5. SELECTOR DE REPETIR
              _buildRepetitionSelector(),
              const SizedBox(height: 30),

              // 6. SELECTOR DE CATEGORÍA
              _buildCategoryInput(
                categoryController: _categoryController,
                cardColor: whiteCardColor
              ),
              const SizedBox(height: 30),
              
              // Espacio final para el scroll
              const SizedBox(height: 50), 
            ],
          ),
        ), // <-- Cierra SingleChildScrollView
      ), // <-- Cierra SafeArea
    ); // <-- Cierra Scaffold
  }


  // --- WIDGETS AUXILIARES ---

  // WIDGET Selector Card (Fecha/Hora/Recordar)
  Widget _buildSelectorCard({
    required String title,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
    required Color cardColor,
    required Color primaryColor,
    required Color secondaryColor,
  }) {
    // ... (Este widget se mantiene igual)
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
                color: secondaryColor, // El color del valor (hora) viene aquí
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

  // ⬅️ NUEVO: WIDGET Selector de Repetición
  Widget _buildRepetitionSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      decoration: BoxDecoration(
        color: whiteCardColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          Row(
            children: [
              const Icon(Icons.repeat, color: darkTextColor),
              const SizedBox(width: 15),
              const Text(
                'Repetir',
                style: TextStyle(fontSize: 16, color: darkTextColor, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 15),
          
          // Botones de Atajo
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildShortcutButton('Entre semana', () {
                setState(() => _selectedDays = [true, true, true, true, true, false, false]);
              }),
              _buildShortcutButton('Fines de semana', () {
                setState(() => _selectedDays = [false, false, false, false, false, true, true]);
              }),
              _buildShortcutButton('Todos los días', () {
                setState(() => _selectedDays = List.filled(7, true));
              }),
            ],
          ),
          const SizedBox(height: 10),
          
          // Divisor
          Divider(color: secondaryTextColor.withAlpha(76), height: 20),
          const SizedBox(height: 10),

          // Selectores de Días
          Center(
            child: ToggleButtons(
              isSelected: _selectedDays,
              onPressed: (int index) {
                setState(() {
                  _selectedDays[index] = !_selectedDays[index];
                });
              },
              fillColor: primaryColor.withAlpha(200),
              selectedColor: Colors.white,
              color: primaryColor,
              borderRadius: BorderRadius.circular(10),
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              children: _dayNames.map((day) => Text(day, style: const TextStyle(fontWeight: FontWeight.bold))).toList(),
            ),
          ),
        ],
      ),
    );
  }
  
  // ⬅️ NUEVO: Helper para los botones de atajo
  Widget _buildShortcutButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: cardColor,
        foregroundColor: primaryColor,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 10),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12)),
    );
  }

  // WIDGET Campos de Texto Combinados (se mantiene igual)
  Widget _buildCombinedInputCard({
    required TextEditingController titleController,
    required TextEditingController noteController,
    required Color cardColor,
  }) {
    // ... (Este widget se mantiene igual)
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
              hintStyle: TextStyle(color: secondaryTextColor.withAlpha(127)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.only(top: 5, bottom: 5),
            ),
          ),

          // Línea divisoria
          Divider(color: secondaryTextColor.withAlpha(76), height: 20),

          // Nota/Descripción
          const Text('Descripción', style: labelStyle),
          TextField(
            controller: noteController,
            maxLines: 4,
            style: const TextStyle(color: textColor, fontSize: 16),
            cursorColor: primaryColor,
            decoration: InputDecoration(
              hintText: 'Escribe algunos detalles...',
              hintStyle: TextStyle(color: secondaryTextColor.withAlpha(127)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.only(top: 5, bottom: 5),
            ),
          ),
        ],
      ),
    );
  }

  // ⬅️ NUEVO: WIDGET para el campo de Categoría
  Widget _buildCategoryInput({
    required TextEditingController categoryController,
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
          const Text('Categoría', style: labelStyle),
          TextField(
            controller: categoryController,
            style: const TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
            cursorColor: primaryColor,
            decoration: InputDecoration(
              hintText: 'Ej: Escuela, Trabajo, Hogar...',
              hintStyle: TextStyle(color: secondaryTextColor.withAlpha(127)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.only(top: 5, bottom: 5),
            ),
          ),
        ],
      ),
    );
  }
  
  // ⬅️ ELIMINADO: _buildColorPicker()
}