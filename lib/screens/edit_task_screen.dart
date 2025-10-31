// lib/screens/edit_task_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart'; // <--- AÑADE ESTA LÍNEA
import '../models/task.dart';

// ... el resto de tu clase ...
class EditTaskScreen extends StatefulWidget {
  final Task task;
  final int taskIndex;
  final dynamic taskKey;

  const EditTaskScreen({
    super.key,
    required this.task,
    required this.taskIndex,
    required this.taskKey,
  });

  @override
  State<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  // Controladores y variables de estado (sin cambios)
  late TextEditingController _titleController;
  late TextEditingController _noteController;
  late TextEditingController _categoryController;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late String _selectedReminder;
  late List<bool> _selectedDays;
  final List<String> _dayNames = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
  final List<String> _reminderOptions = [
    'Ninguno', '5 minutos antes', '10 minutos antes', '15 minutos antes',
    '20 minutos antes', '30 minutos antes', '45 minutos antes', '1 hora antes',
    'Personalizado',
  ];

  // Colores del Tema (sin cambios)
  static const Color primaryColor = Color.fromARGB(255, 55, 78, 107);
  static const Color backgroundColor = Color.fromARGB(255, 232, 232, 232);
  static const Color cardColor = Color.fromARGB(255, 212, 212, 212);
  static const Color whiteCardColor = Color.fromARGB(255, 212, 212, 212);
  static const Color darkTextColor = Color.fromARGB(255, 55, 78, 107);
  static const Color textColor = Color.fromARGB(255, 59, 59, 59);
  static const Color secondaryTextColor = Color.fromARGB(255, 59, 59, 59);

  @override
  void initState() {
    super.initState();
    // Lógica de initState para parsear datos (sin cambios)
    _titleController = TextEditingController(text: widget.task.title);
    _noteController = TextEditingController(text: widget.task.note);
    _selectedDate = widget.task.dueDate;
    _selectedTime = TimeOfDay.fromDateTime(widget.task.dueDate);

    String initialNote = widget.task.note;
    String initialCategory = '';
    if (initialNote.startsWith('Categoría: ')) {
      final parts = initialNote.split('\n\n');
      initialCategory = parts.first.replaceFirst('Categoría: ', '').trim();
      initialNote = parts.length > 1 ? parts.sublist(1).join('\n\n') : '';
    }
    _noteController = TextEditingController(text: initialNote);
    _categoryController = TextEditingController(text: initialCategory);

    _selectedReminder = widget.task.reminderInterval;
    if (!_reminderOptions.contains(_selectedReminder) && _selectedReminder != 'Ninguno') {
      // Valor personalizado
    }

    _selectedDays = List.filled(7, false);
    final String repetition = widget.task.repetitionFrequency;
    if (repetition == 'Diariamente') {
      _selectedDays = List.filled(7, true);
    } else if (repetition == 'Entre semana') {
      _selectedDays = [true, true, true, true, true, false, false];
    }else if (repetition == 'Fines de semana') {
      _selectedDays = [false, false, false, false, false, true, true];
    }else if (repetition.startsWith('Semanal: ')) {
      final days = repetition.replaceFirst('Semanal: ', '').split(', ');
      for (var day in days) {
        final index = _dayNames.indexOf(day);
        if (index != -1) _selectedDays[index] = true;
      }
    }
  }

  @override
  void dispose() {
    // Lógica de dispose (sin cambios)
    _titleController.dispose();
    _noteController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  // --- Funciones de Selección (sin cambios) ---
  Future<void> _selectDate(BuildContext context) async {
    // ... (código igual)
     final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime(2101),
      locale: const Locale('es', 'ES'), // Pone calendario en español
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
      setState(() { _selectedDate = picked; });
    }
  }


    // (Dentro de la clase _EditTaskScreenState)

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
                      fillColor: const Color.fromARGB(255, 114, 193, 243).withAlpha(200), // Usa tu color primario
                      color: const Color.fromARGB(255, 52, 73, 98),
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
  
// FUNCIÓN _selectTime MODIFICADA para estilo estándar con acento azul claro


