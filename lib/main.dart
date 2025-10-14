import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart'; // NEW: Firebase Auth Import
import 'providers/game_provider.dart';
import 'screens/Entrance.dart';
import '../services/auth_service.dart';
import 'package:ticket_to_ride/screens/auth_screen.dart'; // NEW: Auth Screen Import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider( // CHANGED: Use MultiProvider instead of ChangeNotifierProvider
      providers: [
        // 1. Provide the Auth Service
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
        // 2. Provide the Game Provider (which now requires a userId)
        ChangeNotifierProvider(
          // We pass an empty string initially, the AuthWrapper will update it.
          create: (_) => GameProvider(userId: ''), 
        ),
      ],
      child: MaterialApp(
        title: 'Ticket to Ride',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: const AuthWrapper(), // CHANGED: Route to AuthWrapper
      ),
    );
  }
}

/// A wrapper widget that listens to the authentication state and
/// directs the user to the appropriate screen.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Look up the AuthService provided above
    final authService = Provider.of<AuthService>(context);

    // StreamBuilder listens for changes in the user's login status
    return StreamBuilder<User?>(
      stream: authService.user,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final user = snapshot.data;

        if (user == null) {
          // User is NOT logged in, show the authentication screen
          return const AuthScreen();
        } else {
          // User IS logged in, update GameProvider with UID and show main app
          WidgetsBinding.instance.addPostFrameCallback((_) {
             Provider.of<GameProvider>(context, listen: false).updateUserId(user.uid);
          });
          return const Entrance();
        }
      },
    );
  }
}
