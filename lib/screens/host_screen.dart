import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';

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
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(screenSize.width * 0.01),
        child: Row(
          children: [
            // Map Section - Smaller
            Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.asset(
                    'assets/images/Map.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            
            SizedBox(width: screenSize.width * 0.01),
            
            // Sidebar with Leaderboard and Deck
            Expanded(
              flex: 1,
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
        columnSpacing: screenSize.width * 0.01,
        headingRowHeight: screenSize.height * 0.04,
        dataRowHeight: screenSize.height * 0.05,
        columns: [
          DataColumn(
            label: Text(
              'Player',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: screenSize.width * 0.015,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Route Pts',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: screenSize.width * 0.015,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Longest Road',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: screenSize.width * 0.015,
              ),
            ),
          ),
          if (isGameEnded) ...[
            DataColumn(
              label: Text(
                'Destination Pts',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: screenSize.width * 0.015,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Total Pts',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: screenSize.width * 0.015,
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
                  style: TextStyle(fontSize: screenSize.width * 0.012),
                ),
              ),
              DataCell(
                Text(
                  '0', // Route points - would be calculated from routes built
                  style: TextStyle(fontSize: screenSize.width * 0.012),
                ),
              ),
              DataCell(
                Text(
                  '✗', // Longest road - would be calculated
                  style: TextStyle(fontSize: screenSize.width * 0.012),
                ),
              ),
              if (isGameEnded) ...[
                DataCell(
                  Text(
                    '0', // Destination points - would be calculated
                    style: TextStyle(fontSize: screenSize.width * 0.012),
                  ),
                ),
                DataCell(
                  Text(
                    '0', // Total points - would be calculated
                    style: TextStyle(fontSize: screenSize.width * 0.012),
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

}
