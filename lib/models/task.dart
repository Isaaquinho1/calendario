import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'task.g.dart';

@HiveType(typeId: 0)
class Task {
  @HiveField(0)
  final String title;

  @HiveField(1)
  final String note;

  @HiveField(2)
  final DateTime dueDate;

  @HiveField(3)
  final int colorValue;

  @HiveField(4)
  bool isCompleted;

  // ❌ CAMPO ELIMINADO: 'reminderInterval' (era redundante)
  // @HiveField(5)
  // final String reminderInterval;

  @HiveField(6)
  final String repetitionFrequency;

  // ✅ ÚNICA FUENTE DE VERDAD para el recordatorio
  @HiveField(7)
  final int reminderMinutes;

  @HiveField(8)
  final int timeHour;

  @HiveField(9)
  final int timeMinute;

  @HiveField(10)
  final String alarmTone;

  @HiveField(11)
  int? key;

  Task({
    required this.title,
    this.note = '',
    required this.dueDate,
    Color color = Colors.indigo,
    this.isCompleted = false,
    // this.reminderInterval = 'Ninguno', // ❌ ELIMINADO
    this.repetitionFrequency = 'Ninguno',
    this.reminderMinutes = 0,
    required this.timeHour,
    required this.timeMinute,
    this.alarmTone = 'tono_1', // ✅ CORREGIDO: Valor en minúscula
    this.key,
    // ignore: deprecated_member_use
  }) : colorValue = color.value;

  // --- Getters ---

  Color get color => Color(colorValue);

  TimeOfDay get time => TimeOfDay(hour: timeHour, minute: timeMinute);

  DateTime get scheduledDateTime {
    return DateTime(
      dueDate.year,
      dueDate.month,
      dueDate.day,
      timeHour,
      timeMinute,
    );
  }

  DateTime get reminderDateTime {
    return scheduledDateTime.subtract(Duration(minutes: reminderMinutes));
  }

  bool get hasReminder => reminderMinutes > 0;

  int get notificationId {
    return key?.hashCode ?? hashCode;
  }

  // --- Setters ---

  set setKey(int newKey) {
    key = newKey;
  }

  // --- Métodos Estáticos ---

  // (Tus métodos estáticos reminderStringToMinutes, etc. se quedan igual, están perfectos)
  static int reminderStringToMinutes(String reminder) {
    // ... tu código ...
    switch (reminder) {
      case '5 minutos antes':
        return 5;
      case '10 minutos antes':
        return 10;
      case '15 minutos antes':
        return 15;
      case '20 minutos antes':
        return 20;
      case '30 minutos antes':
        return 30;
      case '45 minutos antes':
        return 45;
      case '1 hora antes':
        return 60;
      case '2 horas antes':
        return 120;
      default:
        return 0;
    }
  }

  static String minutesToReminderString(int minutes) {
    // ... tu código ...
    switch (minutes) {
      case 5:
        return '5 minutos antes';
      case 10:
        return '10 minutos antes';
      case 15:
        return '15 minutos antes';
      case 20:
        return '20 minutos antes';
      case 30:
        return '30 minutos antes';
      case 45:
        return '45 minutos antes';
      case 60:
        return '1 hora antes';
      case 120:
        return '2 horas antes';
      default:
        return 'Ninguno';
    }
  }

  static String customMinutesToString(int minutes) {
    // ... tu código ...
    if (minutes == 0) return 'Ninguno';
    if (minutes < 60) return '$minutes minutos antes';
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (remainingMinutes == 0) {
      return '$hours hora${hours > 1 ? 's' : ''} antes';
    } else {
      return '$hours hora${hours > 1 ? 's' : ''} y $remainingMinutes minutos antes';
    }
  }

  // --- copyWith ---

  Task copyWith({
    String? title,
    String? note,
    DateTime? dueDate,
    Color? color,
    bool? isCompleted,
    // String? reminderInterval, // ❌ ELIMINADO
    String? repetitionFrequency,
    int? reminderMinutes,
    int? timeHour,
    int? timeMinute,
    String? alarmTone,
    int? key,
  }) {
    return Task(
      title: title ?? this.title,
      note: note ?? this.note,
      dueDate: dueDate ?? this.dueDate,
      color: color ?? this.color,
      isCompleted: isCompleted ?? this.isCompleted,
      // reminderInterval: reminderInterval ?? this.reminderInterval, // ❌ ELIMINADO
      repetitionFrequency: repetitionFrequency ?? this.repetitionFrequency,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
      timeHour: timeHour ?? this.timeHour,
      timeMinute: timeMinute ?? this.timeMinute,
      alarmTone: alarmTone ?? this.alarmTone,
      key: key ?? this.key,
    );
  }

  @override
  String toString() {
    return 'Task{title: $title, dueDate: $dueDate, time: $timeHour:$timeMinute, reminder: $reminderMinutes min, key: $key}';
  }
}
