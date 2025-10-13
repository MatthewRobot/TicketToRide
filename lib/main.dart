import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ticket_to_ride/screens/entrance.dart';
import 'package:ticket_to_ride/providers/game_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async { // Mark the function as asynchronous (async)

  // 1. Ensure Flutter Widgets are initialized
  // This is mandatory before calling any plugin code, including Firebase.
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize Firebase
  // This uses the platform-specific options from the generated file.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 3. Run your application
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
