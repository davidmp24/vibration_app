// lib/user_list_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart'; // ADICIONADO: para o reconhecedor de toque
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart'; // ADICIONADO: para abrir links
import 'package:uuid/uuid.dart';
import 'vibration_page.dart';

class UserListPage extends StatefulWidget {
  const UserListPage({super.key});

  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> with WidgetsBindingObserver {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _currentUserId;
  String _userName = "Usuário Anônimo";

  // --- LÓGICA PARA ABRIR O LINK (NOVA FUNÇÃO) ---
  Future<void> _launchURL() async {
    final Uri url = Uri.parse('https://github.com/davidmp24');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      // Se não conseguir abrir, mostra um erro (opcional)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível abrir o link: $url')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeUser();
  }

  // O resto das suas funções (_initializeUser, _promptForUserName, etc.)
  // permanece o mesmo. Não precisa alterar.
  // ...
  // (As funções existentes não foram repetidas aqui para economizar espaço,
  // mas elas devem permanecer no seu arquivo)
  // ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dispositivos Disponíveis'),
      ),
      // --- ESTRUTURA DO BODY ALTERADA PARA INCLUIR O RODAPÉ ---
      body: Column( // O corpo agora é uma coluna
        children: [
          Expanded( // Ocupa todo o espaço disponível, empurrando o rodapé para baixo
            child: _currentUserId == null
                ? const Center(child: CircularProgressIndicator())
                : StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('presence')
                        .where('online', isEqualTo: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      // ... toda a lógica do seu StreamBuilder continua a mesma aqui
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final users = snapshot.data!.docs.where((doc) {
                        return doc.id != _currentUserId;
                      }).toList();
                      if (users.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              'Nenhum outro usuário online no momento. Peça para alguém abrir o app!',
                              style: TextStyle(fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }
                      return ListView.builder(
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          final userDoc = users[index];
                          final userName = userDoc['userName'] ?? 'Usuário Desconhecido';
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: ListTile(
                              leading: const Icon(Icons.person_pin_circle_rounded, color: Colors.greenAccent, size: 36),
                              title: Text(userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: const Text('Online - Toque para conectar'),
                              onTap: () {
                                final channelId = _createChannelId(userDoc.id);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => VibrationPage(
                                      channelId: channelId,
                                      partnerName: userName,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
          // --- WIDGET DO RODAPÉ ADICIONADO ---
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
                children: [
                  const TextSpan(text: 'Desenvolvido 2025 - '),
                  TextSpan(
                    text: 'David MP',
                    style: const TextStyle(
                      color: Colors.lightBlueAccent,
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.bold,
                    ),
                    // Adiciona o gesto de clique
                    recognizer: TapGestureRecognizer()..onTap = _launchURL,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- COPIE SUAS FUNÇÕES ANTIGAS AQUI ---
  // Cole aqui as outras funções da classe _UserListPageState que não foram mostradas:
  // _initializeUser(), _promptForUserName(), _updateUserStatus(),
  // didChangeAppLifecycleState(), dispose(), _createChannelId()
  // Elas são necessárias para o funcionamento do app.

  Future<void> _initializeUser() async {
    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');
    String? userName = prefs.getString('userName');
    if (userId == null || userName == null) {
      userId ??= const Uuid().v4();
      await prefs.setString('userId', userId);
      await _promptForUserName(context);
    }
    setState(() {
      _currentUserId = prefs.getString('userId');
      _userName = prefs.getString('userName') ?? "Usuário Anônimo";
    });
    _updateUserStatus(true);
  }

// SUBSTITUA A FUNÇÃO INTEIRA PELA VERSÃO ABAIXO

  Future<void> _promptForUserName(BuildContext context) async {
    TextEditingController nameController = TextEditingController();
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) { // <<< CORRIGIDO AQUI
        return AlertDialog(
          title: const Text('Defina seu nome de usuário'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(hintText: "Seu nome"),
            autofocus: true,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Salvar'),
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('userName', nameController.text);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateUserStatus(bool isOnline) async {
    if (_currentUserId == null) return;
    final prefs = await SharedPreferences.getInstance();
    final currentUsername = prefs.getString('userName') ?? 'Usuário Anônimo';
    await _firestore.collection('presence').doc(_currentUserId).set({
      'online': isOnline,
      'userName': currentUsername,
      'last_seen': FieldValue.serverTimestamp(),
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _updateUserStatus(true);
    } else {
      _updateUserStatus(false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _updateUserStatus(false);
    super.dispose();
  }

  String _createChannelId(String otherUserId) {
    if (_currentUserId == null) throw Exception("Usuário atual não definido");
    if (_currentUserId!.compareTo(otherUserId) > 0) {
      return '$_currentUserId\_$otherUserId';
    } else {
      return '$otherUserId\_$_currentUserId';
    }
  }
}