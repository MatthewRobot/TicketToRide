import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
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

    // Check if this user already joined
    if (gameProvider.myPlayerIndex != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const WaitingForGameStart(),
          ),
        );
      });
    }

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

            Text(
              'Choose Name',
              style: TextStyle(
                fontSize: screenSize.width * 0.06,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: screenSize.height * 0.02),

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

            Text(
              'Choose Color',
              style: TextStyle(
                fontSize: screenSize.width * 0.06,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: screenSize.height * 0.02),

            _buildColorSelector(gameProvider),

            SizedBox(height: screenSize.height * 0.05),

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

      // Attempt to add player (will fail if color taken)
      final success = await gameProvider.addPlayer(playerName, playerColor);

      if (!success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Color was just taken or you already joined. Please choose another.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Success - navigate to waiting screen
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Joined as $playerName! Waiting for host to start game...'),
            duration: const Duration(seconds: 3),
          ),
        );

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
    // Get colors already taken by other players (real-time)
    final takenColors = gameProvider.players.map((p) => p.color).toSet();

    // Auto-deselect if color was taken
    if (_selectedColor != null && takenColors.contains(_selectedColor)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _selectedColor = null;
        });
      });
    }

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

class WaitingForGameStart extends StatefulWidget {
  const WaitingForGameStart({super.key});

  @override
  State<WaitingForGameStart> createState() => _WaitingForGameStartState();
}

class _WaitingForGameStartState extends State<WaitingForGameStart> {
  bool _hasNavigated = false;

  @override
  Widget build(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context);

    print('=== WaitingForGameStart build ===');
    print('Game started: ${gameProvider.gameStarted}');
    print('My player index: ${gameProvider.myPlayerIndex}');
    print('Has navigated: $_hasNavigated');

    // Once game starts, navigate to destination selection
    if (gameProvider.gameStarted && gameProvider.myPlayerIndex != null && !_hasNavigated) {
      print('Navigating to ChooseDestination...');
      _hasNavigated = true;
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ChooseDestination(
                isInitialSelection: true,
                playerIndex: gameProvider.myPlayerIndex!,
              ),
            ),
          );
        }
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
                    final isMe = gameProvider.myPlayerIndex != null && 
                                gameProvider.players[gameProvider.myPlayerIndex!].userId == player.userId;
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
                            player.name + (isMe ? ' (You)' : ''),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isMe ? FontWeight.bold : FontWeight.w500,
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