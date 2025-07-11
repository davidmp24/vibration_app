import 'dart:async';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
import 'firebase_options.dart';
import 'notification_helper.dart';
import 'vibration_page.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationHelper.init();

  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  StreamSubscription? channelSubscription;

  int vibrationIntensity = 255;

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });
    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stop').listen((event) {
    channelSubscription?.cancel();
    service.stopSelf();
  });

  service.on('set_intensity').listen((event) async {
    if (event != null && event['intensity'] != null) {
      vibrationIntensity = event['intensity'] as int;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('vibration_intensity', vibrationIntensity);
    }
  });

  service.on('setChannel').listen((event) {
    final channelId = event?['channelId'];
    final currentUserId = event?['currentUserId'];

    channelSubscription?.cancel();

    if (channelId != null && currentUserId != null) {
      channelSubscription = firestore.collection('channels').doc(channelId).snapshots().listen((snapshot) async {
        try {
          // Apenas processa se o documento existir e tiver dados.
          if (!snapshot.exists || snapshot.data() == null) return;

          final data = snapshot.data()!;

          // Apenas processa se houver um remetente e não for o próprio utilizador.
          if (data.containsKey('senderId') && data['senderId'] != currentUserId) {

            // --- CORREÇÃO: Lê TODOS os dados para variáveis locais PRIMEIRO ---
            final String senderName = data['senderName'] ?? 'Alguém';
            final List<int>? pattern = data.containsKey('pattern') ? List<int>.from(data['pattern']) : null;
            final int? vibrationCount = data.containsKey('vibrationCount') ? data['vibrationCount'] : null;
            final int? vibrationDuration = data.containsKey('vibrationDuration') ? data['vibrationDuration'] : null;
            final int? vibrationSpacing = data.containsKey('vibrationSpacing') ? data['vibrationSpacing'] : null;

            // --- CORREÇÃO: Apaga imediatamente o documento para evitar reprocessamento ---
            await firestore.collection('channels').doc(channelId).delete();

            // --- Agora, executa a lógica com base nas variáveis locais guardadas ---
            if (pattern != null) {
              // Lógica para o alerta contínuo
              if (pattern.length == 1 && pattern[0] == 0) {
                Vibration.cancel();
                return;
              }
              if (pattern.length > 1) {
                final intensities = List.generate(pattern.length, (i) => i % 2 == 1 ? vibrationIntensity : 0);
                Vibration.vibrate(pattern: pattern, intensities: intensities);
                NotificationHelper.showNotification(
                  id: DateTime.now().millisecondsSinceEpoch.toUnsigned(31),
                  title: 'Alerta de $senderName',
                  body: 'Sinal de alerta recebido.',
                );
              }
            } else if (vibrationCount != null && vibrationDuration != null && vibrationSpacing != null) {
              // Lógica para múltiplos toques
              for (int i = 0; i < vibrationCount; i++) {
                Vibration.vibrate(pattern: [0, vibrationDuration], intensities: [0, vibrationIntensity]);
                NotificationHelper.showNotification(
                  id: DateTime.now().millisecondsSinceEpoch.toUnsigned(31),
                  title: 'Sinal de $senderName',
                  body: 'Toque ${i + 1} de $vibrationCount',
                );
                if (i < vibrationCount - 1) {
                  await Future.delayed(Duration(milliseconds: vibrationSpacing));
                }
              }
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('Erro ao processar o sinal de vibração: $e');
          }
        }
      });
    }
  });
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true,
      autoStart: true,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeService();
  await NotificationHelper.init();

  final prefs = await SharedPreferences.getInstance();
  final themeIndex = prefs.getInt('theme_mode') ?? 2;
  themeNotifier.value = ThemeMode.values[themeIndex];

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          title: 'VibraLink',
          theme: ThemeData.light(useMaterial3: true),
          darkTheme: ThemeData.dark(useMaterial3: true),
          themeMode: currentMode,
          home: const VibrationPage(),
        );
      },
    );
  }
}
