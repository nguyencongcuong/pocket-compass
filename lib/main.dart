import 'package:flutter/material.dart';

import 'compass/compass_screen.dart';

void main() {
  runApp(const PocketCompassApp());
}

class PocketCompassApp extends StatelessWidget {
  const PocketCompassApp({super.key});

  static const _seed = Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pocket Compass',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seed,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seed,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const CompassScreen(),
    );
  }
}
