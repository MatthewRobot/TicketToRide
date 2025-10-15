import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For clipboard
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ticket_to_ride/widgets/interactive_map_widget.dart';
import '../providers/game_provider.dart';
import 'player_screen.dart';
import '../models/destination.dart';
import '../models/card.dart' as game_card;

class HostScreen extends StatefulWidget {
  const HostScreen({super.key});

  @override
  State<HostScreen> createState() => _HostScreenState();
}

class _HostScreenState extends State<HostScreen> {
  String? _displayedGameId; // Store the game ID
  bool _isInitializing = false; // Track initialization

  @override
  void initState() {
    super.initState();
    // Automatically create game when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _createGameIfNeeded();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _createGameIfNeeded() async {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);

    if (_displayedGameId == null && !_isInitializing) {
      setState(() {
        _isInitializing = true;
      });

      final newGameRef = FirebaseFirestore.instance.collection('games').doc();
      final gameId = newGameRef.id;

      try {
        // 1. Connection (Log is expected)
        await gameProvider.connectToGame(gameId);

        // 2. CRITICAL STEP: Save/Create Document
        await gameProvider.saveGame(); // ⬅️ Suspect for unhandled exception

        // 3. Update UI state only after successful save
        if (mounted) {
          setState(() {
            _displayedGameId = gameId;
            _isInitializing = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Game ID: $gameId. Share this with players!'),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } catch (e) {
        // 4. Catch and log any exceptions from connectToGame or saveGame
        print('FATAL ERROR during Game Initialization: $e');
        if (mounted) {
          setState(() {
            _isInitializing = false; // MUST set to false to un-stick the UI
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to create game: Check Console.')),
          );
        }
      }
    }
  }

  void _startNewGame(BuildContext context, GameProvider gameProvider) async {
    // 1. Get a unique ID from Firestore without creating the document yet
    final newGameRef = FirebaseFirestore.instance.collection('games').doc();
    final gameId = newGameRef.id;

    // 2. Connect provider to the new ID, starting the stream listener
    await gameProvider.connectToGame(gameId);

    // 3. Initialize the game state (this calls initializeTestGame, which now calls saveGame())
    gameProvider.initializeTestGame();

    // 4. Store and display the ID
    setState(() {
      _displayedGameId = gameId;
    });

    // 5. Display the ID for players to join
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Game ID: $gameId. Share this with players!'),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _copyGameId() {
    if (_displayedGameId != null) {
      Clipboard.setData(ClipboardData(text: _displayedGameId!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Game ID copied to clipboard!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final gameProvider = Provider.of<GameProvider>(context);
    final isGameEnded = false; // This would be controlled by game state

    // Show loading while initializing
    if (_isInitializing) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Host Game'),
          centerTitle: true,
          backgroundColor: Colors.blue[800],
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text(
                'Creating game...',
                style: TextStyle(fontSize: 18),
              ),
            ],
          ),
        ),
      );
    }

    if (!gameProvider.gameStarted) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Host Game'),
          centerTitle: true,
          backgroundColor: Colors.blue[800],
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Game ID Display (if available)
              if (_displayedGameId != null) ...[
                Container(
                  padding: const EdgeInsets.all(24),
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue[300]!, width: 3),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Game ID',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[900],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Text(
                          _displayedGameId!,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                            letterSpacing: 2,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _copyGameId,
                        icon: const Icon(Icons.copy),
                        label: const Text('Copy Game ID'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Share this ID with players to join',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],

              // Player List
              if (gameProvider.players.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Players (${gameProvider.players.length})',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...gameProvider.players.map((player) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: player.color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.black,
                                    width: 1,
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
                const SizedBox(height: 32),
              ],

              // Start Game Button
              ElevatedButton(
                onPressed: gameProvider.players.length >= 2
                    ? () {
                        gameProvider.startGame();
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 20,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: const Text('START GAME'),
              ),
              const SizedBox(height: 16),
              Text(
                gameProvider.players.length < 2
                    ? 'Waiting for at least 2 players...'
                    : 'Ready to start!',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Ticket to Ride Map'),
          centerTitle: true,
          backgroundColor: Colors.blue[800],
          foregroundColor: Colors.white,
        ),
        body: Padding(
          padding: EdgeInsets.all(screenSize.width * 0.01),
          child: Column(
            children: [
              // Game ID Display at top (permanent)
              if (_displayedGameId != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[300]!, width: 2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Game ID:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[900],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _displayedGameId!,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                              letterSpacing: 1.5,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: _copyGameId,
                        icon: const Icon(Icons.copy, size: 16),
                        label: const Text('Copy'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Main game area
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Map Section
                    Expanded(
                      flex: 69,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: const InteractiveMapWidget(),
                        ),
                      ),
                    ),

                    SizedBox(width: screenSize.width * 0.01),

                    // Sidebar
                    Expanded(
                      flex: 28,
                      child: Column(
                        children: [
                          // Leaderboard Section
                          Expanded(
                            flex: 2,
                            child: Container(
                              padding: EdgeInsets.all(screenSize.width * 0.01),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Leaderboard (${gameProvider.players.length} players)',
                                    style: TextStyle(
                                      fontSize: screenSize.width * 0.02,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: screenSize.height * 0.01),
                                  if (gameProvider.players.isEmpty)
                                    Center(
                                      child: Text(
                                        'Click refresh to initialize test game',
                                        style: TextStyle(
                                          fontSize: screenSize.width * 0.012,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    )
                                  else
                                    Expanded(
                                      child: _buildLeaderboardTable(screenSize,
                                          isGameEnded, gameProvider),
                                    ),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(height: screenSize.height * 0.01),

                          // Destination Drawing Button
                          Container(
                            margin: EdgeInsets.symmetric(
                                horizontal: screenSize.width * 0.01),
                            child: ElevatedButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Destination selection will appear on player devices'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[600],
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  vertical: screenSize.height * 0.015,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                'Draw Destinations',
                                style: TextStyle(
                                  fontSize: screenSize.width * 0.015,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: screenSize.height * 0.01),

                          // Deck Section
                          Expanded(
                            flex: 1,
                            child: Container(
                              padding: EdgeInsets.all(screenSize.width * 0.01),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Deck',
                                    style: TextStyle(
                                      fontSize: screenSize.width * 0.02,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: screenSize.height * 0.01),
                                  Expanded(
                                    child:
                                        _buildDeckRow(screenSize, gameProvider),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildLeaderboardTable(
      Size screenSize, bool isGameEnded, GameProvider gameProvider) {
    final players = gameProvider.players;

    return SingleChildScrollView(
      child: DataTable(
        columnSpacing: screenSize.width * 0.005,
        headingRowHeight: screenSize.height * 0.035,
        dataRowHeight: screenSize.height * 0.04,
        columns: [
          DataColumn(
            label: Expanded(
              child: Text(
                'Name',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: screenSize.width * 0.01,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          DataColumn(
            label: Expanded(
              child: Text(
                'Pts',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: screenSize.width * 0.01,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          DataColumn(
            label: Expanded(
              child: Text(
                'Longest',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: screenSize.width * 0.01,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          if (isGameEnded) ...[
            DataColumn(
              label: Expanded(
                child: Text(
                  'Dest',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: screenSize.width * 0.01,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            DataColumn(
              label: Expanded(
                child: Text(
                  'Total',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: screenSize.width * 0.01,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ],
        rows: players.map((player) {
          return DataRow(
            cells: [
              DataCell(
                Text(
                  player.name,
                  style: TextStyle(fontSize: screenSize.width * 0.008),
                ),
              ),
              DataCell(
                Text(
                  '0',
                  style: TextStyle(fontSize: screenSize.width * 0.008),
                ),
              ),
              DataCell(
                Text(
                  '✗',
                  style: TextStyle(fontSize: screenSize.width * 0.008),
                ),
              ),
              if (isGameEnded) ...[
                DataCell(
                  Text(
                    '0',
                    style: TextStyle(fontSize: screenSize.width * 0.008),
                  ),
                ),
                DataCell(
                  Text(
                    '0',
                    style: TextStyle(fontSize: screenSize.width * 0.008),
                  ),
                ),
              ],
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDeckRow(Size screenSize, GameProvider gameProvider) {
    final tableCards = gameProvider.tableCards;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(6, (index) {
        if (index < 5 && index < tableCards.length) {
          final card = tableCards[index];
          return Expanded(
            child: Container(
              margin:
                  EdgeInsets.symmetric(horizontal: screenSize.width * 0.002),
              child: ElevatedButton(
                onPressed: () {
                  if (gameProvider.players.isNotEmpty) {
                    gameProvider.takeCardFromTable(
                        gameProvider.currentPlayerIndex, index);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: card.color,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    vertical: screenSize.height * 0.02,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Colors.black, width: 2),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  card.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: screenSize.width * 0.01,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 2.0, // Controls the fuzziness of the shadow
                        color: Colors.black, // Shadow color
                        offset: Offset(1.0, 1.0), // Shadow offset (x, y)
                      ),
                      Shadow(
                        blurRadius: 2.0,
                        color: Colors.black,
                        offset: Offset(-1.0, -1.0), // For a bolder outline
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        } else if (index == 5) {
          // Deck button
          return Expanded(
            child: Container(
              margin:
                  EdgeInsets.symmetric(horizontal: screenSize.width * 0.002),
              child: ElevatedButton(
                onPressed: () {
                  if (gameProvider.players.isNotEmpty) {
                    gameProvider
                        .drawCardFromDeck(gameProvider.currentPlayerIndex);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[600],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    vertical: screenSize.height * 0.02,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Colors.black, width: 2),
                  ),
                  elevation: 2,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'DECK',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: screenSize.width * 0.01,
                      ),
                    ),
                    Text(
                      '${gameProvider.stackSize}',
                      style: TextStyle(
                        fontSize: screenSize.width * 0.008,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        } else {
          // Empty slot
          return Expanded(
            child: Container(
              margin:
                  EdgeInsets.symmetric(horizontal: screenSize.width * 0.002),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey, width: 1),
                ),
                child: Center(
                  child: Text(
                    'Empty',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: screenSize.width * 0.01,
                    ),
                  ),
                ),
              ),
            ),
          );
        }
      }),
    );
  }
}
