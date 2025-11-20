import 'package:flutter/material.dart';
import 'package:trash_dash_demo/screens/map_screen.dart';

void main() {
  runApp(const TrashDashApp());
}

class TrashDashApp extends StatelessWidget {
  const TrashDashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TrashDash',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const MapScreen(),
    );
  }
}
