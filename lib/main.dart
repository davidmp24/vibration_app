// main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'user_list_page.dart'; // Importa a nova tela de "Lobby"

void main() async {
  // Garante que todos os plugins do Flutter sejam inicializados antes de rodar o app
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa o Firebase usando as configurações da sua plataforma
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App de Vibração',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[900],
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.blueGrey,
          ),
        ),
      ),
      // A tela inicial do aplicativo agora é a nossa lista de usuários online.
      home: const UserListPage(),
    );
  }
}