import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import 'choose_destination.dart';
import 'choose_destination.dart';

class ChooseColorName extends StatefulWidget {
  const ChooseColorName({super.key});

  @override
  State<ChooseColorName> createState() => _ChooseColorNameState();
}

class _ChooseColorNameState extends State<ChooseColorName> {
  final TextEditingController _nameController = TextEditingController();
  Color? _selectedColor;

  final List<Color> _availableColors = [
    Colors.red,
    Colors.blue,
    const Color.fromARGB(255, 68, 156, 71),
    const Color.fromARGB(255, 154, 143, 44),
    Colors.black,
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final gameProvider = Provider.of<GameProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Color & Name'),
        centerTitle: true,
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(screenSize.width * 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: screenSize.height * 0.02),

            // Choose Name Section
            Text(
              'Choose Name',
              style: TextStyle(
                fontSize: screenSize.width * 0.06,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: screenSize.height * 0.02),

            // Name Input Field
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Enter your name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: screenSize.width * 0.03,
                  vertical: screenSize.height * 0.02,
                ),
              ),
              style: TextStyle(fontSize: screenSize.width * 0.04),
            ),

            SizedBox(height: screenSize.height * 0.04),

            // Choose Color Section
            Text(
              'Choose Color',
              style: TextStyle(
                fontSize: screenSize.width * 0.06,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: screenSize.height * 0.02),

            // Color Selection
            _buildColorSelector(gameProvider),

            SizedBox(height: screenSize.height * 0.05),

            // Submit Button
            ElevatedButton(
              onPressed: _canSubmit() ? _submit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[800],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  vertical: screenSize.height * 0.02,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Join Game',
                style: TextStyle(
                  fontSize: screenSize.width * 0.05,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            SizedBox(height: screenSize.height * 0.02),

            // Info text
            Text(
              'You will select destination cards after the host starts the game',
              style: TextStyle(
                fontSize: screenSize.width * 0.035,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  bool _canSubmit() {
    return _nameController.text.trim().isNotEmpty && _selectedColor != null;
  }

  void _submit() async {
    if (_canSubmit()) {
      final gameProvider = Provider.of<GameProvider>(context, listen: false);
      final playerName = _nameController.text.trim();
      final playerColor = _selectedColor!;

      // Final check to ensure the color hasn't been taken
      if (gameProvider.players.any((p) => p.color == playerColor)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Color was just taken. Please choose another.')),
        );
        return;
      }

      // Add the player to the game state
      gameProvider.addPlayer(playerName, playerColor);

      // Show success message and navigate to waiting screen
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Joined as $playerName! Waiting for host to start game...'),
            duration: const Duration(seconds: 3),
          ),
        );

        // Navigate to a waiting screen instead of destination selection
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const WaitingForGameStart(),
          ),
        );
      }
    }
  }

  Widget _buildColorSelector(GameProvider gameProvider) {
    // Get colors already taken by other players
    final takenColors = gameProvider.players.map((p) => p.color).toSet();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: _availableColors.map((color) {
        final isTaken = takenColors.contains(color);

        return GestureDetector(
          onTap: isTaken
              ? null
              : () {
                  setState(() {
                    _selectedColor = color;
                  });
                },
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: _selectedColor == color ? Colors.white : Colors.black26,
                width: 3,
              ),
            ),
            child: isTaken
                ? const Icon(Icons.close, color: Colors.white, size: 24)
                : (_selectedColor == color
                    ? const Icon(Icons.check, color: Colors.white, size: 24)
                    : null),
          ),
        );
      }).toList(),
    );
  }
}

// NEW: Waiting screen that players see after joining
class WaitingForGameStart extends StatelessWidget {
  const WaitingForGameStart({super.key});

  @override
  Widget build(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context);

    // Once game starts, navigate to destination selection
    if (gameProvider.gameStarted) {
      // Find this player's index
      // Note: This is a simplified approach. In production, you'd want to identify
      // players by a unique ID rather than relying on list order
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Get the current player (last in the list, the one who just joined)
        final playerIndex = gameProvider.players.length - 1;
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ChooseDestination(
              isInitialSelection: true,
              playerIndex: playerIndex,
            ),
          ),
        );
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Waiting for Game'),
        centerTitle: true,
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 30),
            const Text(
              'Waiting for host to start the game...',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Players in lobby: ${gameProvider.players.length}',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 30),
            
            // Show all players in the lobby
            Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                children: [
                  const Text(
                    'Players in Lobby:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...gameProvider.players.map((player) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: player.color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.black,
                                width: 2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            player.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            const Text(
              'You will select destination cards once the game starts',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}