import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final gameProvider = Provider.of<GameProvider>(context);
    final isGameEnded = false; // This would be controlled by game state
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ticket to Ride Map'),
        centerTitle: true,
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              gameProvider.initializeTestGame();
            },
            tooltip: 'Initialize Test Game',
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              _testPlayerScreen(context, gameProvider);
            },
            tooltip: 'Test Player Screen',
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(screenSize.width * 0.01),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch, // ⬅️ IMPORTANT: Forces children to fill the Row's height
          children: [
            // Map Section - Use Expanded for full height and proportional width
            Expanded(
              flex: 69, // Proportional to your desired 69% width
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  // child: SvgPicture.asset(
                  //   'assets/images/map.svg',
                  //   fit: BoxFit.contain, // The SVG will now scale up to the full height of the Expanded
                  //   placeholderBuilder: (context) => const CircularProgressIndicator(),
                  // ),
                  child: const InteractiveMapWidget(), // Replace static SVG with the interactive widget
                ),
              ),
            ),
            
            SizedBox(width: screenSize.width * 0.01), // Spacer
            
            // Sidebar - Use Expanded for full height and proportional width
            Expanded(
              flex: 28, // Proportional to your desired 28% width
              child: Column(
                // The Column inside the Expanded will now correctly use the full height.
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
                              child: _buildLeaderboardTable(screenSize, isGameEnded, gameProvider),
                            ),
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(height: screenSize.height * 0.01),
                  
                  // Destination Drawing Button
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: screenSize.width * 0.01),
                    child: ElevatedButton(
                      onPressed: () {
                        // This would trigger destination selection on player devices
                        // For now, show a message about how this would work
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Destination selection will appear on player devices'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                        
                        // In a real implementation, this would:
                        // 1. Send a signal to all player devices
                        // 2. Each player device would show the destination selection screen
                        // 3. Host screen would remain visible to all players
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
                            child: _buildDeckRow(screenSize, gameProvider),
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
    );
  }

  Widget _buildLeaderboardTable(Size screenSize, bool isGameEnded, GameProvider gameProvider) {
    final players = gameProvider.players;

    return SingleChildScrollView(
      child: DataTable(
        columnSpacing: screenSize.width * 0.005, // Reduced spacing
        headingRowHeight: screenSize.height * 0.035, // Reduced height
        dataRowHeight: screenSize.height * 0.04, // Reduced height
        columns: [
          DataColumn(
            label: Expanded(
              child: Text(
                'Name',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: screenSize.width * 0.01, // Reduced font size
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          DataColumn(
            label: Expanded(
              child: Text(
                'Pts', // Shorter header
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: screenSize.width * 0.01, // Reduced font size
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          DataColumn(
            label: Expanded(
              child: Text(
                'Longest', // Shorter header
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: screenSize.width * 0.01, // Reduced font size
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          if (isGameEnded) ...[
            DataColumn(
              label: Expanded(
                child: Text(
                  'Dest', // Shorter header
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: screenSize.width * 0.01, // Reduced font size
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            DataColumn(
              label: Expanded(
                child: Text(
                  'Total', // Shorter header
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: screenSize.width * 0.01, // Reduced font size
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
                  style: TextStyle(fontSize: screenSize.width * 0.008), // Reduced font size
                ),
              ),
              DataCell(
                Text(
                  '0', // Route points - would be calculated from routes built
                  style: TextStyle(fontSize: screenSize.width * 0.008), // Reduced font size
                ),
              ),
              DataCell(
                Text(
                  '✗', // Longest road - would be calculated
                  style: TextStyle(fontSize: screenSize.width * 0.008), // Reduced font size
                ),
              ),
              if (isGameEnded) ...[
                DataCell(
                  Text(
                    '0', // Destination points - would be calculated
                    style: TextStyle(fontSize: screenSize.width * 0.008), // Reduced font size
                  ),
                ),
                DataCell(
                  Text(
                    '0', // Total points - would be calculated
                    style: TextStyle(fontSize: screenSize.width * 0.008), // Reduced font size
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
        // Show table cards (first 5) and deck (6th button)
        if (index < 5 && index < tableCards.length) {
          final card = tableCards[index];
          return Expanded(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: screenSize.width * 0.002),
              child: ElevatedButton(
                onPressed: () {
                  // Take card from table
                  if (gameProvider.players.isNotEmpty) {
                    gameProvider.playerTakeFromTable(gameProvider.players[0], index);
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
              margin: EdgeInsets.symmetric(horizontal: screenSize.width * 0.002),
              child: ElevatedButton(
                onPressed: () {
                  // Draw from deck
                  if (gameProvider.players.isNotEmpty) {
                    gameProvider.playerDrawFromDeck(gameProvider.players[0]);
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
              margin: EdgeInsets.symmetric(horizontal: screenSize.width * 0.002),
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

  void _testPlayerScreen(BuildContext context, GameProvider gameProvider) {
    if (gameProvider.players.isEmpty) {
      // If no players exist, create a test player
      gameProvider.addPlayer('Test Player', Colors.red);
      gameProvider.addPlayer('Test Player 2', Colors.blue);
      
      // Add some test destination cards
      final testDestinations = [
        Destination(from: 'Boston', to: 'Miami', points: 12),
        Destination(from: 'Los Angeles', to: 'New York', points: 21),
        Destination(from: 'Seattle', to: 'Los Angeles', points: 9),
      ];
      
      // Add destinations to the first player
      if (gameProvider.players.isNotEmpty) {
        gameProvider.players[0].handOfDestinationCards.addAll(testDestinations);
      }
      
      // Add some test train cards
      final testCards = [
        game_card.Card(type: game_card.CardType.red, isVisible: true),
        game_card.Card(type: game_card.CardType.red, isVisible: true),
        game_card.Card(type: game_card.CardType.blue, isVisible: true),
        game_card.Card(type: game_card.CardType.green, isVisible: true),
        game_card.Card(type: game_card.CardType.yellow, isVisible: true),
        game_card.Card(type: game_card.CardType.yellow, isVisible: true),
        game_card.Card(type: game_card.CardType.yellow, isVisible: true),
        game_card.Card(type: game_card.CardType.pink, isVisible: true),
        game_card.Card(type: game_card.CardType.rainbow, isVisible: true),
      ];
      
      // Add train cards to the first player
      if (gameProvider.players.isNotEmpty) {
        gameProvider.players[0].handOfCards.addAll(testCards);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test player created with sample cards'),
          duration: Duration(seconds: 2),
        ),
      );
    }
    
    // Navigate to the first player's screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlayerScreen(
          playerIndex: 0,
        ),
      ),
    );
  }

}
