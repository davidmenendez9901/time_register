// Generates the launcher icon PNGs into assets/icon/.
//
// This is not part of the regular test suite (it lives in tool/, not test/).
// Run it manually whenever the icon design changes, then regenerate the
// platform launcher icons:
//
//   flutter test tool/generate_icons_test.dart
//   dart run flutter_launcher_icons
//
// The icon (a clock with a coin) is drawn with Canvas so the project does not
// need binary design sources.
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const double _size = 1024;
const Color _bgTop = Color(0xFF3B82F6);
const Color _bgBottom = Color(0xFF1E40AF);
const Color _hands = Color(0xFF1E40AF);
const Color _tickMinor = Color(0xFF94A3B8);
const Color _tickMajor = Color(0xFF475569);
const Color _coinFill = Color(0xFFF59E0B);
const Color _coinRing = Color(0xFFD97706);

Future<void> _loadRoboto() async {
  final flutterRoot = Platform.environment['FLUTTER_ROOT']!;
  final file = File(
    '$flutterRoot/bin/cache/artifacts/material_fonts/Roboto-Bold.ttf',
  );
  final bytes = file.readAsBytesSync();
  final loader = FontLoader('RobotoGen')
    ..addFont(Future.value(ByteData.view(bytes.buffer)));
  await loader.load();
}

void _drawBackground(Canvas canvas) {
  final paint = Paint()
    ..shader = ui.Gradient.linear(const Offset(0, 0), const Offset(0, _size), [
      _bgTop,
      _bgBottom,
    ]);
  canvas.drawRect(const Rect.fromLTWH(0, 0, _size, _size), paint);
}

void _drawClockAndCoin(Canvas canvas) {
  const clockCenter = Offset(512, 480);
  const clockRadius = 330.0;

  // Soft drop shadow under the clock face
  canvas.drawCircle(
    clockCenter.translate(0, 14),
    clockRadius,
    Paint()
      ..color = Colors.black.withValues(alpha: 0.20)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24),
  );

  // Clock face
  canvas.drawCircle(clockCenter, clockRadius, Paint()..color = Colors.white);

  // Tick marks
  for (var i = 0; i < 12; i++) {
    final angle = i * math.pi / 6;
    final isMajor = i % 3 == 0;
    final outer = clockRadius - 36;
    final inner = outer - (isMajor ? 56.0 : 34.0);
    final dir = Offset(math.sin(angle), -math.cos(angle));
    canvas.drawLine(
      clockCenter + dir * inner,
      clockCenter + dir * outer,
      Paint()
        ..color = isMajor ? _tickMajor : _tickMinor
        ..strokeWidth = isMajor ? 20 : 14
        ..strokeCap = StrokeCap.round,
    );
  }

  // Hands at 10:08, the classic friendly watch pose
  final handPaint = Paint()
    ..color = _hands
    ..strokeCap = StrokeCap.round;
  const hourAngle = (10 + 8 / 60) / 12 * 2 * math.pi;
  const minuteAngle = 8 / 60 * 2 * math.pi;
  canvas.drawLine(
    clockCenter,
    clockCenter + Offset(math.sin(hourAngle), -math.cos(hourAngle)) * 150,
    handPaint..strokeWidth = 40,
  );
  canvas.drawLine(
    clockCenter,
    clockCenter + Offset(math.sin(minuteAngle), -math.cos(minuteAngle)) * 215,
    handPaint..strokeWidth = 30,
  );
  canvas.drawCircle(clockCenter, 28, Paint()..color = _hands);

  // Coin overlapping the lower-right edge of the clock
  const coinCenter = Offset(740, 762);
  const coinRadius = 188.0;
  canvas.drawCircle(coinCenter, coinRadius + 18, Paint()..color = Colors.white);
  canvas.drawCircle(coinCenter, coinRadius, Paint()..color = _coinFill);
  canvas.drawCircle(
    coinCenter,
    coinRadius - 34,
    Paint()
      ..color = _coinRing
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14,
  );

  // Dollar sign
  final textPainter = TextPainter(
    text: const TextSpan(
      text: '\$',
      style: TextStyle(
        fontFamily: 'RobotoGen',
        fontSize: 230,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  textPainter.paint(
    canvas,
    coinCenter - Offset(textPainter.width / 2, textPainter.height / 2),
  );
}

Future<void> _savePng(ui.Picture picture, String path) async {
  final image = await picture.toImage(_size.toInt(), _size.toInt());
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(data!.buffer.asUint8List());
}

void main() {
  test('generate launcher icon assets', () async {
    await _loadRoboto();

    // Full icon (legacy launchers, Play Store listing)
    var recorder = ui.PictureRecorder();
    var canvas = Canvas(recorder);
    _drawBackground(canvas);
    _drawClockAndCoin(canvas);
    await _savePng(recorder.endRecording(), 'assets/icon/icon.png');

    // Adaptive foreground: transparent, content scaled into the safe zone
    recorder = ui.PictureRecorder();
    canvas = Canvas(recorder);
    canvas.translate(512, 512);
    canvas.scale(0.58);
    canvas.translate(-512, -512);
    _drawClockAndCoin(canvas);
    await _savePng(recorder.endRecording(), 'assets/icon/icon_foreground.png');

    // Adaptive background: just the gradient
    recorder = ui.PictureRecorder();
    canvas = Canvas(recorder);
    _drawBackground(canvas);
    await _savePng(recorder.endRecording(), 'assets/icon/icon_background.png');

    expect(File('assets/icon/icon.png').existsSync(), isTrue);
  });
}
