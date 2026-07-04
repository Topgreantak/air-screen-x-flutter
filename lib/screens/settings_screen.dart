import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/connection_controller.dart';

// R1: iOS settings are BASIC only — host IP, FPS, display (letterbox).
// Mode / aspect ratio / resolution are configured on the Windows app, not here.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ConnectionController>();
    final p = c.prefs;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(children: [
        ListTile(
          title: const Text('Host IP'),
          subtitle: TextFormField(
            initialValue: p.hostIp,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: '192.168.1.10'),
            onChanged: (v) => c.setPrefs(p.copyWith(hostIp: v.trim())),
          ),
        ),
        const Divider(),
        ListTile(
          title: const Text('FPS'),
          trailing: DropdownButton<int>(
            value: p.fps,
            items: const [30, 60]
                .map((f) => DropdownMenuItem(value: f, child: Text('$f')))
                .toList(),
            onChanged: (v) => v == null ? null : c.setPrefs(p.copyWith(fps: v)),
          ),
        ),
        SwitchListTile(
          title: const Text('Letterbox (keep aspect ratio)'),
          value: p.letterbox,
          onChanged: (v) => c.setPrefs(p.copyWith(letterbox: v)),
        ),
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Display mode, aspect ratio and resolution are set on the Windows app.',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      ]),
    );
  }
}
