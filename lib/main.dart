import 'package:flutter/material.dart';

import 'compass/compass_screen.dart';

void main() {
  runApp(const PocketCompassApp());
}

class PocketCompassApp extends StatelessWidget {
  const PocketCompassApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pocket Compass',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const CompassScreen(),
    );
  }
}
