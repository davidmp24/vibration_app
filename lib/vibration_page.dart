import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import 'package:vibration/vibration.dart';
import 'ajustes_page.dart';

class VibrationPage extends StatefulWidget {
  const VibrationPage({super.key});
  @override
  State<VibrationPage> createState() => _VibrationPageState();
}

class _VibrationPageState extends State<VibrationPage> with WidgetsBindingObserver {
  // Controllers e Instâncias
  final TextEditingController _vibrationCountController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final service = FlutterBackgroundService();

  // Variáveis de Estado
  String? _currentUserId;
  String _userName = "Carregando...";
  String? _connectedPartnerId;
  String? _connectedPartnerName;
  String? _channelId;
  bool _isManuallyOnline = false;
  bool _hasAmplitudeControl = false;
  final Map<String, int> _presetValues = {
    'A': 1, 'B': 2, 'C': 3, 'D': 4, 'E': 5,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeUser();
    _checkAmplitudeSupport();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if(_isManuallyOnline){
      _updateUserStatus(isOnline: false);
    }
    _vibrationCountController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && _isManuallyOnline) {
      _updateUserStatus(isOnline: true);
    }
  }

  Future<void> _initializeUser() async {
    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');
    String? userName = prefs.getString('userName');

    _presetValues.forEach((key, defaultValue) {
      _presetValues[key] = prefs.getInt('preset_$key') ?? defaultValue;
    });

    if (userId == null || userName == null) {
      userId ??= const Uuid().v4();
      await prefs.setString('userId', userId);
      await _promptForUserName(context);
    }
    if (mounted) {
      setState(() {
        _currentUserId = prefs.getString('userId');
        _userName = prefs.getString('userName') ?? "Usuário Anônimo";
      });
    }
  }

  Future<void> _checkAmplitudeSupport() async {
    bool? hasSupport = await Vibration.hasAmplitudeControl();
    if (mounted) {
      setState(() {
        _hasAmplitudeControl = hasSupport ?? false;
      });
    }
  }

  Future<void> _handleOnlineSwitch(bool isOnline) async {
    setState(() { _isManuallyOnline = isOnline; });

    final isRunning = await service.isRunning();
    if (isOnline) {
      if (!isRunning) {
        await service.startService();
      }
      service.invoke('setAsForeground');
      _sendInitialSettingsToService();
      await _updateUserStatus(isOnline: true);
    } else {
      service.invoke('stop');
      await _updateUserStatus(isOnline: false);
      if (_connectedPartnerId != null) {
        _handleUserTap(_connectedPartnerId!, _connectedPartnerName!);
      }
    }
  }

  Future<void> _sendInitialSettingsToService() async {
    final prefs = await SharedPreferences.getInstance();
    final intensity = prefs.getInt('vibration_intensity') ?? 255;
    service.invoke('set_intensity', {'intensity': intensity});
  }

  Future<void> _updateUserStatus({required bool isOnline}) async {
    if (_currentUserId == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUsername = prefs.getString('userName') ?? 'Usuário Anônimo';
      await _firestore.collection('presence').doc(_currentUserId).set(
        { 'online': isOnline, 'userName': currentUsername, 'last_seen': FieldValue.serverTimestamp() },
        SetOptions(merge: true),
      );
    } catch (e) {
      _showToast("Erro de conexão. Verifique sua internet.");
      if (mounted) { setState(() { _isManuallyOnline = !isOnline; }); }
    }
  }

  void _handleUserTap(String partnerId, String partnerName) {
    String? newChannelId;
    if (_connectedPartnerId == partnerId) {
      setState(() {
        _connectedPartnerId = null;
        _connectedPartnerName = null;
        _channelId = null;
      });
      _showToast("Desconectado.");
      newChannelId = null;
    } else {
      setState(() {
        _connectedPartnerId = partnerId;
        _connectedPartnerName = partnerName;
        _channelId = _createChannelId(partnerId);
      });
      _showToast("Conectado com $partnerName");
      newChannelId = _channelId;
    }

    if (_isManuallyOnline) {
      service.invoke('setChannel', {'channelId': newChannelId, 'currentUserId': _currentUserId});
    }
  }

  // Função genérica para enviar qualquer padrão para o canal.
  Future<void> _sendPatternToChannel(List<int> pattern) async {
    if (_channelId == null) {
      _showToast("Selecione um usuário para se conectar.");
      return;
    }
    await _firestore.collection('channels').doc(_channelId).set({
      'pattern': pattern,
      'senderId': _currentUserId,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Função específica para o botão de Alerta (Toque Contínuo)
  Future<void> _sendContinuousVibration(bool start) async {
    List<int> pattern;
    if (start) {
      final prefs = await SharedPreferences.getInstance();
      final int alertDuration = (prefs.getInt('continuous_vibration_duration') ?? 3) * 1000;
      pattern = [0, alertDuration];
    } else {
      pattern = [0];
    }
    await _sendPatternToChannel(pattern);
  }

  // Função específica para o botão de Padrão Personalizado
  void _vibrateCustomPattern() async {
    final prefs = await SharedPreferences.getInstance();
    final int vibrationDuration = prefs.getInt('vibration_duration') ?? 200;
    final int vibrationSpacing = prefs.getInt('vibration_spacing') ?? 100;

    final text = _vibrationCountController.text;
    if (text.isEmpty) { _showToast("Defina uma quantidade ou use um atalho."); return; }
    final vibrationCount = int.tryParse(text);
    if (vibrationCount == null || vibrationCount <= 0) { _showToast('Digite um número válido.'); return; }

    List<int> pattern = [0];
    for (int i = 0; i < vibrationCount; i++) {
      pattern.add(vibrationDuration);
      pattern.add(vibrationSpacing);
    }

    await _sendPatternToChannel(pattern);
  }

  Future<void> _showEditPresetDialog(String label) async {
    final TextEditingController presetController = TextEditingController();
    presetController.text = _presetValues[label].toString();
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Editar Atalho "$label"'),
          content: TextFormField(
            controller: presetController,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Nova quantidade'),
          ),
          actions: <Widget>[
            TextButton(child: const Text('Cancelar'), onPressed: () => Navigator.of(context).pop()),
            TextButton(
              child: const Text('Salvar'),
              onPressed: () async {
                final newValue = int.tryParse(presetController.text);
                if (newValue != null && newValue > 0) {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setInt('preset_$label', newValue);
                  if(mounted) { setState(() { _presetValues[label] = newValue; }); }
                  Navigator.of(context).pop();
                } else {
                  _showToast("Por favor, insira um número válido.");
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _promptForUserName(BuildContext context) async {
    TextEditingController nameController = TextEditingController();
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Defina seu nome de usuário'),
          content: TextField(controller: nameController, decoration: const InputDecoration(hintText: "Seu nome"), autofocus: true),
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

  @override
  Widget build(BuildContext context) {
    final String presenceStatusText = _isManuallyOnline ? "Online" : "Offline";
    final Color presenceStatusColor = _isManuallyOnline ? Colors.greenAccent : Colors.redAccent;

    return Scaffold(
      appBar: AppBar(
        title: const Text('VibraLink'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Ajustes',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AjustesPage(
                    hasAmplitudeControl: _hasAmplitudeControl,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: SwitchListTile(
                title: Text(presenceStatusText, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: presenceStatusColor)),
                subtitle: const Text("Ficar visível e receber vibrações em 2º plano"),
                value: _isManuallyOnline,
                onChanged: _handleOnlineSwitch,
                secondary: Icon(Icons.power_settings_new, color: presenceStatusColor),
              ),
            ),
            const SizedBox(height: 20),

            if (_isManuallyOnline) ...[
              const Text("Usuários Online:", style: TextStyle(fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 8),
              Container(
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade700),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _buildUserList(),
              ),
              const SizedBox(height: 10),
              Text(
                _connectedPartnerName == null
                    ? "Selecione um usuário para conectar"
                    : "Conectado com: $_connectedPartnerName",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 10),
              const Divider(),

              Card(
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      const Text("Toque Contínuo (Alerta)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 15),
                      SizedBox(
                        width: double.infinity,
                        child: Listener(
                          onPointerDown: (_) => _sendContinuousVibration(true),
                          onPointerUp: (_) => _sendContinuousVibration(false),
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.touch_app, size: 20),
                            label: const Text('ALERTA', style: TextStyle(fontSize: 16)),
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[800], fixedSize: const Size.fromHeight(44)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      const Text("Padrão Personalizado", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 15),
                      const Text("Atalhos de Quantidade:"),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildPresetButton("A"),
                          _buildPresetButton("B"),
                          _buildPresetButton("C"),
                          _buildPresetButton("D"),
                          _buildPresetButton("E"),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 80,
                            child: TextFormField(
                              controller: _vibrationCountController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Qtd', isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 8)),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.send, size: 20),
                              label: const Text('Enviar Padrão', style: TextStyle(fontSize: 15)),
                              onPressed: _vibrateCustomPattern,
                              style: ElevatedButton.styleFrom(fixedSize: const Size.fromHeight(44)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 30),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetButton(String label) {
    final String value = _presetValues[label].toString();

    return ElevatedButton(
      onPressed: () {
        _vibrationCountController.text = value;
      },
      onLongPress: () {
        _showEditPresetDialog(label);
      },
      style: ElevatedButton.styleFrom(
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(16),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildUserList() {
    if (_currentUserId == null) return const Center(child: Text("Inicializando..."));
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('presence').where('online', isEqualTo: true).where('last_seen', isGreaterThan: DateTime.now().subtract(const Duration(minutes: 2))).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return const Center(child: Text("Erro ao carregar usuários."));
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('Nenhum usuário online.'));
        final users = snapshot.data!.docs.where((doc) => doc.id != _currentUserId).toList();
        if (users.isEmpty) return const Center(child: Text('Você é o único online.'));
        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final userDoc = users[index];
            final userName = userDoc['userName'] ?? 'Desconhecido';
            final bool isConnected = userDoc.id == _connectedPartnerId;
            return Card(
              color: isConnected ? Colors.green.withOpacity(0.3) : null,
              child: ListTile(
                leading: const Icon(Icons.person),
                title: Text(userName),
                trailing: isConnected ? const Icon(Icons.check_circle, color: Colors.green) : null,
                onTap: () => _handleUserTap(userDoc.id, userName),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: TextStyle(color: Colors.grey[400], fontSize: 14),
          children: [
            const TextSpan(text: 'Desenvolvido por - '),
            TextSpan(
              text: 'David MP',
              style: const TextStyle(color: Colors.lightBlueAccent, decoration: TextDecoration.underline),
              recognizer: TapGestureRecognizer()..onTap = _launchURL,
            ),
          ],
        ),
      ),
    );
  }

  String _createChannelId(String otherUserId) {
    if (_currentUserId == null) return "";
    if (_currentUserId!.compareTo(otherUserId) > 0) return '$_currentUserId\_$otherUserId';
    return '$otherUserId\_$_currentUserId';
  }

  Future<void> _launchURL() async {
    final Uri url = Uri.parse('https://github.com/davidmp24');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      _showToast('Não foi possível abrir o link.');
    }
  }

  void _showToast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), duration: const Duration(seconds: 2)));
  }
}