  Future<void> _showOptionSelector(BuildContext context, List<String> options, String current, Function(String) onSelect) async {
    // ... (código igual)
     final String? selected = await showModalBottomSheet<String>(
      context: context,
      builder: (BuildContext context) { /* ... ListTile ... */
         return Container( color: cardColor, child: Column( mainAxisSize: MainAxisSize.min, children: options.map((String option) {
            return ListTile( title: Text(option, style: TextStyle(color: current == option ? primaryColor : textColor)),
              onTap: () { Navigator.pop(context, option); });
          }).toList()));
       });
    if (selected != null) onSelect(selected);
  }

  Future<void> _showCustomReminderDialog() async {
    // ... (código igual)
      final TextEditingController reminderController = TextEditingController();
      final String? minutes = await showDialog<String>( context: context, builder: (context) {
        return AlertDialog( backgroundColor: cardColor, title: const Text('Recordatorio Personalizado', style: TextStyle(color: textColor)),
          content: TextField( controller: reminderController, keyboardType: TextInputType.number, autofocus: true, style: const TextStyle(color: textColor),
            decoration: InputDecoration( hintText: 'Minutos antes', hintStyle: TextStyle(color: secondaryTextColor.withAlpha(150)))),
          actions: [
            TextButton( child: const Text('Cancelar', style: TextStyle(color: secondaryTextColor)), onPressed: () => Navigator.pop(context)),
            TextButton( child: const Text('Aceptar', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
              onPressed: () { Navigator.pop(context, reminderController.text); }),
          ]);
       });
    if (minutes != null && minutes.isNotEmpty) {
      final int? min = int.tryParse(minutes);
      if (min != null && min > 0) { setState(() { _selectedReminder = '$min minutos antes'; }); }
    }
  }

  // --- Helper de Repetición (sin cambios) ---
  String _getRepetitionString() {
    // ... (código igual)
     final List<String> chosenDays = []; int selectedCount = 0;
    for (int i = 0; i < _selectedDays.length; i++) { if (_selectedDays[i]) { chosenDays.add(_dayNames[i]); selectedCount++; }}
    if (selectedCount == 0) {
      return 'Ninguno';
    } else if (selectedCount == 7) {
      return 'Diariamente';
    }else if (selectedCount == 5 && !_selectedDays[5] && !_selectedDays[6]) {
      return 'Entre semana';
    }else if (selectedCount == 2 && _selectedDays[5] && _selectedDays[6]) {return 'Fines de semana';
    } else {
      return 'Semanal: ${chosenDays.join(', ')}';
    }
  }

  // --- Función para guardar la tarea (ACTUALIZADA) ---
  void _updateTask() {
    // ... (Lógica interna sin cambios, devuelve 'key')
      if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar( const SnackBar(content: Text('¡Oye! El título de la tarea es obligatorio.')));
      return;
    }
    final updatedDueDate = DateTime( _selectedDate.year, _selectedDate.month, _selectedDate.day, _selectedTime.hour, _selectedTime.minute );
    String note = _noteController.text;
    if (_categoryController.text.isNotEmpty) { note = "Categoría: ${_categoryController.text}\n\n${_noteController.text}"; }
    final String repetition = _getRepetitionString();
    final updatedTask = Task(
      title: _titleController.text, note: note, dueDate: updatedDueDate, color: widget.task.color, // Mantiene color original
      isCompleted: widget.task.isCompleted, reminderInterval: _selectedReminder, repetitionFrequency: repetition );
    Navigator.pop(context, { 'task': updatedTask, 'key': widget.taskKey }); // Devuelve key
  }

