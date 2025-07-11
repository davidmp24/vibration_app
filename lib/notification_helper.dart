// lib/notification_helper.dart

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationHelper {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: DarwinInitializationSettings(),
    );

    await _notificationsPlugin.initialize(initializationSettings);
  }

  static Future<void> showNotification({
    required int id,
    required String title, // O título será usado como o nome do remetente.
    required String body,
  }) async {

    // CORREÇÃO: Simplificado o objeto 'Person' para usar a sintaxe correta,
    // removendo a referência ao ícone que causava o erro.
    final Person sender = Person(
      name: title,
      key: 'sender_$id',
    );

    final MessagingStyleInformation messagingStyle = MessagingStyleInformation(
      sender,
      conversationTitle: title,
      messages: [
        Message(body, DateTime.now(), sender),
      ],
    );

    final AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'vibration_signal_channel',
      'Sinais de Vibração (VibraLink)',
      channelDescription: 'Canal para receber os sinais do VibraLink na sua pulseira.',
      importance: Importance.max,
      priority: Priority.high,
      styleInformation: messagingStyle,
      category: AndroidNotificationCategory.message,
    );

    // CORREÇÃO: Removido o 'const' pois a notificação agora é dinâmica.
    final NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    await _notificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
    );
  }
}