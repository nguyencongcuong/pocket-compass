import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geomag/geomag.dart';
import 'package:package_info_plus/package_info_plus.dart';
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

class _CompassScreenState extends State<CompassScreen>
    with SingleTickerProviderStateMixin {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  StreamSubscription<CompassEvent>? _subscription;
  final HeadingSmoother _smoother = HeadingSmoother();
  static final GeoMag _geoMag = GeoMag();

  bool _permissionGranted = false;
  bool _permissionChecked = false;
  bool _streamMissing = false;

  double? _heading;
  double? _declination;
  bool _waitingForGps = true;
  String _appVersion = '';

  // --- Animation state ---
  late final Ticker _ticker;
  double _animatedHeading = 0;
  bool _hasAnimTarget = false;
  Duration _lastTick = Duration.zero;

  /// Exponential-decay rate: higher = snappier. 8 gives ~120ms settle time.
  static const double _lerpSpeed = 8.0;

  double? get _targetHeading {
    final h = _heading;
    if (h == null) return null;
    final dec = _declination;
    if (dec == null) return h;
    return (h + dec + 360) % 360;
  }

  bool get _isTrueNorth => _declination != null;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
    _loadVersion();
    _bootstrap();
  }

  void _onTick(Duration elapsed) {
    final target = _targetHeading;
    if (target == null) return;

    if (!_hasAnimTarget) {
      _animatedHeading = target;
      _hasAnimTarget = true;
      _lastTick = elapsed;
      setState(() {});
      return;
    }

    final dtSec = _lastTick == Duration.zero
        ? 1 / 60
        : (elapsed - _lastTick).inMicroseconds / 1e6;
    _lastTick = elapsed;

    double diff = target - _animatedHeading;
    while (diff > 180) {
      diff -= 360;
    }
    while (diff < -180) {
      diff += 360;
    }

    if (diff.abs() < 0.01) {
      if (_animatedHeading != target) {
        _animatedHeading = target;
        setState(() {});
      }
      return;
    }

    final t = 1.0 - math.exp(-_lerpSpeed * dtSec);
    _animatedHeading = (_animatedHeading + diff * t + 360) % 360;
    setState(() {});
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() => _appVersion = '${info.version}+${info.buildNumber}');
    }
  }

  Future<void> _bootstrap() async {
    final status = await Permission.locationWhenInUse.request();
    if (!mounted) return;
    setState(() {
      _permissionChecked = true;
      _permissionGranted = status.isGranted;
    });
    if (!status.isGranted) return;

    _startCompass();
    _fetchDeclination();
  }

  void _startCompass() {
    final stream = FlutterCompass.events;
    if (stream == null) {
      setState(() => _streamMissing = true);
      return;
    }

    _subscription = stream.listen(
      (event) {
        final raw = event.heading;
        if (raw == null) return;
        _heading = _smoother.smooth(raw);
      },
      onError: (_) {
        if (mounted) setState(() => _streamMissing = true);
      },
    );
  }

  Future<void> _fetchDeclination() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 15),
        ),
      );
      if (!mounted) return;

      final result = _geoMag.calculate(
        position.latitude,
        position.longitude,
      );
      setState(() {
        _declination = result.dec;
        _waitingForGps = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _waitingForGps = false);
      }
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _retryPermission() async {
    setState(() {
      _permissionChecked = false;
      _permissionGranted = false;
      _streamMissing = false;
      _heading = null;
      _declination = null;
      _waitingForGps = true;
      _hasAnimTarget = false;
      _lastTick = Duration.zero;
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

    final heading = _hasAnimTarget ? _animatedHeading : null;
    final textTheme = Theme.of(context).textTheme;
    final northLabel = _isTrueNorth ? 'True north' : 'Magnetic north';

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: const Text('Pocket Compass'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Settings',
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          ),
        ],
      ),
      endDrawer: NavigationDrawer(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Text(
              'Settings',
              style: textTheme.titleMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          const Divider(indent: 24, endIndent: 24),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Version'),
            subtitle: Text(_appVersion.isEmpty ? '…' : _appVersion),
            contentPadding: const EdgeInsets.symmetric(horizontal: 24),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
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
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  northLabel,
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                if (_waitingForGps && _heading != null) ...[
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 10,
                    height: 10,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
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
