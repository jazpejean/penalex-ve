import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  factory NotificationService() => _instance;
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const String _livesChannelId = 'lives_reminder';
  static const String _livesChannelName = 'Recordatorios de Vidas';
  static const String _livesChannelDesc =
      'Notificaciones cuando tus vidas se han regenerado';

  Future<void> initialize() async {
    await _firebaseMessaging.requestPermission();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(settings);

    final String? token = await _firebaseMessaging.getToken();
    if (token != null && FirebaseAuth.instance.currentUser != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .update(<Object, Object?>{'fcmToken': token});
    }

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
  }

  void _handleForegroundMessage(RemoteMessage message) {
    _showLocalNotification(
      title: message.notification?.title ?? 'Notificación',
      body: message.notification?.body ?? '',
    );
  }

  void _handleBackgroundMessage(RemoteMessage message) {}

  Future<void> _showLocalNotification({
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'penalex_channel',
      'Penalex Notifications',
      channelDescription: 'Notificaciones de Penalex VE',
      importance: Importance.high,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }

  Future<void> scheduleAudienceReminder({
    required String audienceId,
    required String title,
    required DateTime dateTime,
  }) async {
    await _localNotifications.zonedSchedule(
      audienceId.hashCode,
      'Recordatorio de Audiencia',
      title,
      tz.TZDateTime.from(dateTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'audience_reminder',
          'Recordatorios de Audiencias',
          channelDescription: 'Recordatorios para audiencias programadas',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelAudienceReminder(String audienceId) async {
    await _localNotifications.cancel(audienceId.hashCode);
  }

  // -------------------- NUEVO: Vidas --------------------
  Future<void> scheduleLivesFullReminder({
    required DateTime scheduledTime,
  }) async {
    await _localNotifications.zonedSchedule(
      0,
      '⚡ Vidas recargadas',
      'Ya tienes 5 vidas disponibles. ¡Vuelve a jugar en el Desafío Penal!',
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _livesChannelId,
          _livesChannelName,
          channelDescription: _livesChannelDesc,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelLivesReminder() async {
    await _localNotifications.cancel(0);
  }
}