import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'services/connection_controller.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ConnectionController()..init(),
      child: const IDisplayApp(),
    ),
  );
}
