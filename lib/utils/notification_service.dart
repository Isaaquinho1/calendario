import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import '../models/task.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // ---  DEFINICIÓN DE SONIDOS ---

  static const String _soundReminder = 'remind';

  static const List<String> _availableTones = ['tono_1', 'tono_2', 'tono_3'];

  static Future<void> init() async {
    // Inicializar timezones
    tz.initializeTimeZones();
    try {
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      tz.setLocalLocation(tz.getLocation('America/Mexico_City'));
    }

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Manejar cuando se toca la notificación
      },
    );

    // Solicitar permisos en Android 13+ (IMPORTANTE)
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    await androidImplementation?.requestNotificationsPermission();

    await _setupNotificationChannels();
  }

  // 2. Configurar canales (UNO POR CADA TONO)
  static Future<void> _setupNotificationChannels() async {
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin != null) {
      // Canal para recordatorios (fijo)
      const AndroidNotificationChannel reminderChannel =
          AndroidNotificationChannel(
            'reminder_channel',
            'Recordatorios',
            description: 'Notificaciones suaves previas a la tarea',
            importance: Importance.high,
            playSound: true,
            sound: RawResourceAndroidNotificationSound(_soundReminder),
            enableVibration: true,
          );
      await androidPlugin.createNotificationChannel(reminderChannel);

      // Crear un canal para CADA tono de alarma
      for (String tone in _availableTones) {
        final AndroidNotificationChannel channel = AndroidNotificationChannel(
          'alarm_channel_$tone', // ID único por tono (ej: alarm_channel_tono_1)
          'Alarma ($tone)',
          description: 'Canal para alarmas con sonido $tone',
          importance: Importance.max, // Max para que suene fuerte
          playSound: true,
          sound: RawResourceAndroidNotificationSound(tone),
          enableVibration: true,
        );
        await androidPlugin.createNotificationChannel(channel);
      }
    }
  }

  // 3. Programar notificaciones
  static Future<void> scheduleTaskNotifications(Task task) async {
    try {
      await cancelTaskNotifications(task);

      final int taskId = task.notificationId;
      final DateTime scheduledTime = task.scheduledDateTime;

      // === PROGRAMAR RECORDATORIO (Antes) ===
      if (task.reminderMinutes > 0) {
        final DateTime reminderTime = task.scheduledDateTime.subtract(
          Duration(minutes: task.reminderMinutes),
        );

        if (reminderTime.isAfter(DateTime.now())) {
          const AndroidNotificationDetails androidReminderDetails =
              AndroidNotificationDetails(
                'reminder_channel',
                'Recordatorios',
                importance: Importance.high,
                priority: Priority.high,
                sound: RawResourceAndroidNotificationSound(_soundReminder),
              );

          const NotificationDetails reminderDetails = NotificationDetails(
            android: androidReminderDetails,
            iOS: DarwinNotificationDetails(sound: '$_soundReminder.mp3'),
          );

          await _notifications.zonedSchedule(
            taskId + 1000, // ID Diferente para recordatorio
            'Recordatorio: ${task.title}',
            _getReminderMessage(task.reminderMinutes, task.note),
            tz.TZDateTime.from(reminderTime, tz.local),
            reminderDetails,
            // ❌ ELIMINAR: Parámetro obsoleto en la versión 19+
            // uiLocalNotificationDateInterpretation:
            //     UILocalNotificationDateInterpretation.absoluteTime,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          );
        }
      }

      // === PROGRAMAR ALARMA PRINCIPAL (Hora Exacta) ===
      if (scheduledTime.isAfter(DateTime.now())) {
        // Determinar qué canal usar basado en el tono elegido
        String selectedTone = task.alarmTone;
        // Si el tono guardado no está en la lista, usar el default
        if (!_availableTones.contains(selectedTone)) {
          selectedTone = 'tono_1';
        }

        // Usamos el ID del canal específico para ese tono
        final String channelId = 'alarm_channel_$selectedTone';

        final AndroidNotificationDetails androidAlarmDetails =
            AndroidNotificationDetails(
              channelId, //  CLAVE: Usar el canal pre-creado con ese sonido
              'Alarmas',
              importance: Importance.max,
              priority:
                  Priority.max, // Prioridad máxima para despertar pantalla
              playSound: true,
              // Aunque el canal ya tiene el sonido, es bueno reiterarlo aquí
              sound: RawResourceAndroidNotificationSound(selectedTone),
              enableVibration: true,
              fullScreenIntent: true, // Para mostrarse sobre pantalla bloqueo
              category: AndroidNotificationCategory.alarm, // Categoría Alarma
              audioAttributesUsage:
                  AudioAttributesUsage.alarm, // Usar volumen de alarma
            );

        final NotificationDetails alarmDetails = NotificationDetails(
          android: androidAlarmDetails,
          iOS: DarwinNotificationDetails(
            sound: '$selectedTone.mp3',
            presentSound: true,
            interruptionLevel:
                InterruptionLevel.timeSensitive, // Importante iOS 15+
          ),
        );

        await _notifications.zonedSchedule(
          taskId,
          '¡Es hora! ${task.title}',
          _getAlarmMessage(task.note),
          tz.TZDateTime.from(scheduledTime, tz.local),
          alarmDetails,

          androidScheduleMode:
              AndroidScheduleMode.alarmClock, //  MODO ALARMA REAL
        );
      }

      print(
        ' Alarmas programadas para: ${task.title} (Tono: ${task.alarmTone})',
      );
    } catch (e) {
      print(' Error programando notificaciones: $e');
    }
  }

  // 4. Mensajes
  static String _getReminderMessage(int minutes, String description) {
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      return 'En $hours hora${hours > 1 ? 's' : ''}: ${description.isNotEmpty ? description : "Tu tarea está próxima"}';
    } else {
      return 'En $minutes minutos: ${description.isNotEmpty ? description : "Tu tarea está próxima"}';
    }
  }

  static String _getAlarmMessage(String description) {
    return description.isNotEmpty
        ? description
        : '¡Es momento de completar tu tarea!';
  }

  // 5. Cancelar
  static Future<void> cancelTaskNotifications(Task task) async {
    try {
      final int taskId = task.notificationId;
      await _notifications.cancel(taskId);
      await _notifications.cancel(taskId + 1000);
    } catch (e) {
      print(' Error cancelando notificaciones: $e');
    }
  }

  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  // 6. Notificación de Prueba
  static Future<void> showTestNotification(bool isAlarm) async {
    try {
      final String tone = isAlarm ? 'tono_1' : _soundReminder;
      final String channelId = isAlarm
          ? 'alarm_channel_$tone'
          : 'reminder_channel';

      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            channelId,
            isAlarm ? 'Alarmas' : 'Recordatorios',
            importance: Importance.max,
            priority: Priority.max,
            sound: RawResourceAndroidNotificationSound(tone),
          );

      final NotificationDetails details = NotificationDetails(
        android: androidDetails,
      );

      await _notifications.show(
        DateTime.now().millisecondsSinceEpoch % 100000,
        isAlarm ? ' PRUEBA DE ALARMA' : ' PRUEBA DE RECORDATORIO',
        'Si escuchas esto, el sonido ($tone) funciona correctamente.',
        details,
      );
    } catch (e) {
      print('❌ Error prueba: $e');
    }
  }
}