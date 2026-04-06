import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const settings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (details) {},
      onDidReceiveBackgroundNotificationResponse: _onBackground,
    );

    // Pide permiso en Android 13+
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  // Debe ser una función top-level (fuera de la clase) o static
  @pragma('vm:entry-point')
  static void _onBackground(NotificationResponse details) {}

  static Future<void> showNotaGuardada() async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'notas_channel',
        'Notas',
        channelDescription: 'Notificaciones de la app de notas',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
      ),
    );
    await _plugin.show(id: 0, title: 'Nota guardada', body: 'Nota guardada exitosamente', notificationDetails: details);
  }

  static Future<void> showNotaEditada() async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'notas_channel',
        'Notas',
        channelDescription: 'Notificaciones de la app de notas',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
      ),
    );
    await _plugin.show(id: 1, title: 'Nota editada', body: 'Nota editada exitosamente', notificationDetails: details);
  }
}