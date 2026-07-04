import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

class IDisplayApp extends StatelessWidget {
  const IDisplayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'iDisplay',
      theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}
