import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Baseplate-style compass: housing, bezel, orienting marks, DOT arrow, needle.
class CompassPainter extends CustomPainter {
  CompassPainter({
    required this.headingDegrees,
    required this.hasHeading,
    required this.colorScheme,
  });

  /// Smoothed magnetic heading, 0 = north, clockwise. Ignored if [hasHeading] is false.
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

    final housingFill = Paint()
      ..shader = ui.Gradient.radial(
        center,
        housingR,
        [
          colorScheme.surfaceContainerLow,
          colorScheme.surfaceContainerHigh,
        ],
      );
    final housingBorder = Paint()
      ..color = colorScheme.outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = shortest * 0.008;

    canvas.drawCircle(center, housingR, housingFill);
    canvas.drawCircle(center, housingR, housingBorder);

    _drawBezel(canvas, center, housingR, bezelOuterR, shortest);
    _drawIndexLine(canvas, center, bezelOuterR, shortest);
    _drawOrientingLines(canvas, center, housingR, shortest);
    _drawOrientingArrow(canvas, center, housingR, shortest);

    if (hasHeading) {
      _drawNeedle(canvas, center, housingR, shortest);
    }
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

    for (var deg = 0; deg < 360; deg += 10) {
      final rad = -math.pi / 2 - deg * _degToRad;
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
      final rad = -math.pi / 2 - label.degrees * _degToRad;
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

  void _drawNeedle(
    Canvas canvas,
    Offset center,
    double housingR,
    double shortest,
  ) {
    final rotation = (360 - headingDegrees) * _degToRad;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    final northLen = housingR * 0.72;
    final southLen = housingR * 0.52;
    final w = shortest * 0.028;

    final northPath = Path()
      ..moveTo(-w, 0)
      ..lineTo(0, -northLen)
      ..lineTo(w, 0)
      ..close();

    final southPath = Path()
      ..moveTo(-w * 0.85, 0)
      ..lineTo(0, southLen)
      ..lineTo(w * 0.85, 0)
      ..close();

    final northPaint = Paint()..color = Colors.red.shade700;
    final southPaint = Paint()..color = Colors.grey.shade200;
    final outline = Paint()
      ..color = colorScheme.onSurface.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = shortest * 0.003;

    canvas.drawPath(northPath, northPaint);
    canvas.drawPath(southPath, southPaint);
    canvas.drawPath(northPath, outline);
    canvas.drawPath(southPath, outline);

    canvas.drawCircle(Offset.zero, shortest * 0.022, Paint()..color = colorScheme.surface);
    canvas.drawCircle(
      Offset.zero,
      shortest * 0.022,
      Paint()
        ..color = colorScheme.outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = shortest * 0.003,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CompassPainter oldDelegate) {
    return oldDelegate.headingDegrees != headingDegrees ||
        oldDelegate.hasHeading != hasHeading ||
        oldDelegate.colorScheme != colorScheme;
  }
}
