import 'dart:async';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
import 'firebase_options.dart';
import 'vibration_page.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  StreamSubscription? channelSubscription;

  int vibrationIntensity = 255;
  int vibrationDuration = 200;

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

  service.on('set_duration').listen((event) async {
    if (event != null && event['duration'] != null) {
      vibrationDuration = event['duration'] as int;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('vibration_duration', vibrationDuration);
    }
  });

  service.on('setChannel').listen((event) {
    final channelId = event?['channelId'];
    final currentUserId = event?['currentUserId'];

    channelSubscription?.cancel();

    if (channelId != null && currentUserId != null) {
      channelSubscription = firestore.collection('channels').doc(channelId).snapshots().listen((snapshot) {
        if (snapshot.exists && snapshot.data() != null) {
          final data = snapshot.data()!;
          if (data['senderId'] != currentUserId) {
            final receivedPattern = List<int>.from(data['pattern'] ?? []);
            if (receivedPattern.isNotEmpty) {

              final intensities = <int>[];
              for (int i = 0; i < receivedPattern.length; i++) {
                intensities.add(i % 2 == 1 ? vibrationIntensity : 0);
              }

              Vibration.vibrate(pattern: receivedPattern, intensities: intensities, repeat: -1);
            }
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