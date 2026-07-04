import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/connection_state.dart';
import '../services/connection_controller.dart';
import '../widgets/connection_badge.dart';
import '../widgets/display_surface.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ConnectionController>();

    // While streaming, the native Metal surface fills the screen.
    if (c.state == ConnState.streaming) {
      return const Scaffold(backgroundColor: Colors.black, body: DisplaySurface());
    }

    final canConnect = c.prefs.hostIp.isNotEmpty && !c.state.isBusy;
    return Scaffold(
      appBar: AppBar(
        title: const Text('iDisplay'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ConnectionBadge(state: c.state),
          const SizedBox(height: 24),
          if (c.prefs.hostIp.isEmpty)
            const Text('Set a host IP in Settings to connect.')
          else
            Text('Host: ${c.prefs.hostIp}'),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: canConnect ? c.connect : null,
            icon: const Icon(Icons.cast),
            label: Text(c.state.isBusy ? 'Connecting…' : 'Connect'),
          ),
          if (c.state == ConnState.denied)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Text('Host denied the request.', style: TextStyle(color: Colors.red)),
            ),
        ]),
      ),
    );
  }
}
