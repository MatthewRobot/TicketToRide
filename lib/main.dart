import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ticket_to_ride/screens/entrance.dart';
import 'package:ticket_to_ride/providers/game_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MainAppState createState() => _MainAppState();
}

class _MainAppState extends State<MyApp> {
  ThemeMode themeMode = ThemeMode.system;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => GameProvider(),
      child: MaterialApp(
        title: 'Ticket to Ride',
        home: const Entrance(),
      ),
    );
  }
}
