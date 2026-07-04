import 'package:flutter/services.dart';
import '../models/display_config.dart';

// Platform-channel bridge to the Swift native layer (StreamClient / CtrlClient / decoder).
class DisplayChannel {
  static const _method = MethodChannel('idisplay/native');
  static const _events = EventChannel('idisplay/status');

  // R6: iOS initiates. Sends host IP + prefs; native performs PAIR_REQUEST and starts the stream.
  static Future<void> connect(Prefs prefs) =>
      _method.invokeMethod('startStream', {
        'hostIp': prefs.hostIp,
        ...prefs.toPrefsJson(),
      });

  static Future<void> disconnect() => _method.invokeMethod('stopStream');

  // Basic prefs only (R1). Windows owns mode/aspect/resolution.
  static Future<void> updatePrefs(Prefs prefs) =>
      _method.invokeMethod('updateConfig', prefs.toPrefsJson());

  // Status events from native: connection state, latency, fps, incoming CONFIG_ACK, etc.
  static Stream<Map<String, dynamic>> get status =>
      _events.receiveBroadcastStream().map((e) => Map<String, dynamic>.from(e as Map));
}