  @override
  Widget build(BuildContext context) {
    // final Color primaryColor = Colors.indigo.shade700; // Usa el static const definido antes

    return Scaffold(
      backgroundColor: backgroundColor,
      // ⬅️ CAMBIO: AppBar estilo AddTaskScreen
      appBar: AppBar(
        title: null, // Sin título
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: Padding( // Botón Back circular
          padding: const EdgeInsets.only(left: 10.0, top: 5.0),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40, height: 40,
              decoration: const BoxDecoration(color: cardColor, shape: BoxShape.circle),
              child: const Icon(Icons.arrow_back_ios_new, color: textColor, size: 20),
            ),
          ),
        ),
        actions: [ // Botón Check circular
          Padding(
            padding: const EdgeInsets.only(right: 15.0, top: 5.0),
            child: GestureDetector(
              onTap: _updateTask, // Llama a la función de guardar/actualizar
              child: Container(
                width: 40, height: 40,
                decoration: const BoxDecoration(color: cardColor, shape: BoxShape.circle),
                child: const Icon(Icons.check, color: primaryColor, size: 25),
              ),
            ),
          ),
        ],
      ),
      // ⬅️ CAMBIO: Body es solo SingleChildScrollView
      body: SingleChildScrollView(
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
             // ⬅️ NUEVO: Título "Editar Tarea" centrado en el body
            const Center(
              child: Text(
                'Editar Tarea',
                style: TextStyle(
                  color: textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 30),

            // 1. CAMPOS DE TEXTO (Título y Nota)
            _buildCombinedInputCard(
              titleController: _titleController,
              noteController: _noteController,
              cardColor: cardColor,
            ),
            const SizedBox(height: 30),

            // 2. CAMPO DE CATEGORÍA
            _buildCategoryInput(
              categoryController: _categoryController,
              cardColor: whiteCardColor,
            ),
            const SizedBox(height: 30),

            // 3. SELECTOR DE FECHA
            _buildSelectorCard(
              title: 'Fecha',
              value: DateFormat('dd MMMM, yyyy', 'es').format(_selectedDate), // Formato más legible
              icon: Icons.calendar_today,
              onTap: () => _selectDate(context),
              cardColor: whiteCardColor,
              primaryColor: darkTextColor,
              secondaryColor: primaryColor, // Color azul para valor
            ),
            const SizedBox(height: 15),

            // 4. SELECTOR DE HORA
            _buildSelectorCard(
              title: 'Hora',
              value: _selectedTime.format(context),
              icon: Icons.access_time,
              onTap: () => _selectTime(context),
              cardColor: whiteCardColor,
              primaryColor: darkTextColor,
              secondaryColor: darkTextColor, // Mantenemos color oscuro aquí
            ),
            const SizedBox(height: 15),

            // 5. SELECTOR DE RECORDAR
            _buildSelectorCard(
              title: 'Recordar',
              value: _selectedReminder, // Muestra el valor actual
              icon: Icons.notifications_active,
              onTap: () {
                _showOptionSelector(context, _reminderOptions, _selectedReminder, (value) {
                  if (value == 'Personalizado'){

                  _showCustomReminderDialog();
                }
                else{
                  setState(() => _selectedReminder = value);
              }});
              },
              cardColor: whiteCardColor,
              primaryColor: darkTextColor,
              secondaryColor: primaryColor, // Color azul para valor
            ),
            const SizedBox(height: 15),

            // 6. SELECTOR DE REPETIR
            _buildRepetitionSelector(),
            const SizedBox(height: 30),

             // 7. ⬅️ ELIMINADO: El botón de actualizar ya está en la AppBar
             //    y el logo ya no está aquí.
          ],
        ),
      ),
    );
  }

  // --- Widgets Auxiliares (Sin cambios en su lógica interna) ---
  // (Solo se ajustaron colores/formatos en la llamada a _buildSelectorCard)

  Widget _buildSelectorCard({ /* ... (código sin cambios) ... */
    required String title, required String value, required IconData icon, required VoidCallback onTap,
    required Color cardColor, required Color primaryColor, required Color secondaryColor,
  }) {
    final bool isCustomReminder = (title == 'Recordar' && !_reminderOptions.contains(value) && value != 'Ninguno');
    final String displayValue = isCustomReminder ? 'Personalizado' : value;
    return GestureDetector( onTap: onTap, child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        decoration: BoxDecoration( color: cardColor, borderRadius: BorderRadius.circular(15)),
        child: Row( children: [
            Icon(icon, color: primaryColor), const SizedBox(width: 15),
            Text(title, style: TextStyle(fontSize: 16, color: primaryColor, fontWeight: FontWeight.bold)),
            const Spacer(),
            if (isCustomReminder) Padding( padding: const EdgeInsets.only(right: 8.0), child: Text( value, style: TextStyle(
                  fontSize: 16, color: secondaryColor, fontWeight: FontWeight.bold))),
            Text( isCustomReminder ? '' : displayValue, style: TextStyle(
                fontSize: 16, color: secondaryColor, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Transform.rotate( angle: -45 * (3.1415926535 / 180), child: Icon(Icons.arrow_right_alt, color: secondaryColor, size: 25)),
        ])));
  }

  Widget _buildRepetitionSelector() { /* ... (código sin cambios) ... */
     return Container( padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      decoration: BoxDecoration( color: whiteCardColor, borderRadius: BorderRadius.circular(15)),
      child: Column( crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row( children: [ const Icon(Icons.repeat, color: darkTextColor), const SizedBox(width: 15),
              const Text( 'Repetir', style: TextStyle(fontSize: 16, color: darkTextColor, fontWeight: FontWeight.bold))]),
          const SizedBox(height: 15),
          Row( mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              _buildShortcutButton('Entre semana', () { setState(() => _selectedDays = [true, true, true, true, true, false, false]); }),
              _buildShortcutButton('Fines de semana', () { setState(() => _selectedDays = [false, false, false, false, false, true, true]); }),
              _buildShortcutButton('Todos los días', () { setState(() => _selectedDays = List.filled(7, true)); }),
          ]), const SizedBox(height: 10),
          Divider(color: secondaryTextColor.withAlpha(76)), const SizedBox(height: 10),
          Center( child: ToggleButtons(
              isSelected: _selectedDays, onPressed: (int index) { setState(() { _selectedDays[index] = !_selectedDays[index]; }); },
              fillColor: primaryColor.withAlpha(200), selectedColor: Colors.white, color: primaryColor,
              borderRadius: BorderRadius.circular(10), constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              children: _dayNames.map((day) => Text(day, style: const TextStyle(fontWeight: FontWeight.bold))).toList()))]));
   }

  Widget _buildShortcutButton(String text, VoidCallback onPressed) { /* ... (código sin cambios) ... */
     return ElevatedButton( onPressed: onPressed, style: ElevatedButton.styleFrom(
        backgroundColor: cardColor, foregroundColor: primaryColor, elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(horizontal: 10)),
      child: Text(text, style: const TextStyle(fontSize: 12)));
   }

  Widget _buildCombinedInputCard({ /* ... (código sin cambios) ... */
    required TextEditingController titleController, required TextEditingController noteController, required Color cardColor }) {
    const TextStyle labelStyle = TextStyle( color: secondaryTextColor, fontSize: 16, fontWeight: FontWeight.w700);
    return Container( padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration( color: cardColor, borderRadius: BorderRadius.circular(15)),
      child: Column( crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Título', style: labelStyle),
          TextField( controller: titleController, style: const TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold), cursorColor: primaryColor,
            decoration: InputDecoration( hintText: 'Escribe el título...', hintStyle: TextStyle(color: secondaryTextColor.withAlpha(127)),
              border: InputBorder.none, contentPadding: const EdgeInsets.only(top: 5, bottom: 5))),
          Divider(color: secondaryTextColor.withAlpha(76), height: 20),
          const Text('Descripción', style: labelStyle),
          TextField( controller: noteController, maxLines: 4, style: const TextStyle(color: textColor, fontSize: 16), cursorColor: primaryColor,
            decoration: InputDecoration( hintText: 'Escribe algunos detalles...', hintStyle: TextStyle(color: secondaryTextColor.withAlpha(127)),
              border: InputBorder.none, contentPadding: const EdgeInsets.only(top: 5, bottom: 5))),
      ]));
  }

  Widget _buildCategoryInput({ /* ... (código sin cambios) ... */
    required TextEditingController categoryController, required Color cardColor }
    )
     {
    const TextStyle labelStyle = TextStyle( 
      color: secondaryTextColor, 
      fontSize: 16, 
      fontWeight: FontWeight.w700
      );
    return Container( 
      padding: const EdgeInsets.symmetric(
        horizontal: 20, 
        vertical: 15
        ),
      decoration: BoxDecoration( color: cardColor, borderRadius: BorderRadius.circular(15)),
      child: Column( crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Categoría', style: labelStyle),
          TextField( controller: categoryController, style: const TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold), cursorColor: primaryColor,
            decoration: InputDecoration( hintText: 'Ej: Escuela, Trabajo, Hogar...', hintStyle: TextStyle(color: secondaryTextColor.withAlpha(127)),
              border: InputBorder.none, contentPadding: const EdgeInsets.only(top: 5, bottom: 5))),
      ]));
  }
}