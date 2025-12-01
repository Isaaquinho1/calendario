import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/task.dart';
import '../utils/notification_service.dart';
import 'package:audioplayers/audioplayers.dart';

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
  // Controladores y variables de estado
  late TextEditingController _titleController;
  late TextEditingController _noteController;
  late TextEditingController _categoryController;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late int _selectedReminderMinutes;
  late String _selectedAlarmTone;

  late List<bool> _selectedDays;

  final AudioPlayer _audioPlayer = AudioPlayer();

  final List<String> _dayNames = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

  late TextEditingController _customMinutesController;
  // ignore: unused_field
  final bool _showCustomInput = false;

  // Opciones de Recordatorio
  final List<Map<String, dynamic>> _reminderOptions = [
    {'minutes': 0, 'text': 'Ninguno'},
    {'minutes': 5, 'text': '5 minutos antes'},
    {'minutes': 10, 'text': '10 minutos antes'},
    {'minutes': 15, 'text': '15 minutos antes'},
    {'minutes': 20, 'text': '20 minutos antes'},
    {'minutes': 30, 'text': '30 minutos antes'},
    {'minutes': 45, 'text': '45 minutos antes'},
    {'minutes': 60, 'text': '1 hora antes'},
    {'minutes': 120, 'text': '2 horas antes'},
    {'minutes': -1, 'text': 'Personalizado'},
  ];

  final List<Map<String, dynamic>> _alarmToneOptions = [
    {
      'value': 'tono_1',
      'text': 'Tono Clásico',
      'icon': Icons.music_note,
      'color': Colors.blue,
      'sound': 'sounds/classic_tone.mp3',
    },
    {
      'value': 'tono_2',
      'text': 'Tono Urgente',
      'icon': Icons.notification_important,
      'color': Colors.red,
      'sound': 'sounds/urgent_tone.mp3',
    },
    {
      'value': 'tono_3',
      'text': 'Tono Moderno',
      'icon': Icons.audiotrack,
      'color': Colors.green,
      'sound': 'sounds/modern_tone.mp3',
    },
  ];

  // Colores del Tema
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

    _selectedReminderMinutes = widget.task.reminderMinutes;
    _selectedAlarmTone = widget.task.alarmTone;

    if (!_alarmToneOptions.any((tone) => tone['value'] == _selectedAlarmTone)) {
      _selectedAlarmTone = _alarmToneOptions[0]['value'];
    }

    _titleController = TextEditingController(text: widget.task.title);
    _selectedDate = widget.task.dueDate;
    _selectedTime = TimeOfDay(
      hour: widget.task.timeHour,
      minute: widget.task.timeMinute,
    );

    _customMinutesController = TextEditingController();

    // Parsear categoría y nota
    String initialNote = widget.task.note;
    String initialCategory = '';
    if (initialNote.startsWith('Categoría: ')) {
      final parts = initialNote.split('\n\n');
      initialCategory = parts.first.replaceFirst('Categoría: ', '').trim();
      initialNote = parts.length > 1 ? parts.sublist(1).join('\n\n') : '';
    }
    _noteController = TextEditingController(text: initialNote);
    _categoryController = TextEditingController(text: initialCategory);

    // Inicializar días seleccionados
    _selectedDays = List.filled(7, false);

    // 1. Intentar leer la lista de enteros (formato nuevo)
    // ignore: unnecessary_null_comparison
    if (widget.task.repeatDays != null && widget.task.repeatDays.isNotEmpty) {
      for (int day in widget.task.repeatDays) {
        if (day >= 1 && day <= 7) {
          _selectedDays[day - 1] = true;
        }
      }
    } else {
      // 2. Fallback al formato antiguo (string)
      final String repetition = widget.task.repetitionFrequency;
      if (repetition == 'Diariamente') {
        _selectedDays = List.filled(7, true);
      } else if (repetition == 'Entre semana') {
        _selectedDays = [true, true, true, true, true, false, false];
      } else if (repetition == 'Fines de semana') {
        _selectedDays = [false, false, false, false, false, true, true];
      } else if (repetition.startsWith('Semanal: ')) {
        final days = repetition.replaceFirst('Semanal: ', '').split(', ');
        for (var day in days) {
          final index = _dayNames.indexOf(day);
          if (index != -1) _selectedDays[index] = true;
        }
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    _categoryController.dispose();
    _customMinutesController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  // --- Funciones de Selección ---

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime(2101),
      locale: const Locale('es', 'ES'),
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
    int tempHour24 = _selectedTime.hour;
    int tempMinute = _selectedTime.minute;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        final screenHeight = MediaQuery.of(context).size.height;
        final screenWidth = MediaQuery.of(context).size.width;
        final isSmallScreen = screenWidth < 360;

        bool isPM = tempHour24 >= 12;
        int displayHour = tempHour24 % 12;
        if (displayHour == 0) displayHour = 12;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: screenHeight * 0.5,
              decoration: const BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                    decoration: BoxDecoration(
                      // ignore: deprecated_member_use
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(25),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Seleccionar Hora',
                          style: TextStyle(
                            color: textColor,
                            fontSize: isSmallScreen ? 18 : 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            color: textColor,
                            size: isSmallScreen ? 20 : 24,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: screenWidth * 0.25,
                          child: CupertinoPicker(
                            itemExtent: 50,
                            diameterRatio: 1.5,
                            scrollController: FixedExtentScrollController(
                              initialItem: displayHour - 1,
                            ),
                            onSelectedItemChanged: (int index) {
                              int newDisplayHour = index + 1;
                              if (isPM) {
                                tempHour24 = (newDisplayHour == 12)
                                    ? 12
                                    : newDisplayHour + 12;
                              } else {
                                tempHour24 = (newDisplayHour == 12)
                                    ? 0
                                    : newDisplayHour;
                              }
                            },
                            children: List.generate(
                              12,
                              (index) => Center(
                                child: Text(
                                  (index + 1).toString().padLeft(2, '0'),
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: isSmallScreen ? 20 : 24,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Text(
                          ':',
                          style: TextStyle(
                            color: textColor,
                            fontSize: isSmallScreen ? 24 : 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(
                          width: screenWidth * 0.25,
                          child: CupertinoPicker(
                            itemExtent: 50,
                            diameterRatio: 1.5,
                            scrollController: FixedExtentScrollController(
                              initialItem: tempMinute,
                            ),
                            looping: true,
                            onSelectedItemChanged: (int index) {
                              tempMinute = index;
                            },
                            children: List.generate(
                              60,
                              (index) => Center(
                                child: Text(
                                  index.toString().padLeft(2, '0'),
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: isSmallScreen ? 20 : 24,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: screenWidth * 0.25,
                          child: CupertinoPicker(
                            itemExtent: 50,
                            diameterRatio: 1.5,
                            scrollController: FixedExtentScrollController(
                              initialItem: isPM ? 1 : 0,
                            ),
                            onSelectedItemChanged: (int index) {
                              setModalState(() {
                                isPM = index == 1;
                                int currentDisplayHour = tempHour24 % 12;
                                if (currentDisplayHour == 0)
                                  // ignore: curly_braces_in_flow_control_structures
                                  currentDisplayHour = 12;
                                if (isPM) {
                                  tempHour24 = (currentDisplayHour == 12)
                                      ? 12
                                      : currentDisplayHour + 12;
                                } else {
                                  tempHour24 = (currentDisplayHour == 12)
                                      ? 0
                                      : currentDisplayHour;
                                }
                              });
                            },
                            children: const [
                              Center(
                                child: Text(
                                  'AM',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Center(
                                child: Text(
                                  'PM',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: cardColor,
                              foregroundColor: textColor,
                              padding: EdgeInsets.symmetric(
                                vertical: isSmallScreen ? 12 : 15,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                                side: const BorderSide(color: primaryColor),
                              ),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'CANCELAR',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 14 : 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: isSmallScreen ? 10 : 15),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                vertical: isSmallScreen ? 12 : 15,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            onPressed: () {
                              setState(() {
                                _selectedTime = TimeOfDay(
                                  hour: tempHour24,
                                  minute: tempMinute,
                                );
                              });
                              Navigator.pop(context);
                            },
                            child: Text(
                              'ACEPTAR',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 14 : 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _playAlarmTone(String soundPath) async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource(soundPath));
    } catch (e) {
      // ignore: avoid_print
      print('Error reproduciendo sonido: $e');
    }
  }

  Future<void> _showReminderSelector(BuildContext context) async {
    int tempSelectedMinutes = _selectedReminderMinutes;
    bool showCustomInput = false;

    if (!_reminderOptions.any((opt) => opt['minutes'] == tempSelectedMinutes) &&
        tempSelectedMinutes != 0) {
      showCustomInput = true;
      _customMinutesController.text = tempSelectedMinutes.toString();
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        final screenHeight = MediaQuery.of(context).size.height;
        final screenWidth = MediaQuery.of(context).size.width;
        final isSmallScreen = screenWidth < 360;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: screenHeight * (showCustomInput ? 0.5 : 0.6),
              decoration: const BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                    decoration: BoxDecoration(
                      // ignore: deprecated_member_use
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(25),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          showCustomInput
                              ? 'Recordatorio Personalizado'
                              : 'Seleccionar Recordatorio',
                          style: TextStyle(
                            color: textColor,
                            fontSize: isSmallScreen ? 18 : 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            color: textColor,
                            size: isSmallScreen ? 20 : 24,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  if (showCustomInput) ...[
                    Padding(
                      padding: EdgeInsets.all(isSmallScreen ? 20 : 25),
                      child: Column(
                        children: [
                          Text(
                            'Ingresa los minutos de anticipación:',
                            style: TextStyle(
                              color: textColor,
                              fontSize: isSmallScreen ? 16 : 18,
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _customMinutesController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: 'Ej: 25, 40, 90...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 18 : 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Nota: Ingresa solo números (mínimo 1 minuto)',
                            style: TextStyle(
                              color: secondaryTextColor,
                              fontSize: isSmallScreen ? 12 : 14,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: FixedExtentScrollController(
                          initialItem: _reminderOptions.indexWhere(
                            (option) =>
                                option['minutes'] == _selectedReminderMinutes,
                          ),
                        ),
                        itemExtent: 60,
                        diameterRatio: 1.5,
                        onSelectedItemChanged: (int index) {
                          final selectedOption = _reminderOptions[index];
                          if (selectedOption['minutes'] == -1) {
                            setModalState(() {
                              showCustomInput = true;
                            });
                          } else {
                            tempSelectedMinutes = selectedOption['minutes'];
                          }
                        },
                        children: _reminderOptions.map((option) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  option['text'],
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: isSmallScreen ? 18 : 20,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (option['minutes'] > 0)
                                  Text(
                                    'Recordatorio ${option['minutes']} min antes',
                                    style: TextStyle(
                                      color: secondaryTextColor,
                                      fontSize: isSmallScreen ? 12 : 14,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                  Padding(
                    padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                    child: Row(
                      children: [
                        if (showCustomInput) ...[
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: cardColor,
                                foregroundColor: textColor,
                                padding: EdgeInsets.symmetric(
                                  vertical: isSmallScreen ? 12 : 15,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  side: const BorderSide(color: primaryColor),
                                ),
                              ),
                              onPressed: () {
                                setModalState(() {
                                  showCustomInput = false;
                                  _customMinutesController.clear();
                                });
                              },
                              child: Text(
                                'ATRÁS',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 14 : 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: isSmallScreen ? 10 : 15),
                        ] else ...[
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: cardColor,
                                foregroundColor: textColor,
                                padding: EdgeInsets.symmetric(
                                  vertical: isSmallScreen ? 12 : 15,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  side: const BorderSide(color: primaryColor),
                                ),
                              ),
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                'CANCELAR',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 14 : 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: isSmallScreen ? 10 : 15),
                        ],
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                vertical: isSmallScreen ? 12 : 15,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            onPressed: () {
                              if (showCustomInput) {
                                final customMinutes =
                                    int.tryParse(
                                      _customMinutesController.text,
                                    ) ??
                                    0;
                                if (customMinutes > 0) {
                                  tempSelectedMinutes = customMinutes;
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Por favor ingresa un número válido mayor a 0',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }
                              }
                              setState(() {
                                _selectedReminderMinutes = tempSelectedMinutes;
                              });
                              Navigator.pop(context);
                            },
                            child: Text(
                              'ACEPTAR',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 14 : 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showAlarmToneSelector(BuildContext context) async {
    String tempSelectedTone = _selectedAlarmTone;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        final screenHeight = MediaQuery.of(context).size.height;
        final screenWidth = MediaQuery.of(context).size.width;
        final isSmallScreen = screenWidth < 360;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: screenHeight * 0.7,
              decoration: const BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                    decoration: BoxDecoration(
                      // ignore: deprecated_member_use
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(25),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Seleccionar Tono de Alarma',
                          style: TextStyle(
                            color: textColor,
                            fontSize: isSmallScreen ? 18 : 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            color: textColor,
                            size: isSmallScreen ? 20 : 24,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 16 : 20,
                      vertical: 10,
                    ),
                    child: Text(
                      'Toca un tono para escucharlo',
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: isSmallScreen ? 14 : 16,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 10 : 15,
                        vertical: 10,
                      ),
                      itemCount: _alarmToneOptions.length,
                      itemBuilder: (context, index) {
                        final tone = _alarmToneOptions[index];
                        final isSelected = tempSelectedTone == tone['value'];

                        return Card(
                          margin: EdgeInsets.symmetric(
                            vertical: isSmallScreen ? 5 : 8,
                            horizontal: isSmallScreen ? 5 : 10,
                          ),
                          color: isSelected
                              // ignore: deprecated_member_use
                              ? primaryColor.withOpacity(0.2)
                              : cardColor,
                          elevation: 2,
                          child: ListTile(
                            leading: Container(
                              padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                              decoration: BoxDecoration(
                                // ignore: deprecated_member_use
                                color: tone['color'].withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                tone['icon'],
                                color: tone['color'],
                                size: isSmallScreen ? 20 : 24,
                              ),
                            ),
                            title: Text(
                              tone['text'],
                              style: TextStyle(
                                color: textColor,
                                fontSize: isSmallScreen ? 16 : 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.play_arrow,
                                    color: primaryColor,
                                    size: isSmallScreen ? 20 : 24,
                                  ),
                                  onPressed: () =>
                                      _playAlarmTone(tone['sound']),
                                ),
                                if (isSelected)
                                  Icon(
                                    Icons.check_circle,
                                    color: primaryColor,
                                    size: isSmallScreen ? 20 : 24,
                                  ),
                              ],
                            ),
                            onTap: () {
                              _playAlarmTone(tone['sound']);
                              setModalState(() {
                                tempSelectedTone = tone['value'];
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: cardColor,
                              foregroundColor: textColor,
                              padding: EdgeInsets.symmetric(
                                vertical: isSmallScreen ? 12 : 15,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                                side: const BorderSide(color: primaryColor),
                              ),
                            ),
                            onPressed: () {
                              _audioPlayer.stop();
                              Navigator.pop(context);
                            },
                            child: Text(
                              'CANCELAR',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 14 : 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: isSmallScreen ? 10 : 15),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                vertical: isSmallScreen ? 12 : 15,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            onPressed: () {
                              _audioPlayer.stop();
                              setState(() {
                                _selectedAlarmTone = tempSelectedTone;
                              });
                              Navigator.pop(context);
                            },
                            child: Text(
                              'ACEPTAR',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 14 : 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- Funciones de Ayuda ---

  String _getSelectedReminderText() {
    if (_selectedReminderMinutes == 0) {
      return 'Ninguno';
    }
    final predefinedOption = _reminderOptions.firstWhere(
      (option) => option['minutes'] == _selectedReminderMinutes,
      orElse: () => {'text': 'Personalizado'},
    );
    if (predefinedOption['text'] != 'Personalizado') {
      return predefinedOption['text'];
    } else {
      return '$_selectedReminderMinutes minutos antes';
    }
  }

  String _getSelectedAlarmToneText() {
    final option = _alarmToneOptions.firstWhere(
      (option) => option['value'] == _selectedAlarmTone,
      orElse: () => _alarmToneOptions[0],
    );
    return option['text'];
  }

  String _getReminderDescription() {
    if (_selectedReminderMinutes == 0) {
      return 'Solo sonará la alarma fuerte en la hora exacta';
    } else {
      return 'Sonido suave $_selectedReminderMinutes minutos antes y alarma fuerte en la hora exacta';
    }
  }

  String _getAlarmToneDescription() {
    return 'Sonido que se reproducirá cuando sea la hora exacta de la tarea';
  }

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
    } else if (selectedCount == 5 && !_selectedDays[5] && !_selectedDays[6]) {
      return 'Entre semana';
    } else if (selectedCount == 2 && _selectedDays[5] && _selectedDays[6]) {
      return 'Fines de semana';
    } else {
      return 'Semanal: ${chosenDays.join(', ')}';
    }
  }

  Future<void> _showUpdateSuccessDialog(Task updatedTask) async {
    final navigator = Navigator.of(context);
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        Future.delayed(const Duration(seconds: 2, milliseconds: 500), () {
          if (mounted) {
            // ignore: use_build_context_synchronously
            Navigator.pop(dialogContext);
            navigator.pop({'task': updatedTask, 'key': widget.taskKey});
          }
        });
        return Dialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(25.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  'assets/foquito.svg',
                  height: 120,
                  placeholderBuilder: (context) => const Icon(
                    Icons.check_circle_outline,
                    size: 100,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  '¡Tarea Editada!',
                  style: TextStyle(
                    color: darkTextColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  '"${updatedTask.title}"',
                  style: const TextStyle(color: textColor, fontSize: 16),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _updateTask() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Oye! El título de la tarea es obligatorio.'),
        ),
      );
      return;
    }

    final updatedDueDate = _selectedDate;
    final updatedTime = _selectedTime;

    final scheduledDateTime = DateTime(
      updatedDueDate.year,
      updatedDueDate.month,
      updatedDueDate.day,
      updatedTime.hour,
      updatedTime.minute,
    );

    if (scheduledDateTime.isBefore(
      DateTime.now().subtract(const Duration(minutes: 1)),
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Oops! No puedes programar tareas en el pasado.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    String note = _noteController.text;
    if (_categoryController.text.isNotEmpty) {
      note =
          "Categoría: ${_categoryController.text}\n\n${_noteController.text}";
    }

    List<int> daysToRepeat = [];
    for (int i = 0; i < 7; i++) {
      if (_selectedDays[i]) {
        daysToRepeat.add(i + 1);
      }
    }

    final updatedTask = Task(
      title: _titleController.text,
      note: note,
      dueDate: updatedDueDate,
      color: widget.task.color,
      isCompleted: widget.task.isCompleted,
      repetitionFrequency: _getRepetitionString(),
      reminderMinutes: _selectedReminderMinutes,
      timeHour: updatedTime.hour,
      timeMinute: updatedTime.minute,
      alarmTone: _selectedAlarmTone,
      key: widget.task.key,
      repeatDays: daysToRepeat,
    );

    final Box<Task> taskBox;
    if (Hive.isBoxOpen('tasks')) {
      taskBox = Hive.box<Task>('tasks');
    } else {
      taskBox = await Hive.openBox<Task>('tasks');
    }

    await taskBox.put(widget.taskKey, updatedTask);

    await NotificationService.cancelTaskNotifications(widget.task);
    await NotificationService.scheduleTaskNotifications(updatedTask);

    if (!mounted) return;
    await _showUpdateSuccessDialog(updatedTask);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 360;
    final isLargeScreen = screenWidth > 400;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: null,
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: Padding(
          padding: EdgeInsets.only(left: isSmallScreen ? 12.0 : 16.0, top: 8.0),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: isSmallScreen ? 40 : 44,
              height: isSmallScreen ? 40 : 44,
              decoration: const BoxDecoration(
                color: cardColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                color: textColor,
                size: isSmallScreen ? 18 : 22,
              ),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(
              right: isSmallScreen ? 12.0 : 16.0,
              top: 8.0,
            ),
            child: GestureDetector(
              onTap: _updateTask,
              child: Container(
                width: isSmallScreen ? 40 : 44,
                height: isSmallScreen ? 40 : 44,
                decoration: const BoxDecoration(
                  color: cardColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  color: primaryColor,
                  size: isSmallScreen ? 22 : 26,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isSmallScreen ? 18.0 : 22.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: SizedBox(
                  height: screenHeight * 0.12,
                  width: screenWidth * 0.3,
                  child: SvgPicture.asset(
                    'assets/timido.svg',
                    fit: BoxFit.contain,
                    placeholderBuilder: (context) => const Icon(
                      Icons.image_not_supported,
                      size: 50,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.025),
              Center(
                child: Text(
                  'Editar Tarea',
                  style: TextStyle(
                    color: textColor,
                    fontSize: isSmallScreen
                        ? 20
                        : isLargeScreen
                        ? 24
                        : 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.035),
              _buildCombinedInputCard(
                titleController: _titleController,
                noteController: _noteController,
                cardColor: cardColor,
                isSmallScreen: isSmallScreen,
              ),
              SizedBox(height: screenHeight * 0.025),
              _buildSelectorCard(
                title: 'Fecha',
                value: DateFormat('dd MMMM, yyyy', 'es').format(_selectedDate),
                icon: Icons.calendar_today,
                onTap: () => _selectDate(context),
                cardColor: whiteCardColor,
                primaryColor: darkTextColor,
                secondaryColor: primaryColor,
                isSmallScreen: isSmallScreen,
              ),
              SizedBox(height: screenHeight * 0.018),
              _buildSelectorCard(
                title: 'Hora',
                value: _selectedTime.format(context),
                icon: Icons.access_time,
                onTap: () => _selectTime(context),
                cardColor: whiteCardColor,
                primaryColor: darkTextColor,
                secondaryColor: darkTextColor,
                isSmallScreen: isSmallScreen,
              ),
              SizedBox(height: screenHeight * 0.018),
              _buildSelectorCard(
                title: 'Recordar',
                value: _getSelectedReminderText(),
                icon: Icons.notifications_active,
                onTap: () => _showReminderSelector(context),
                cardColor: whiteCardColor,
                primaryColor: darkTextColor,
                secondaryColor: primaryColor,
                isSmallScreen: isSmallScreen,
              ),
              SizedBox(height: screenHeight * 0.012),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 10.0 : 14.0,
                ),
                child: Text(
                  _getReminderDescription(),
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: isSmallScreen ? 12 : 13,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.018),
              _buildSelectorCard(
                title: 'Tono de Alarma',
                value: _getSelectedAlarmToneText(),
                icon: Icons.audiotrack,
                onTap: () => _showAlarmToneSelector(context),
                cardColor: whiteCardColor,
                primaryColor: darkTextColor,
                secondaryColor: primaryColor,
                isSmallScreen: isSmallScreen,
              ),
              SizedBox(height: screenHeight * 0.012),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 10.0 : 14.0,
                ),
                child: Text(
                  _getAlarmToneDescription(),
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: isSmallScreen ? 12 : 13,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.018),
              _buildRepetitionSelector(isSmallScreen: isSmallScreen),
              SizedBox(height: screenHeight * 0.025),
              _buildCategoryInput(
                categoryController: _categoryController,
                cardColor: whiteCardColor,
                isSmallScreen: isSmallScreen,
              ),
              SizedBox(height: screenHeight * 0.04),
            ],
          ),
        ),
      ),
    );
  }

  // --- Widgets Auxiliares Modificados ---

  Widget _buildSelectorCard({
    required String title,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
    required Color cardColor,
    required Color primaryColor,
    required Color secondaryColor,
    required bool isSmallScreen,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 14 : 18,
          vertical: isSmallScreen ? 14 : 18,
        ),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: primaryColor, size: isSmallScreen ? 22 : 26),
            SizedBox(width: isSmallScreen ? 14 : 18),
            Text(
              title,
              style: TextStyle(
                fontSize: isSmallScreen ? 15 : 17,
                color: primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: isSmallScreen ? 15 : 17,
                  color: secondaryColor,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
              ),
            ),
            SizedBox(width: isSmallScreen ? 8 : 12),
            Transform.rotate(
              angle: -45 * (3.1415926535 / 180),
              child: Icon(
                Icons.arrow_right_alt,
                color: secondaryColor,
                size: isSmallScreen ? 22 : 27,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔴 AQUÍ ESTÁ EL CAMBIO CLAVE PARA RESPONSIVIDAD 🔴
  Widget _buildRepetitionSelector({required bool isSmallScreen}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 14 : 18,
        vertical: isSmallScreen ? 14 : 18,
      ),
      decoration: BoxDecoration(
        color: whiteCardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.repeat,
                color: darkTextColor,
                size: isSmallScreen ? 22 : 26,
              ),
              SizedBox(width: isSmallScreen ? 14 : 18),
              Text(
                'Repetir',
                style: TextStyle(
                  fontSize: isSmallScreen ? 15 : 17,
                  color: darkTextColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 14 : 18),
          Wrap(
            spacing: isSmallScreen ? 8 : 12,
            runSpacing: 10,
            children: [
              _buildShortcutButton('Entre semana', () {
                setState(
                  () => _selectedDays = [
                    true,
                    true,
                    true,
                    true,
                    true,
                    false,
                    false,
                  ],
                );
              }, isSmallScreen: isSmallScreen),
              _buildShortcutButton('Fines de semana', () {
                setState(
                  () => _selectedDays = [
                    false,
                    false,
                    false,
                    false,
                    false,
                    true,
                    true,
                  ],
                );
              }, isSmallScreen: isSmallScreen),
              _buildShortcutButton('Todos los días', () {
                setState(() => _selectedDays = List.filled(7, true));
              }, isSmallScreen: isSmallScreen),
            ],
          ),
          SizedBox(height: isSmallScreen ? 10 : 14),
          Divider(color: secondaryTextColor.withAlpha(76), height: 22),
          SizedBox(height: isSmallScreen ? 10 : 14),

          // 🔴 USO DE WRAP EN LUGAR DE ROW/TOGGLEBUTTONS 🔴
          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: isSmallScreen
                  ? 8.0
                  : 12.0, // Espacio horizontal entre botones
              runSpacing: 10.0, // Espacio vertical si baja a la siguiente línea
              children: List.generate(7, (index) {
                final isSelected = _selectedDays[index];
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedDays[index] = !_selectedDays[index];
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: isSmallScreen ? 38 : 44, // Ancho fijo por botón
                    height: isSmallScreen ? 38 : 44, // Alto fijo por botón
                    decoration: BoxDecoration(
                      color: isSelected
                          ? primaryColor
                          : primaryColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(
                        12,
                      ), // Bordes redondeados
                      border: Border.all(
                        color: isSelected ? primaryColor : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _dayNames[index],
                        style: TextStyle(
                          color: isSelected ? Colors.white : textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: isSmallScreen ? 14 : 16,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutButton(
    String text,
    VoidCallback onPressed, {
    required bool isSmallScreen,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: cardColor,
        foregroundColor: primaryColor,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 10 : 12,
          vertical: isSmallScreen ? 8 : 10,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: isSmallScreen ? 11 : 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildCombinedInputCard({
    required TextEditingController titleController,
    required TextEditingController noteController,
    required Color cardColor,
    required bool isSmallScreen,
  }) {
    final TextStyle labelStyle = TextStyle(
      color: secondaryTextColor,
      fontSize: isSmallScreen ? 15 : 17,
      fontWeight: FontWeight.w700,
    );
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 18 : 22,
        vertical: isSmallScreen ? 14 : 18,
      ),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Título', style: labelStyle),
          TextField(
            controller: titleController,
            style: TextStyle(
              color: textColor,
              fontSize: isSmallScreen ? 17 : 19,
              fontWeight: FontWeight.bold,
            ),
            cursorColor: primaryColor,
            decoration: InputDecoration(
              hintText: 'Escribe el título...',
              hintStyle: TextStyle(color: secondaryTextColor.withAlpha(127)),
              border: InputBorder.none,
              contentPadding: EdgeInsets.only(top: 8, bottom: 8),
            ),
          ),
          Divider(color: secondaryTextColor.withAlpha(76), height: 22),
          Text('Descripción', style: labelStyle),
          TextField(
            controller: noteController,
            maxLines: 4,
            style: TextStyle(
              color: textColor,
              fontSize: isSmallScreen ? 15 : 17,
            ),
            cursorColor: primaryColor,
            decoration: InputDecoration(
              hintText: 'Escribe algunos detalles...',
              hintStyle: TextStyle(color: secondaryTextColor.withAlpha(127)),
              border: InputBorder.none,
              contentPadding: EdgeInsets.only(top: 8, bottom: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryInput({
    required TextEditingController categoryController,
    required Color cardColor,
    required bool isSmallScreen,
  }) {
    final TextStyle labelStyle = TextStyle(
      color: secondaryTextColor,
      fontSize: isSmallScreen ? 15 : 17,
      fontWeight: FontWeight.w700,
    );
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 18 : 22,
        vertical: isSmallScreen ? 14 : 18,
      ),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Categoría', style: labelStyle),
          TextField(
            controller: categoryController,
            style: TextStyle(
              color: textColor,
              fontSize: isSmallScreen ? 17 : 19,
              fontWeight: FontWeight.bold,
            ),
            cursorColor: primaryColor,
            decoration: InputDecoration(
              hintText: 'Ej: Escuela, Trabajo, Hogar...',
              hintStyle: TextStyle(color: secondaryTextColor.withAlpha(127)),
              border: InputBorder.none,
              contentPadding: EdgeInsets.only(top: 8, bottom: 8),
            ),
          ),
        ],
      ),
    );
  }
}
