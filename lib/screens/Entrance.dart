import 'package:flutter/material.dart';
import 'choose_color_name.dart';
import 'host_screen.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
// IMPORTANT: You'll need to import your AuthService and AuthScreen here
import '../services/auth_service.dart';
import 'auth_screen.dart'; 
// Assuming AuthScreen is your login/auth screen widget

class Entrance extends StatefulWidget {
  const Entrance({super.key});

  @override
  State<Entrance> createState() => _Entrance();
}

class _Entrance extends State<Entrance> {
  final TextEditingController _gameIdController = TextEditingController();

  @override
  void dispose() {
    _gameIdController.dispose();
    super.dispose();
  }

  // New _logOut method to handle the sign-out process
  void _logOut(BuildContext context) async {
    await Provider.of<AuthService>(context, listen: false).signOut();
    
    // 1. Navigate back to the login/auth screen.
    // Use pushAndRemoveUntil to clear the navigation history completely.
    // Navigator.pushAndRemoveUntil(
    //   context,
    //   MaterialPageRoute(builder: (context) => const AuthScreen()
    //   ),
    //   (route) => false, // Remove all previous routes
    // );
  }

  @override
  Widget build(BuildContext context) {
    // 1. Access the AuthService using Provider.of, setting listen: true
    //    so the widget rebuilds when the authentication state changes.
    final authService = Provider.of<AuthService>(context);
    
    // 2. Get the current user. Assuming AuthService has a 'currentUser' property
    //    that returns a user object (which has an 'email' property).
    //    If the user is not logged in, this will likely be null.
    final userEmail = authService.currentUser?.email ?? 'Guest';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ticket to Ride'),
        centerTitle: true,
        // --- LOG OUT BUTTON ADDED HERE ---
        actions: [
          TextButton.icon(
            onPressed: () => _logOut(context),
            icon: const Icon(Icons.logout, color: Color.fromARGB(255, 13, 12, 12)),
            label: const Text(
              'Log Out',
              style: TextStyle(color: Color.fromARGB(255, 2, 2, 2)),
            ),
          ),
        ],
        // ---------------------------------
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome to Ticket to Ride! $userEmail',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 50),
            SizedBox(
              child: TextField(
                controller: _gameIdController,
                decoration: const InputDecoration(
                  labelText: 'Enter Game ID',
                  hintText: 'e.g., ABC-123',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.vpn_key),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _joinGame(context), // Call the new join function
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                textStyle: const TextStyle(fontSize: 18),
              ),
              child: const Text('Join Game'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HostScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                textStyle: const TextStyle(fontSize: 18),
              ),
              child: const Text('Host Game'),
            ),
          ],
        ),
      ),
    );
  }

// New _joinGame method outside of build
  void _joinGame(BuildContext context) async {
    final gameId = _gameIdController.text.trim();
    if (gameId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a Game ID.')),
      );
      return;
    }

    final gameProvider = Provider.of<GameProvider>(context, listen: false);

    // 1. Connect to the Firestore document stream
    await gameProvider.connectToGame(gameId);

    // 2. Navigate to choose name/color.
    // The game state will now be synchronized before the player adds themselves.
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ChooseColorName()),
    );
  }
}