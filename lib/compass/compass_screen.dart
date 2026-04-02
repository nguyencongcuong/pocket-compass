import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:permission_handler/permission_handler.dart';

import 'compass_painter.dart';
import 'heading_smoothing.dart';

/// Maps [0, 360) heading to 8-wind rose abbreviation (45° sectors).
String _headingToCompass8(double degrees) {
  final d = (degrees % 360 + 360) % 360;
  const labels = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
  final idx = ((d + 22.5) ~/ 45) % 8;
  return labels[idx];
}

class CompassScreen extends StatefulWidget {
  const CompassScreen({super.key});

  @override
  State<CompassScreen> createState() => _CompassScreenState();
}

class _CompassScreenState extends State<CompassScreen> {
  StreamSubscription<CompassEvent>? _subscription;
  final HeadingSmoother _smoother = HeadingSmoother();

  bool _permissionGranted = false;
  bool _permissionChecked = false;
  bool _streamMissing = false;
  double? _heading;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final status = await Permission.locationWhenInUse.request();
    if (!mounted) return;
    setState(() {
      _permissionChecked = true;
      _permissionGranted = status.isGranted;
    });
    if (!status.isGranted) return;

    final stream = FlutterCompass.events;
    if (stream == null) {
      setState(() => _streamMissing = true);
      return;
    }

    _subscription = stream.listen(
      (event) {
        final raw = event.heading;
        if (raw == null) return;
        final smoothed = _smoother.smooth(raw);
        if (mounted) {
          setState(() => _heading = smoothed);
        }
      },
      onError: (_) {
        if (mounted) setState(() => _streamMissing = true);
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _retryPermission() async {
    setState(() {
      _permissionChecked = false;
      _permissionGranted = false;
      _streamMissing = false;
      _heading = null;
    });
    _subscription?.cancel();
    _subscription = null;
    _smoother.reset();
    await _bootstrap();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (!_permissionChecked) {
      return Material(
        color: scheme.surface,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!_permissionGranted) {
      return Material(
        color: scheme.surface,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.explore_off, size: 48, color: scheme.primary),
                const SizedBox(height: 16),
                Text(
                  'Location permission is needed for the compass on this device.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _retryPermission,
                  child: const Text('Allow access'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_streamMissing) {
      return Material(
        color: scheme.surface,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sensors_off, size: 48, color: scheme.primary),
                const SizedBox(height: 16),
                Text(
                  'Compass sensor is not available. Try a physical iPhone or Android device.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final heading = _heading;

    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      key: const ValueKey<String>('compass_screen'),
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Heading readout
            Text(
              heading != null
                  ? '${heading.round()}° ${_headingToCompass8(heading)}'
                  : '—',
              style: textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Magnetic north',
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            // Compass dial
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: Size(
                          constraints.maxWidth,
                          constraints.maxHeight,
                        ),
                        painter: CompassPainter(
                          headingDegrees: heading ?? 0,
                          hasHeading: heading != null,
                          colorScheme: scheme,
                        ),
                      ),
                      if (heading == null)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: scheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Waiting for heading…',
                                  style: textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
