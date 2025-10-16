// lib/models/task.dart

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'task.g.dart'; 

@HiveType(typeId: 0)
class Task {
  @HiveField(0)
  final String title;

  @HiveField(1)
  final String note;

  @HiveField(3)
  final int colorValue; // El valor entero del color
  
  @HiveField(4)
  bool isCompleted;

  @HiveField(5)
  final String reminderInterval;

  @HiveField(6)
  final String repetitionFrequency;

  // 🔑 Nota: La variable dueDate (@HiveField(2)) está definida en el código anterior
  // Asegúrate de que no la hayas eliminado. Asumo que es un error de copia.
  @HiveField(2)
  final DateTime dueDate;


  Task({
    required this.title,
    this.note = '',
    required this.dueDate,
    Color color = Colors.indigo,
    this.isCompleted = false,
    this.reminderInterval = 'Ninguno', 
    this.repetitionFrequency = 'Ninguno',
  }) : colorValue = color.value; // ✅ Corrección: La inicialización final se realiza aquí.
    
  // Getter para recrear el objeto Color
  Color get color => Color(colorValue);
}