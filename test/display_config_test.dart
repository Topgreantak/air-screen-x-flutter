import 'package:flutter_test/flutter_test.dart';
import 'package:idisplay_client/models/display_config.dart';
import 'package:idisplay_client/models/connection_state.dart';

void main() {
  test('Prefs round-trips through JSON', () {
    const p = Prefs(hostIp: '192.168.1.5', fps: 30, letterbox: false);
    final back = Prefs.fromJson(p.toJson());
    expect(back.hostIp, '192.168.1.5');
    expect(back.fps, 30);
    expect(back.letterbox, false);
  });

  test('Prefs.fromJson tolerates missing fields', () {
    final p = Prefs.fromJson(const {});
    expect(p.hostIp, '');
    expect(p.fps, 60);
    expect(p.letterbox, true);
  });

  test('toPrefsJson shape matches SET_PREFS (R1: no mode/aspect/res)', () {
    const p = Prefs(hostIp: 'x', fps: 60, letterbox: true);
    final j = p.toPrefsJson();
    expect(j['fps'], 60);
    expect(j['display'], {'letterbox': true});
    expect(j.containsKey('mode'), false);
    expect(j.containsKey('resolution'), false);
  });

  test('StreamInfo parses CONFIG_ACK', () {
    final s = StreamInfo.fromJson(const {
      'mode': 'extend',
      'aspectRatio': '16:9',
      'virtualWidth': 1920,
      'virtualHeight': 1080,
      'fps': 60,
      'codec': 'h264',
    });
    expect(s.width, 1920);
    expect(s.height, 1080);
    expect(s.aspect, closeTo(1920 / 1080, 0.0001));
  });

  test('ConnState labels/busy', () {
    expect(ConnState.streaming.label, 'Connected');
    expect(ConnState.waiting.isBusy, true);
    expect(ConnState.disconnected.isBusy, false);
  });
}
