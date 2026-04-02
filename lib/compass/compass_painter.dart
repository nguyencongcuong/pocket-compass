import 'dart:math' as math;

import 'package:flutter/material.dart';

class CompassPainter extends CustomPainter {
  CompassPainter({
    required this.headingDegrees,
    required this.hasHeading,
    required this.colorScheme,
  });

  final double headingDegrees;
  final bool hasHeading;
  final ColorScheme colorScheme;

  static const double _deg2rad = math.pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    final shortest = math.min(size.width, size.height);
    final center = Offset(size.width / 2, size.height / 2);

    final outerR = shortest * 0.44;
    final innerR = shortest * 0.34;
    final labelR = shortest * 0.365;
    final tickOuterR = outerR - shortest * 0.005;

    final H = hasHeading ? headingDegrees : 0.0;
    final dialRad = -H * _deg2rad;

    // --- Rotating group (card) ---
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(dialRad);
    canvas.translate(-center.dx, -center.dy);

    _drawInnerDisc(canvas, center, innerR, shortest);
    _drawTicks(canvas, center, innerR, tickOuterR, shortest);
    _drawRadialLabels(canvas, center, labelR, shortest);

    canvas.restore();

    // --- Fixed overlays ---
    _drawOuterRim(canvas, center, outerR, shortest);
    _drawIndexMark(canvas, center, outerR, shortest);

