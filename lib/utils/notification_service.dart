// lib/utils/notification_service.dart

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import '../models/task.dart'; 

class NotificationService {
  
  // 1. Inicializar Time Zones de forma ASÍNCRONA
  static Future<void> init() async { 
    tz.initializeTimeZones();
    try {
      final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
      final String timeZoneName = timeZoneInfo.identifier;
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      tz.setLocalLocation(tz.getLocation('America/New_York'));
    }
  }

  // 2. Función para calcular la hora de notificación (sin cambios)
  static DateTime _calculateNotificationTime(Task task) {
    if (task.reminderInterval == 'Ninguno') {
      return task.dueDate;
    }

    int minutesBefore = 0;
    switch (task.reminderInterval) {
      case '5 minutos antes':
        minutesBefore = 5;
        break;
      case '10 minutos antes':
        minutesBefore = 10;
        break;
      case '15 minutos antes':
        minutesBefore = 15;
        break;
      case '20 minutos antes':
        minutesBefore = 20;
        break;
      case '30 minutos antes':
        minutesBefore = 30;
        break;
      case '45 minutos antes':
        minutesBefore = 45;
        break;
      case '1 hora antes':
        minutesBefore = 60;
        break;
      default:
        minutesBefore = 0;
        break;
    }

    final scheduledTime = task.dueDate.subtract(Duration(minutes: minutesBefore));
    
    if (scheduledTime.isBefore(DateTime.now())) {
      return task.dueDate.isBefore(DateTime.now()) 
          ? DateTime.now().add(const Duration(seconds: 5)) 
          : scheduledTime;
    }
    
    return scheduledTime;
  }

  // 3. Función principal para programar la notificación
  static Future<void> scheduleNotification(
      Task task, FlutterLocalNotificationsPlugin notificationsPlugin) async {
      
    final int id = task.hashCode; 
    
    await notificationsPlugin.cancel(id); 

    if (task.reminderInterval == 'Ninguno' && task.repetitionFrequency == 'Ninguno') {
      return;
    }
    
    final scheduledTime = _calculateNotificationTime(task);
    final tzTime = tz.TZDateTime.from(scheduledTime, tz.local);
    
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'task_reminders_id', 
      'Recordatorios de Tareas',
      channelDescription: 'Canal para alertas de tareas programadas.',
      importance: Importance.high,
    );
    const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
      sound: 'default',
    );
    
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    // Notificación única (zonedSchedule)
    if (task.repetitionFrequency == 'Ninguno') {
      await notificationsPlugin.zonedSchedule( 
        id,
        '⏰ Recordatorio: ${task.title}',
        'Tu tarea está programada para las ${task.dueDate.hour}:${task.dueDate.minute.toString().padLeft(2, '0')}. ¡Vamos por ello!',
        tzTime,
        notificationDetails,

        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, 
        // ❌ ELIMINADO: Parámetros obsoletos que causaban el error de compilación.
      );
    } else {
      // Notificación recurrente (periodicallyShow)
      final RepeatInterval repeatInterval;
      
      switch (task.repetitionFrequency) {
        case 'Diariamente':
          repeatInterval = RepeatInterval.daily;
          break;
        case 'Semanalmente':
          repeatInterval = RepeatInterval.weekly;
          break;
        default:
          return;
      }
      
      await notificationsPlugin.periodicallyShow( 
        id,
        '📅 Tarea Recurrente: ${task.title}',
        'Recordatorio diario/semanal de tu tarea. ¡No la olvides!',
        repeatInterval,
        notificationDetails,
        
        // 🔑 AÑADIDO: Parámetro obligatorio para tu versión
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    }
  }
}