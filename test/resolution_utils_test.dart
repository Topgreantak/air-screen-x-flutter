import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:idisplay_client/utils/resolution_utils.dart';

void main() {
  test('16:9 stream on 4:3 screen → letterbox (bars top/bottom)', () {
    final r = fitContent(16 / 9, const Size(1024, 768)); // screen aspect 1.333
    expect(r.x, 0);
    expect(r.width, 1024);
    expect(r.height, closeTo(1024 * 9 / 16, 0.001)); // 576
    expect(r.y, closeTo((768 - 576) / 2, 0.001));     // 96
  });

  test('1:1 stream on wide 21:9 screen → pillarbox (bars left/right)', () {
    final r = fitContent(1.0, const Size(2100, 900)); // screen aspect 2.333 > stream 1.0
    expect(r.y, 0);
    expect(r.height, 900);
    expect(r.width, closeTo(900, 0.001));
    expect(r.x, closeTo((2100 - 900) / 2, 0.001)); // 600
  });

  test('degenerate inputs → empty rect', () {
    expect(fitContent(0, const Size(100, 100)).width, 0);
    expect(fitContent(1.5, const Size(0, 100)).width, 0);
  });

  test('normalizeTouch maps content interior, rejects bars', () {
    final content = fitContent(16 / 9, const Size(1024, 768)); // y=96..672
    final mid = normalizeTouch(512, 384, content);
    expect(mid, isNotNull);
    expect(mid!.dx, closeTo(0.5, 0.001));
    expect(mid.dy, closeTo(0.5, 0.001));

    expect(normalizeTouch(512, 10, content), isNull);  // on top bar
  });
}
