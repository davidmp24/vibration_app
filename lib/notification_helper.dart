// lib/notification_helper.dart

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationHelper {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  // Inicializa o plugin de notificações
  static Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/launcher_icon'); // Usa o ícone do nosso app

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: DarwinInitializationSettings(), // Configuração básica para iOS
    );

    await _notificationsPlugin.initialize(initializationSettings);
  }

  // Mostra uma notificação
  static Future<void> showNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'vibration_signal_channel', // ID do canal
      'Sinais de Vibração',       // Nome do canal
      channelDescription: 'Canal para receber os sinais do VibraLink',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );
    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    await _notificationsPlugin.show(
      0, // ID da notificação
      'Sinal Recebido!',
      'Você recebeu um novo sinal no VibraLink.',
      platformChannelSpecifics,
    );
  }
}