    if (hasHeading) {
      _drawNorthArrow(canvas, center, innerR, shortest, H);
    }
  }

  // ─── Inner disc ──────────────────────────────────────────────

  void _drawInnerDisc(
    Canvas canvas,
    Offset center,
    double r,
    double shortest,
  ) {
    canvas.drawCircle(
      center,
      r,
      Paint()..color = colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
    );
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = colorScheme.outlineVariant.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = shortest * 0.003,
    );
  }

  // ─── Tick marks ──────────────────────────────────────────────

  void _drawTicks(
    Canvas canvas,
    Offset center,
    double innerR,
    double outerR,
    double shortest,
  ) {
    for (var deg = 0; deg < 360; deg += 2) {
      final isMajor = deg % 30 == 0;
      final isMedium = deg % 10 == 0;

      double tickInner;
      double alpha;
      double width;
      if (isMajor) {
        tickInner = outerR - shortest * 0.040;
        alpha = 0.85;
        width = shortest * 0.005;
      } else if (isMedium) {
        tickInner = outerR - shortest * 0.025;
        alpha = 0.55;
        width = shortest * 0.003;
      } else {
        tickInner = outerR - shortest * 0.013;
        alpha = 0.25;
        width = shortest * 0.002;
      }

      final rad = -math.pi / 2 + deg * _deg2rad;
      final c = math.cos(rad);
      final s = math.sin(rad);

      canvas.drawLine(
        Offset(center.dx + c * tickInner, center.dy + s * tickInner),
        Offset(center.dx + c * outerR, center.dy + s * outerR),
        Paint()
          ..color = colorScheme.onSurface.withValues(alpha: alpha)
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  // ─── Radially-rotated labels ─────────────────────────────────

  void _drawRadialLabels(
    Canvas canvas,
    Offset center,
    double labelR,
    double shortest,
  ) {
    final degStyle = TextStyle(
      color: colorScheme.onSurface.withValues(alpha: 0.78),
      fontSize: shortest * 0.042,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
    );

    final cardinalStyle = TextStyle(
      color: colorScheme.onSurface.withValues(alpha: 0.92),
      fontSize: shortest * 0.062,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.5,
    );

    const cardinals = {0: 'N', 90: 'E', 180: 'S', 270: 'W'};

    for (var deg = 0; deg < 360; deg += 30) {
      final isCardinal = cardinals.containsKey(deg);
      final text = isCardinal ? cardinals[deg]! : '$deg';
      var style = isCardinal ? cardinalStyle : degStyle;
      if (deg == 0) {
        style = style.copyWith(color: Colors.red.shade600);
      }

      final tp = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
      )..layout();

      final theta = deg * _deg2rad;
      final inBottomHalf = deg > 90 && deg < 270;

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(theta);

      if (inBottomHalf) {
        canvas.rotate(math.pi);
        tp.paint(canvas, Offset(-tp.width / 2, labelR - tp.height));
      } else {
        tp.paint(canvas, Offset(-tp.width / 2, -labelR - tp.height));
      }
      canvas.restore();
    }
  }

  // ─── Fixed outer rim ─────────────────────────────────────────

  void _drawOuterRim(
    Canvas canvas,
    Offset center,
    double r,
    double shortest,
  ) {
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = colorScheme.outlineVariant.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = shortest * 0.004,
    );
  }

  // ─── Index mark (12 o'clock) ─────────────────────────────────

  void _drawIndexMark(
    Canvas canvas,
    Offset center,
    double outerR,
    double shortest,
  ) {
    final tipY = center.dy - outerR - shortest * 0.012;
    final baseY = center.dy - outerR + shortest * 0.022;
    final halfW = shortest * 0.024;

    final path = Path()
      ..moveTo(center.dx, tipY)
      ..lineTo(center.dx - halfW, baseY)
      ..lineTo(center.dx + halfW, baseY)
      ..close();

    canvas.drawPath(path, Paint()..color = colorScheme.primary);
    canvas.drawPath(
      path,
      Paint()
        ..color = colorScheme.outline.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = shortest * 0.002,
    );
  }

  // ─── Fixed north arrow ───────────────────────────────────────

  void _drawNorthArrow(
    Canvas canvas,
    Offset center,
    double innerR,
    double shortest,
    double headingDeg,
  ) {
    final northAngle = -math.pi / 2 - headingDeg * _deg2rad;
    final tipLen = innerR * 0.88;
    final baseLen = shortest * 0.025;
    final halfW = shortest * 0.032;

    final tip = Offset(
      center.dx + tipLen * math.cos(northAngle),
      center.dy + tipLen * math.sin(northAngle),
    );
    final perp = northAngle + math.pi / 2;
    final baseMid = Offset(
      center.dx - baseLen * math.cos(northAngle),
      center.dy - baseLen * math.sin(northAngle),
    );
    final b1 = Offset(
      baseMid.dx + halfW * math.cos(perp),
      baseMid.dy + halfW * math.sin(perp),
    );
    final b2 = Offset(
      baseMid.dx - halfW * math.cos(perp),
      baseMid.dy - halfW * math.sin(perp),
    );

    final northPath = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(b1.dx, b1.dy)
      ..lineTo(b2.dx, b2.dy)
      ..close();

    canvas.drawPath(northPath, Paint()..color = Colors.red.shade600);
    canvas.drawPath(
      northPath,
      Paint()
        ..color = colorScheme.onSurface.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = shortest * 0.003,
    );

    // South half (opposite direction)
    final southAngle = northAngle + math.pi;
    final southTipLen = innerR * 0.52;
    final southTip = Offset(
      center.dx + southTipLen * math.cos(southAngle),
      center.dy + southTipLen * math.sin(southAngle),
    );
    final southPath = Path()
      ..moveTo(southTip.dx, southTip.dy)
      ..lineTo(b1.dx, b1.dy)
      ..lineTo(b2.dx, b2.dy)
      ..close();

    canvas.drawPath(
      southPath,
      Paint()..color = colorScheme.onSurface.withValues(alpha: 0.2),
    );
    canvas.drawPath(
      southPath,
      Paint()
        ..color = colorScheme.onSurface.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = shortest * 0.002,
    );

    // Pivot dot
    canvas.drawCircle(
      center,
      shortest * 0.02,
      Paint()..color = colorScheme.surface,
    );
    canvas.drawCircle(
      center,
      shortest * 0.02,
      Paint()
        ..color = colorScheme.outline.withValues(alpha: 0.4)
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
