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
        // Manejar toque
      },
    );

    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    await androidImplementation?.requestNotificationsPermission();
    await _setupNotificationChannels();
  }

  // 2. Configurar canales
  static Future<void> _setupNotificationChannels() async {
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin != null) {
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

      for (String tone in _availableTones) {
        final AndroidNotificationChannel channel = AndroidNotificationChannel(
          'alarm_channel_$tone',
          'Alarma ($tone)',
          description: 'Canal para alarmas con sonido $tone',
          importance: Importance.max,
          playSound: true,
          sound: RawResourceAndroidNotificationSound(tone),
          enableVibration: true,
        );
        await androidPlugin.createNotificationChannel(channel);
      }
    }
  }

  // ==========================================
  //      NUEVA LÓGICA: SEMANAL vs FECHA
  // ==========================================

  /// Decide si programa una fecha única o días recurrentes
  static Future<void> scheduleTaskNotifications(Task task) async {
    await cancelTaskNotifications(task); // Limpiamos lo anterior primero

    // ASUMO QUE TU MODELO TASK TIENE UN CAMPO PARA DÍAS (ej: List<int> repeatDays)
    // Si la lista de días está vacía, es una tarea de fecha única
    // ignore: unnecessary_null_comparison
    if (task.repeatDays == null || task.repeatDays.isEmpty) {
      await _scheduleSingleNotification(task);
    } else {
      await _scheduleWeeklyNotifications(task);
    }
  }

  // 3.A Programar Notificación Única (Tu lógica original)
  static Future<void> _scheduleSingleNotification(Task task) async {
    try {
      final int taskId = task.notificationId;
      final DateTime scheduledTime = task.scheduledDateTime;

      // ... (Lógica de recordatorio previo, opcional agregar aquí si la necesitas) ...

      if (scheduledTime.isAfter(DateTime.now())) {
        final NotificationDetails alarmDetails = _buildAlarmDetails(
          task.alarmTone,
        );

        await _notifications.zonedSchedule(
          taskId,
          '¡Es hora! ${task.title}',
          _getAlarmMessage(task.note),
          tz.TZDateTime.from(scheduledTime, tz.local),
          alarmDetails,
          androidScheduleMode: AndroidScheduleMode.alarmClock,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
        // ignore: avoid_print
        print('📅 Alarma única programada para: ${task.title}');
      }
    } catch (e) {
      // ignore: avoid_print
      print('❌ Error programando única: $e');
    }
  }

  // 3.B Programar Notificaciones Semanales (NUEVO)
  static Future<void> _scheduleWeeklyNotifications(Task task) async {
    try {
      // Obtenemos la hora y minuto de la fecha programada
      final int hour = task.scheduledDateTime.hour;
      final int minute = task.scheduledDateTime.minute;
      final NotificationDetails alarmDetails = _buildAlarmDetails(
        task.alarmTone,
      );

      // Recorremos los días seleccionados (Ej: [1, 4, 6] -> Lun, Jue, Sab)
      for (int dayOfWeek in task.repeatDays) {
        // Generamos un ID único: ID Tarea * 10 + Día (Ej: Tarea 5, Lunes(1) -> 51)
        // Esto evita que el Lunes sobrescriba al Jueves
        final int uniqueId = (task.notificationId * 10) + dayOfWeek;

        await _notifications.zonedSchedule(
          uniqueId,
          '¡Es hora! ${task.title}',
          _getAlarmMessage(task.note),
          _nextInstanceOfDay(dayOfWeek, hour, minute), // Calculamos la fecha
          alarmDetails,
          androidScheduleMode: AndroidScheduleMode.alarmClock,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents:
              DateTimeComponents.dayOfWeekAndTime, // CLAVE: Repite cada semana
        );
      }
      // ignore: avoid_print
      print(
        '🔄 Alarmas semanales programadas para: ${task.title} en días ${task.repeatDays}',
      );
    } catch (e) {
      // ignore: avoid_print
      print('❌ Error programando semanal: $e');
    }
  }

  // ==========================================
  //           FUNCIONES AUXILIARES
  // ==========================================

  // Construye los detalles de la notificación (para no repetir código)
  static NotificationDetails _buildAlarmDetails(String toneName) {
    String selectedTone = toneName;
    if (!_availableTones.contains(selectedTone)) selectedTone = 'tono_1';
    final String channelId = 'alarm_channel_$selectedTone';

    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        'Alarmas',
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound(selectedTone),
        enableVibration: true,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        audioAttributesUsage: AudioAttributesUsage.alarm,
      ),
      iOS: DarwinNotificationDetails(
        sound: '$selectedTone.mp3',
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      ),
    );
  }

  // Calcula la fecha del próximo Lunes/Martes/etc a la hora X
  static tz.TZDateTime _nextInstanceOfDay(int dayOfWeek, int hour, int minute) {
    tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // Ajustamos al día de la semana correcto
    while (scheduledDate.weekday != dayOfWeek) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // Si la fecha ya pasó hoy, programar para la próxima semana
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 7));
    }
    return scheduledDate;
  }

  static String _getAlarmMessage(String description) {
    return description.isNotEmpty
        ? description
        : '¡Es momento de completar tu tarea!';
  }

  // 5. Cancelar (Actualizado para borrar múltiples IDs)
  static Future<void> cancelTaskNotifications(Task task) async {
    try {
      final int taskId = task.notificationId;

      // 1. Cancelar la principal (por si era fecha única)
      await _notifications.cancel(taskId);
      // 2. Cancelar recordatorio
      await _notifications.cancel(taskId + 1000);

      // 3. Cancelar posibles repeticiones semanales (Lunes a Domingo)
      // Como usamos la lógica (ID * 10) + día, barremos del 1 al 7
      for (int i = 1; i <= 7; i++) {
        await _notifications.cancel((taskId * 10) + i);
      }

      // ignore: avoid_print
      print("🗑️ Notificaciones canceladas para ID: $taskId");
    } catch (e) {
      // ignore: avoid_print
      print(' Error cancelando notificaciones: $e');
    }
  }

  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}
