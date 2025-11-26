import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Importar Firebase Auth
import '../models/task.dart';
import '../utils/notification_service.dart';

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
  final TextEditingController _customReminderController =
      TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Variables de estado
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  int _selectedReminderMinutes = 0;
  String _selectedAlarmTone = 'tono_1';
  // ignore: unused_field
  late bool _isPM;

  List<bool> _selectedDays = List.filled(7, false);

  // Opciones de Recordatorio con minutos
  final List<Map<String, dynamic>> _reminderOptions = [
    {'minutes': 0, 'text': 'Ninguno'},
    {'minutes': 5, 'text': '5 minutos antes'},
    {'minutes': 10, 'text': '10 minutos antes'},
    {'minutes': 15, 'text': '15 minutos antes'},
    {'minutes': 20, 'text': '20 minutos antes'},
    {'minutes': 25, 'text': '25 minutos antes'},
    {'minutes': 30, 'text': '30 minutos antes'},
    {'minutes': 45, 'text': '45 minutos antes'},
    {'minutes': 60, 'text': '1 hora antes'},
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
      'text': 'Tono Navideño',
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

  final List<String> _dayNames = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

  @override
  void initState() {
    super.initState();
    _isPM = _selectedTime.hour >= 12;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    _categoryController.dispose();
    _customReminderController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playSound(String soundPath) async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource(soundPath));
    } catch (e) {
      // ignore: avoid_print
      print('Error reproduciendo sonido: $e');
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      locale: const Locale('es', 'ES'),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: Colors.white,
              onPrimary: Colors.black,
              surface: Colors.black,
              onSurface: Colors.white,
            ),
            dialogTheme: DialogThemeData(backgroundColor: Colors.black),
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
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(25),
                ),
              ),
              child: Column(
                children: [
                  // Header
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

                  // Selectores deslizables
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Horas (1-12)
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

                        // Minutos
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

                        // AM/PM
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
                                if (currentDisplayHour == 0) {
                                  currentDisplayHour = 12;
                                }

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

                  // Botones
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
                                side: BorderSide(color: primaryColor),
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
                                _isPM = _selectedTime.hour >= 12;
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

  Future<void> _showReminderSelector(BuildContext context) async {
    int tempSelectedMinutes = _selectedReminderMinutes;
    bool showCustomInput = false;

    if (!_reminderOptions.any((opt) => opt['minutes'] == tempSelectedMinutes) &&
        tempSelectedMinutes != 0) {
      showCustomInput = true;
      _customReminderController.text = tempSelectedMinutes.toString();
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
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(25),
                ),
              ),
              child: Column(
                children: [
                  // Header
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
                    // Input personalizado
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
                          SizedBox(height: 20),
                          TextField(
                            controller: _customReminderController,
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
                          SizedBox(height: 20),
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
                    // Selector deslizable
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
                        //
                        //  INICIO DE LA CORRECCIÓN DE RECORDATORIOS DUPLICADOS
                        //
                        children: _reminderOptions.map((option) {
                          return Center(
                            child: Text(
                              option['text'], // Solo mostramos el texto principal
                              style: TextStyle(
                                color: textColor,
                                fontSize: isSmallScreen ? 18 : 20,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                        //
                        //  FIN DE LA CORRECCIÓN
                        //
                      ),
                    ),
                  ],

                  // Botones
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
                                  side: BorderSide(color: primaryColor),
                                ),
                              ),
                              onPressed: () {
                                setModalState(() {
                                  showCustomInput = false;
                                  _customReminderController.clear();
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
                                  side: BorderSide(color: primaryColor),
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

                        // Botón Aceptar
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
                                      _customReminderController.text,
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
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(25),
                ),
              ),
              child: Column(
                children: [
                  // Header
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

                  // Instrucción
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

                  // Lista deslizable de tonos
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
                                  onPressed: () => _playSound(tone['sound']),
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
                              _playSound(tone['sound']);
                              setModalState(() {
                                tempSelectedTone = tone['value'];
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),

                  // Botones
                  Padding(
                    padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                    child: Row(
                      children: [
                        // Botón Cancelar
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
                                side: BorderSide(color: primaryColor),
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

                        // Botón Aceptar
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

  // --- Funciones de Ayuda (Están bien) ---

  String _getSelectedReminderText() {
    if (_selectedReminderMinutes == 0) {
      return 'Ninguno';
    } else if (_reminderOptions.any(
      (option) => option['minutes'] == _selectedReminderMinutes,
    )) {
      final option = _reminderOptions.firstWhere(
        (option) => option['minutes'] == _selectedReminderMinutes,
      );
      return option['text'];
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

  // 1. 🔑 ESTA ES LA NUEVA FUNCIÓN PARA MOSTRAR EL DIÁLOGO DE ÉXITO
  Future<void> _showSuccessDialog(Task taskWithKey) async {
    // Guardamos el Navigator ANTES de mostrar el diálogo
    // para poder cerrar la pantalla de "Agregar" después.
    final navigator = Navigator.of(context);

    await showDialog(
      context: context,
      barrierDismissible: false, // El usuario no puede cerrarlo
      builder: (dialogContext) {
        // Programamos el cierre automático
        Future.delayed(const Duration(seconds: 2, milliseconds: 500), () {
          if (mounted) {
            Navigator.pop(dialogContext); // Cierra el diálogo
            navigator.pop(taskWithKey); // Cierra la pantalla de "Agregar"
          }
        });

        return Dialog(
          backgroundColor: cardColor, // Usando tu color de tema
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(25.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. LA IMAGEN (EXTERNA A LA CAJA DE TEXTO)
                // ‼️ Asegúrate de tener 'assets/alegre.svg' en tu pubspec.yaml
                SvgPicture.asset(
                  'assets/foquito.svg', // ¡Puedes cambiar esto por 'feliz.svg' o la que quieras!
                  height: 120,
                  placeholderBuilder: (context) => const Icon(
                    Icons.check_circle_outline,
                    size: 100,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 20),

                // 2. EL TEXTO (DENTRO DE SU "CAJA" DE DIÁLOGO)
                const Text(
                  '¡Tarea Guardada!',
                  style: TextStyle(
                    color: darkTextColor, // Usando tu color
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  '"${taskWithKey.title}"',
                  style: const TextStyle(
                    color: textColor, // Usando tu color
                    fontSize: 16,
                  ),
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

  Future<void> _saveTask() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Oye! El título de la tarea es obligatorio.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Obtener el UID del usuario actual de Firebase
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Error: No se encontró usuario. Intenta iniciar sesión de nuevo.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    final String uid = currentUser.uid;
    final String userTaskBoxName = 'tasks_$uid';

    try {
      final DateTime scheduledDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
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

      final newTask = Task(
        title: _titleController.text,
        note: note,
        dueDate: _selectedDate,
        repetitionFrequency: _getRepetitionString(),
        reminderMinutes: _selectedReminderMinutes,
        timeHour: _selectedTime.hour,
        timeMinute: _selectedTime.minute,
        alarmTone: _selectedAlarmTone,
        isCompleted: false,
      );

      // Abrir la caja específica del usuario y guardar
      final Box<Task> taskBox = await Hive.openBox<Task>(userTaskBoxName);
      final int key = await taskBox.add(newTask);

      final taskWithKey = newTask.copyWith(key: key);
      await taskBox.put(key, taskWithKey);

      await NotificationService.scheduleTaskNotifications(taskWithKey);

      if (!mounted) return;
      await _showSuccessDialog(taskWithKey);

      //
    } catch (e) {
      // ignore: avoid_print
      print('Error al guardar tarea: $e');
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ... (build principal) ...
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
          padding: EdgeInsets.only(
            left: isSmallScreen ? 12.0 : 16.0,
            top: isSmallScreen ? 8.0 : 10.0,
          ),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: isSmallScreen ? 44 : 50,
              height: isSmallScreen ? 44 : 50,
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
              top: isSmallScreen ? 8.0 : 10.0,
            ),
            child: GestureDetector(
              onTap: _saveTask,
              child: Container(
                width: isSmallScreen ? 44 : 50,
                height: isSmallScreen ? 44 : 50,
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
          padding: EdgeInsets.all(isSmallScreen ? 16.0 : 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Imagen Remy - Responsive con manejo de errores
              _buildRemyImage(isSmallScreen, screenHeight),
              SizedBox(height: screenHeight * 0.02),

              // Título Central - Responsive
              Center(
                child: Text(
                  'Agregar Nueva Tarea',
                  style: TextStyle(
                    color: textColor,
                    fontSize: isSmallScreen
                        ? 20
                        : isLargeScreen
                        ? 24
                        : 22,
                    fontWeight: FontWeight.w900,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: screenHeight * 0.03),

              // Campos de texto
              _buildCombinedInputCard(
                titleController: _titleController,
                noteController: _noteController,
                cardColor: cardColor,
                isSmallScreen: isSmallScreen,
                screenHeight: screenHeight,
              ),
              SizedBox(height: screenHeight * 0.03),

              // Selectores
              _buildSelectorCard(
                title: 'Fecha',
                value: DateFormat('dd MMMM, yyyy', 'es').format(_selectedDate),
                icon: Icons.calendar_today,
                onTap: () => _selectDate(context),
                cardColor: whiteCardColor,
                primaryColor: darkTextColor,
                secondaryColor: primaryColor,
                isSmallScreen: isSmallScreen,
                screenHeight: screenHeight,
              ),
              SizedBox(height: screenHeight * 0.015),

              _buildSelectorCard(
                title: 'Hora',
                value: _selectedTime.format(context),
                icon: Icons.access_time,
                onTap: () => _selectTime(context),
                cardColor: whiteCardColor,
                primaryColor: darkTextColor,
                secondaryColor: darkTextColor,
                isSmallScreen: isSmallScreen,
                screenHeight: screenHeight,
              ),
              SizedBox(height: screenHeight * 0.015),

              _buildSelectorCard(
                title: 'Recordar',
                value: _getSelectedReminderText(),
                icon: Icons.notifications_active,
                onTap: () => _showReminderSelector(context),
                cardColor: whiteCardColor,
                primaryColor: darkTextColor,
                secondaryColor: primaryColor,
                isSmallScreen: isSmallScreen,
                screenHeight: screenHeight,
              ),
              SizedBox(height: screenHeight * 0.01),

              // Información de recordatorio
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 12.0 : 16.0,
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
              SizedBox(height: screenHeight * 0.015),

              _buildSelectorCard(
                title: 'Tono de Alarma',
                value: _getSelectedAlarmToneText(),
                icon: Icons.audiotrack,
                onTap: () => _showAlarmToneSelector(context),
                cardColor: whiteCardColor,
                primaryColor: darkTextColor,
                secondaryColor: primaryColor,
                isSmallScreen: isSmallScreen,
                screenHeight: screenHeight,
              ),
              SizedBox(height: screenHeight * 0.01),

              // Información del tono de alarma
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 12.0 : 16.0,
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
              SizedBox(height: screenHeight * 0.02),

              // Selector de repetición
              _buildRepetitionSelector(
                isSmallScreen: isSmallScreen,
                screenHeight: screenHeight,
              ),
              SizedBox(height: screenHeight * 0.03),

              // Selector de categoría
              _buildCategoryInput(
                categoryController: _categoryController,
                cardColor: whiteCardColor,
                isSmallScreen: isSmallScreen,
                screenHeight: screenHeight,
              ),
              SizedBox(height: screenHeight * 0.05),
            ],
          ),
        ),
      ),
    );
  }

  //  WIDGET DE IMAGEN AÑADIDO
  Widget _buildRemyImage(bool isSmallScreen, double screenHeight) {
    // ‼️ REVISA QUE ESTA RUTA SEA CORRECTA EN TUS ASSETS ('pubspec.yaml')
    // Asumo que se llama 'remi3.svg' como en tu home_screen
    final String remyAssetPath = 'assets/timido.svg';

    return Container(
      height: screenHeight * 0.15, // Un tamaño de ejemplo
      alignment: Alignment.center,
      child: SvgPicture.asset(
        remyAssetPath,
        // Si la imagen no se carga o no se encuentra, muestra un icono
        placeholderBuilder: (BuildContext context) =>
            const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
      ),
    );
  }

  // --- WIDGETS AUXILIARES ---
  // (El resto de tus widgets auxiliares van aquí)

  Widget _buildSelectorCard({
    required String title,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
    required Color cardColor,
    required Color primaryColor,
    required Color secondaryColor,
    required bool isSmallScreen,
    required double screenHeight,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 16 : 20,
          vertical: isSmallScreen ? 16 : 20,
        ),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
              decoration: BoxDecoration(
                // ignore: deprecated_member_use
                color: primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: primaryColor,
                size: isSmallScreen ? 22 : 26,
              ),
            ),
            SizedBox(width: isSmallScreen ? 15 : 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 16 : 18,
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16,
                      color: secondaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: secondaryColor,
              size: isSmallScreen ? 18 : 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRepetitionSelector({
    required bool isSmallScreen,
    required double screenHeight,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16 : 20,
        vertical: isSmallScreen ? 16 : 20,
      ),
      decoration: BoxDecoration(
        color: whiteCardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                decoration: BoxDecoration(
                  // ignore: deprecated_member_use
                  color: darkTextColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.repeat,
                  color: darkTextColor,
                  size: isSmallScreen ? 20 : 24,
                ),
              ),
              SizedBox(width: isSmallScreen ? 12 : 15),
              Text(
                'Repetir',
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 18,
                  color: darkTextColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 12 : 15),

          // Botones de Atajo
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
          SizedBox(height: isSmallScreen ? 12 : 15),

          // Divisor
          Divider(color: secondaryTextColor.withAlpha(76), height: 20),
          SizedBox(height: isSmallScreen ? 12 : 15),

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
              borderRadius: BorderRadius.circular(15),
              constraints: BoxConstraints(
                minWidth: isSmallScreen ? 40 : 50,
                minHeight: isSmallScreen ? 40 : 50,
              ),
              children: _dayNames
                  .map(
                    (day) => Text(
                      day,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isSmallScreen ? 14 : 16,
                      ),
                    ),
                  )
                  .toList(),
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
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 12 : 16,
          vertical: isSmallScreen ? 10 : 12,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: isSmallScreen ? 12 : 14,
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
    required double screenHeight,
  }) {
    final TextStyle labelStyle = TextStyle(
      color: secondaryTextColor,
      fontSize: isSmallScreen ? 16 : 18,
      fontWeight: FontWeight.w700,
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16 : 20,
        vertical: isSmallScreen ? 16 : 20,
      ),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Título', style: labelStyle),
          SizedBox(height: 8),
          TextField(
            controller: titleController,
            style: TextStyle(
              color: textColor,
              fontSize: isSmallScreen ? 18 : 20,
              fontWeight: FontWeight.bold,
            ),
            cursorColor: primaryColor,
            decoration: InputDecoration(
              hintText: 'Escribe el título...',
              hintStyle: TextStyle(color: secondaryTextColor.withAlpha(127)),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          Divider(color: secondaryTextColor.withAlpha(76), height: 30),
          Text('Descripción', style: labelStyle),
          SizedBox(height: 8),
          TextField(
            controller: noteController,
            maxLines: 4,
            style: TextStyle(
              color: textColor,
              fontSize: isSmallScreen ? 16 : 18,
            ),
            cursorColor: primaryColor,
            decoration: InputDecoration(
              hintText: 'Escribe algunos detalles...',
              hintStyle: TextStyle(color: secondaryTextColor.withAlpha(127)),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 12),
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
    required double screenHeight,
  }) {
    final TextStyle labelStyle = TextStyle(
      color: secondaryTextColor,
      fontSize: isSmallScreen ? 16 : 18,
      fontWeight: FontWeight.w700,
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16 : 20,
        vertical: isSmallScreen ? 16 : 20,
      ),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Categoría', style: labelStyle),
          SizedBox(height: 8),
          TextField(
            controller: categoryController,
            style: TextStyle(
              color: textColor,
              fontSize: isSmallScreen ? 18 : 20,
              fontWeight: FontWeight.bold,
            ),
            cursorColor: primaryColor,
            decoration: InputDecoration(
              hintText: 'Ej: Escuela, Trabajo, Hogar...',
              hintStyle: TextStyle(color: secondaryTextColor.withAlpha(127)),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
