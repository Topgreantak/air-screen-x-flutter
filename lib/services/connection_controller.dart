import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/connection_state.dart';
import '../models/display_config.dart';
import 'config_service.dart';
import 'display_channel.dart';

// App state (provider). Owns prefs + connection lifecycle. R6 connect flow lives here.
class ConnectionController extends ChangeNotifier {
  ConnectionController({ConfigService? config}) : _config = config ?? ConfigService();

  final ConfigService _config;
  StreamSubscription<Map<String, dynamic>>? _sub;

  Prefs _prefs = const Prefs();
  ConnState _state = ConnState.disconnected;
  StreamInfo? _stream;

  Prefs get prefs => _prefs;
  ConnState get state => _state;
  StreamInfo? get stream => _stream;

  Future<void> init() async {
    _prefs = await _config.load();
    _sub = DisplayChannel.status.listen(_onStatus, onError: (_) => _set(ConnState.error));
    notifyListeners();
  }

  Future<void> setPrefs(Prefs p) async {
    _prefs = p;
    await _config.save(p);
    if (_state == ConnState.streaming) {
      await DisplayChannel.updatePrefs(p);
    }
    notifyListeners();
  }

  Future<void> connect() async {
    if (_prefs.hostIp.isEmpty || _state.isBusy) return;
    _set(ConnState.requesting);
    try {
      await DisplayChannel.connect(_prefs);
      _set(ConnState.waiting); // native reports 'paired' via status when the host accepts
    } catch (_) {
      _set(ConnState.error);
    }
  }

  Future<void> disconnect() async {
    await DisplayChannel.disconnect();
    _stream = null;
    _set(ConnState.disconnected);
  }

  // Parse status events pushed by native.
  void _onStatus(Map<String, dynamic> e) {
    switch (e['event'] as String?) {
      case 'paired':
        if (e['config'] is Map) {
          _stream = StreamInfo.fromJson(Map<String, dynamic>.from(e['config'] as Map));
        }
        _set(ConnState.streaming);
      case 'denied':
        _set(ConnState.denied);
      case 'disconnected':
        _set(ConnState.disconnected);
      case 'error':
        _set(ConnState.error);
    }
  }

  void _set(ConnState s) {
    _state = s;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
