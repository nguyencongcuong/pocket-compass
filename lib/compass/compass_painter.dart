import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Compass with rotating card (degrees + cardinals) and a fixed red arrow toward north.
class CompassPainter extends CustomPainter {
  CompassPainter({
    required this.headingDegrees,
    required this.hasHeading,
    required this.colorScheme,
  });

  /// Device heading in degrees (0 = top of phone toward north, clockwise). Drives dial rotation and north arrow.
  final double headingDegrees;
  final bool hasHeading;
  final ColorScheme colorScheme;

  static const double _degToRad = math.pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    final shortest = math.min(size.width, size.height);
    final center = Offset(size.width / 2, size.height / 2);

    final baseW = shortest * 0.88;
    final baseH = shortest * 0.98;
    final housingR = shortest * 0.34;
    final bezelOuterR = housingR * 1.22;

    final baseplateRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: center,
        width: baseW,
        height: baseH,
      ),
      Radius.circular(shortest * 0.04),
    );

    final baseFill = Paint()
      ..color = colorScheme.surfaceContainerHighest.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
    final baseStroke = Paint()
      ..color = colorScheme.outline.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = shortest * 0.006;

    canvas.drawRRect(baseplateRect, baseFill);
    canvas.drawRRect(baseplateRect, baseStroke);

    _drawDirectionOfTravelArrow(canvas, center, baseH, shortest);

    final H = hasHeading ? headingDegrees : 0.0;
    // Rotating card: N on dial stays on geographic north. If dial and arrow drift together
    // on your device, flip the sign (use +H * _degToRad instead).
    final dialRotationRad = -H * _degToRad;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(dialRotationRad);
    canvas.translate(-center.dx, -center.dy);

    _drawHousingDisc(canvas, center, housingR, shortest);
    _drawBezel(canvas, center, housingR, bezelOuterR, shortest);
    _drawOrientingLines(canvas, center, housingR, shortest);
    _drawOrientingArrow(canvas, center, housingR, shortest);

    canvas.restore();

    final innerRim = Paint()
      ..color = colorScheme.outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = shortest * 0.008;
    canvas.drawCircle(center, housingR, innerRim);

    final outerRim = Paint()
      ..color = colorScheme.outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = shortest * 0.005;
    canvas.drawCircle(center, bezelOuterR, outerRim);

    _drawIndexLine(canvas, center, bezelOuterR, shortest);

    if (hasHeading) {
      _drawFixedNorthArrow(canvas, center, housingR, shortest, H);
    }
  }

  void _drawHousingDisc(
    Canvas canvas,
    Offset center,
    double housingR,
    double shortest,
  ) {
    final housingFill = Paint()
      ..shader = ui.Gradient.radial(
        center,
        housingR,
        [
          colorScheme.surfaceContainerLow,
          colorScheme.surfaceContainerHigh,
        ],
      );
    canvas.drawCircle(center, housingR, housingFill);
  }

  void _drawDirectionOfTravelArrow(
    Canvas canvas,
    Offset center,
    double baseH,
    double shortest,
  ) {
    final tipY = center.dy - baseH * 0.46;
    final tailY = center.dy - baseH * 0.12;
    final halfW = shortest * 0.07;

    final path = Path()
      ..moveTo(center.dx, tipY)
      ..lineTo(center.dx + halfW, tailY)
      ..lineTo(center.dx - halfW, tailY)
      ..close();

    final fill = Paint()
      ..color = colorScheme.primary
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = colorScheme.onPrimary.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = shortest * 0.004;

    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);

    final stem = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx, tailY + shortest * 0.04),
        width: shortest * 0.05,
        height: shortest * 0.08,
      ),
      Radius.circular(shortest * 0.012),
    );
    canvas.drawRRect(stem, fill);
  }

  void _drawBezel(
    Canvas canvas,
    Offset center,
    double housingR,
    double outerR,
    double shortest,
  ) {
    final tickPaint = Paint()
      ..color = colorScheme.onSurface.withValues(alpha: 0.75)
      ..strokeWidth = shortest * 0.004
      ..strokeCap = StrokeCap.round;

    final labelStyle = TextStyle(
      color: colorScheme.onSurface.withValues(alpha: 0.85),
      fontSize: shortest * 0.055,
      fontWeight: FontWeight.w600,
    );

    // Clockwise-from-north on screen: up = N, right = E (+y is down).
    for (var deg = 0; deg < 360; deg += 10) {
      final rad = -math.pi / 2 + deg * _degToRad;
      final isMajor = deg % 30 == 0;
      final inner = outerR - (isMajor ? shortest * 0.04 : shortest * 0.022);
      final outer = outerR - shortest * 0.006;
      final c = math.cos(rad);
      final s = math.sin(rad);
      canvas.drawLine(
        Offset(center.dx + c * inner, center.dy + s * inner),
        Offset(center.dx + c * outer, center.dy + s * outer),
        tickPaint,
      );

      if (isMajor && deg % 90 != 0) {
        final labelR = outerR - shortest * 0.11;
        final tp = TextPainter(
          text: TextSpan(text: '$deg', style: labelStyle),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(
          canvas,
          Offset(
            center.dx + c * labelR - tp.width / 2,
            center.dy + s * labelR - tp.height / 2,
          ),
        );
      }
    }

    for (final label in _cardinalLabels()) {
      final rad = -math.pi / 2 + label.degrees * _degToRad;
      final c = math.cos(rad);
      final s = math.sin(rad);
      final labelR = outerR - shortest * 0.13;
      final tp = TextPainter(
        text: TextSpan(
          text: label.text,
          style: labelStyle.copyWith(
            fontSize: shortest * 0.07,
            color: label.color ?? labelStyle.color,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(
          center.dx + c * labelR - tp.width / 2,
          center.dy + s * labelR - tp.height / 2,
        ),
      );
    }
  }

  List<({String text, double degrees, Color? color})> _cardinalLabels() {
    return [
      (text: 'N', degrees: 0, color: Colors.red.shade700),
      (text: 'E', degrees: 90, color: null),
      (text: 'S', degrees: 180, color: null),
      (text: 'W', degrees: 270, color: null),
    ];
  }

  void _drawIndexLine(
    Canvas canvas,
    Offset center,
    double outerR,
    double shortest,
  ) {
    final top = Offset(center.dx, center.dy - outerR - shortest * 0.02);
    final path = Path()
      ..moveTo(top.dx - shortest * 0.04, top.dy + shortest * 0.02)
      ..lineTo(top.dx, top.dy - shortest * 0.02)
      ..lineTo(top.dx + shortest * 0.04, top.dy + shortest * 0.02);

    final paint = Paint()
      ..color = colorScheme.onSurface
      ..style = PaintingStyle.stroke
      ..strokeWidth = shortest * 0.006
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, paint);
  }

  void _drawOrientingLines(
    Canvas canvas,
    Offset center,
    double housingR,
    double shortest,
  ) {
    final paint = Paint()
      ..color = colorScheme.outline.withValues(alpha: 0.45)
      ..strokeWidth = shortest * 0.003
      ..style = PaintingStyle.stroke;

    final gap = housingR * 0.14;
    final top = center.dy - housingR * 0.72;
    final bottom = center.dy + housingR * 0.55;
    canvas.drawLine(Offset(center.dx - gap, top), Offset(center.dx - gap, bottom), paint);
    canvas.drawLine(Offset(center.dx + gap, top), Offset(center.dx + gap, bottom), paint);
  }

  void _drawOrientingArrow(
    Canvas canvas,
    Offset center,
    double housingR,
    double shortest,
  ) {
    final tipY = center.dy + housingR * 0.38;
    final shoulderY = center.dy + housingR * 0.12;
    final halfW = housingR * 0.22;

    final path = Path()
      ..moveTo(center.dx, tipY)
      ..lineTo(center.dx + halfW, shoulderY)
      ..lineTo(center.dx + halfW * 0.35, shoulderY)
      ..lineTo(center.dx + halfW * 0.35, center.dy - housingR * 0.08)
      ..lineTo(center.dx - halfW * 0.35, center.dy - housingR * 0.08)
      ..lineTo(center.dx - halfW * 0.35, shoulderY)
      ..lineTo(center.dx - halfW, shoulderY)
      ..close();

    final stroke = Paint()
      ..color = Colors.red.shade700
      ..style = PaintingStyle.stroke
      ..strokeWidth = shortest * 0.005;
    canvas.drawPath(path, stroke);
  }

  /// Fixed in screen space: points toward north on the glass (angle from +x, clockwise).
  void _drawFixedNorthArrow(
    Canvas canvas,
    Offset center,
    double housingR,
    double shortest,
    double headingDeg,
  ) {
    final northAngle = -math.pi / 2 - headingDeg * _degToRad;
    final tipLen = housingR * 0.82;
    final tip = Offset(
      center.dx + tipLen * math.cos(northAngle),
      center.dy + tipLen * math.sin(northAngle),
    );
    final perp = northAngle + math.pi / 2;
    final halfW = shortest * 0.038;
    final baseMidDist = shortest * 0.02;
    final baseMid = Offset(
      center.dx - baseMidDist * math.cos(northAngle),
      center.dy - baseMidDist * math.sin(northAngle),
    );
    final b1 = Offset(
      baseMid.dx + halfW * math.cos(perp),
      baseMid.dy + halfW * math.sin(perp),
    );
    final b2 = Offset(
      baseMid.dx - halfW * math.cos(perp),
      baseMid.dy - halfW * math.sin(perp),
    );

    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(b2.dx, b2.dy)
      ..lineTo(b1.dx, b1.dy)
      ..close();

    final fill = Paint()..color = Colors.red.shade700;
    final outline = Paint()
      ..color = colorScheme.onSurface.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = shortest * 0.003;

    canvas.drawPath(path, fill);
    canvas.drawPath(path, outline);

    canvas.drawCircle(center, shortest * 0.024, Paint()..color = colorScheme.surface);
    canvas.drawCircle(
      center,
      shortest * 0.024,
      Paint()
        ..color = colorScheme.outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = shortest * 0.003,
    );
  }

  @override
  bool shouldRepaint(covariant CompassPainter oldDelegate) {
    return oldDelegate.headingDegrees != headingDegrees ||
        oldDelegate.hasHeading != hasHeading ||
        oldDelegate.colorScheme != colorScheme;
  }
}
