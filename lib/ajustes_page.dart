import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart';

class AjustesPage extends StatefulWidget {
  final bool hasAmplitudeControl;
  const AjustesPage({super.key, required this.hasAmplitudeControl});
  @override
  State<AjustesPage> createState() => _AjustesPageState();
}

class _AjustesPageState extends State<AjustesPage> {
  int _continuousDuration = 3;
  int _patternDuration = 200;
  int _patternSpacing = 100;
  int _vibrationIntensity = 255;
  ThemeMode _currentThemeMode = ThemeMode.system;
  final service = FlutterBackgroundService();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _continuousDuration = prefs.getInt('continuous_vibration_duration') ?? 3;
      _patternDuration = prefs.getInt('vibration_duration') ?? 200;
      _patternSpacing = prefs.getInt('vibration_spacing') ?? 100;
      _vibrationIntensity = prefs.getInt('vibration_intensity') ?? 255;
      _currentThemeMode = ThemeMode.values[prefs.getInt('theme_mode') ?? 2];
    });
  }

  Future<void> _saveIntSetting(String key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, value);
  }

  Future<void> _onThemeChanged(ThemeMode? value) async {
    if (value == null) return;
    setState(() => _currentThemeMode = value);
    await _saveIntSetting('theme_mode', value.index);
    themeNotifier.value = value;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Vibração", style: Theme.of(context).textTheme.titleLarge),
                  const Divider(),
                  _buildSettingRow(
                    label: "Duração de Alerta", value: "$_continuousDuration s",
                    onDecrement: () {
                      if (_continuousDuration > 1) {
                        setState(() => _continuousDuration--);
                        _saveIntSetting('continuous_vibration_duration', _continuousDuration);
                      }
                    },
                    onIncrement: () {
                      if (_continuousDuration < 30) {
                        setState(() => _continuousDuration++);
                        _saveIntSetting('continuous_vibration_duration', _continuousDuration);
                      }
                    },
                  ),
                  _buildSettingRow(
                    label: "Duração do Toque (Padrão)", value: "$_patternDuration ms",
                    onDecrement: () {
                      if (_patternDuration > 50) {
                        setState(() => _patternDuration -= 50);
                        _saveIntSetting('vibration_duration', _patternDuration);
                        service.invoke('set_duration', {'duration': _patternDuration});
                      }
                    },
                    onIncrement: () {
                      if (_patternDuration < 2000) {
                        setState(() => _patternDuration += 50);
                        _saveIntSetting('vibration_duration', _patternDuration);
                        service.invoke('set_duration', {'duration': _patternDuration});
                      }
                    },
                  ),
                  _buildSettingRow(
                    label: "Espaçamento entre Sinais", value: "$_patternSpacing ms",
                    onDecrement: () {
                      if (_patternSpacing > 50) {
                        setState(() => _patternSpacing -= 50);
                        _saveIntSetting('vibration_spacing', _patternSpacing);
                      }
                    },
                    onIncrement: () {
                      if (_patternSpacing < 2000) {
                        setState(() => _patternSpacing += 50);
                        _saveIntSetting('vibration_spacing', _patternSpacing);
                      }
                    },
                  ),
                  if (widget.hasAmplitudeControl)
                    _buildSettingRow(
                      label: "Intensidade da Vibração", value: "$_vibrationIntensity",
                      onDecrement: () {
                        if (_vibrationIntensity > 1) {
                          setState(() => _vibrationIntensity--);
                          _saveIntSetting('vibration_intensity', _vibrationIntensity);
                          service.invoke('set_intensity', {'intensity': _vibrationIntensity});
                        }
                      },
                      onIncrement: () {
                        if (_vibrationIntensity < 255) {
                          setState(() => _vibrationIntensity++);
                          _saveIntSetting('vibration_intensity', _vibrationIntensity);
                          service.invoke('set_intensity', {'intensity': _vibrationIntensity});
                        }
                      },
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Aparência", style: Theme.of(context).textTheme.titleLarge),
                  const Divider(),
                  RadioListTile<ThemeMode>(title: const Text('Claro'), value: ThemeMode.light, groupValue: _currentThemeMode, onChanged: _onThemeChanged),
                  RadioListTile<ThemeMode>(title: const Text('Escuro'), value: ThemeMode.dark, groupValue: _currentThemeMode, onChanged: _onThemeChanged),
                  RadioListTile<ThemeMode>(title: const Text('Padrão do Sistema'), value: ThemeMode.system, groupValue: _currentThemeMode, onChanged: _onThemeChanged),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingRow({
    required String label,
    required String value,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 16)),
          ),
          Row(
            children: [
              IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: onDecrement, splashRadius: 20),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: onIncrement, splashRadius: 20),
            ],
          ),
        ],
      ),
    );
  }
}