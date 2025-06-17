// lib/vibration_page.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

class VibrationPage extends StatefulWidget {
  final String channelId;
  final String partnerName;

  const VibrationPage({
    super.key,
    required this.channelId,
    required this.partnerName,
  });

  @override
  State<VibrationPage> createState() => _VibrationPageState();
}

class _VibrationPageState extends State<VibrationPage> {
  final TextEditingController _vibrationCountController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _currentUserId;
  StreamSubscription? _channelSubscription;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserId = prefs.getString('userId');
    });
    if (_currentUserId != null) {
      _listenToVibrations();
    }
  }

  void _listenToVibrations() {
    _channelSubscription?.cancel(); // Cancela qualquer ouvinte anterior
    _channelSubscription = _firestore
        .collection('channels')
        .doc(widget.channelId)
        .snapshots()
        .listen((snapshot) async {
      if (!mounted) return; // Garante que o widget ainda está na árvore
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data()!;
        final String receivedSenderId = data['senderId'] ?? '';

        if (receivedSenderId == _currentUserId) return;

        if (data.containsKey('command') && data['command'] == 'stop') {
          Vibration.cancel();
          _showToast("Sinal de parada recebido!");
          return;
        }

        if (data.containsKey('pattern')) {
          final List<int> pattern = List<int>.from(data['pattern']);
          bool? hasVibrator = await Vibration.hasVibrator();
          if (hasVibrator ?? false) {
            Vibration.cancel();
            Vibration.vibrate(pattern: pattern, repeat: -1);
            _showToast("Sinal de vibração recebido!");
          }
        }
      }
    });
  }

  Future<void> _sendVibrationSignal(List<int> pattern) async {
    if (_currentUserId == null) return;
    await _firestore.collection('channels').doc(widget.channelId).set({
      'pattern': pattern,
      'senderId': _currentUserId,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _sendStopSignal() async {
    if (_currentUserId == null) return;
    await _firestore.collection('channels').doc(widget.channelId).set({
      'command': 'stop',
      'senderId': _currentUserId,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  @override
  void dispose() {
    _channelSubscription?.cancel();
    _vibrationCountController.dispose();
    super.dispose();
  }

  void _vibrateCustomPattern() async {
    final String text = _vibrationCountController.text;
    final int? vibrationCount = int.tryParse(text);

    if (vibrationCount == null || vibrationCount <= 0) {
      _showToast('Por favor, digite um número válido (maior que 0).');
      return;
    }

    List<int> pattern = [0];
    for (int i = 0; i < vibrationCount; i++) {
      pattern.add(200); // Duração da vibração
      pattern.add(100); // Duração da pausa
    }

    _sendVibrationSignal(pattern);
    _showToast('Sinal com $vibrationCount vibrações enviado.');
  }

  void _stopVibration() async {
    Vibration.cancel();
    _sendStopSignal();
    _showToast('Vibração parada e sinal de parada enviado');
  }

  void _showToast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Vibrando com ${widget.partnerName}'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'Pressione e segure para enviar vibração contínua:',
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 25),
              Listener(
                onPointerDown: (_) async {
                  _sendVibrationSignal([0, 10000]);
                  _showToast('Sinal de vibração contínua enviado...');
                },
                onPointerUp: (_) {
                  _sendStopSignal();
                  _showToast('Sinal de parada enviado.');
                },
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size(200, 60),
                      backgroundColor: Colors.green[700]),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.vibration),
                      SizedBox(width: 10),
                      Text('Pressionar e Segurar', style: TextStyle(fontSize: 18)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'Enviar número de vibrações padrão:',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: 280,
                child: Row(
                  children: [
                    SizedBox(
                      width: 80,
                      child: TextFormField(
                        controller: _vibrationCountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          labelText: 'Qtd',
                          filled: true,
                          fillColor: Colors.grey[800],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _vibrateCustomPattern,
                        style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(55)),
                        child: const Text('Enviar', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _stopVibration,
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size(280, 50),
                    backgroundColor: Colors.red[700]),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.stop),
                    SizedBox(width: 10),
                    Text('Parar Todas as Vibrações', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}