import 'package:flutter/material.dart';

class HostScreen extends StatefulWidget {
  const HostScreen({super.key});

  @override
  State<HostScreen> createState() => _HostScreenState();
}

class _HostScreenState extends State<HostScreen> {
  final List<Color> _cardColors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.purple,
    Colors.orange,
  ];

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isGameEnded = false; // This would be controlled by game state
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ticket to Ride Map'),
        centerTitle: true,
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
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
                            'Leaderboard',
                            style: TextStyle(
                              fontSize: screenSize.width * 0.02,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: screenSize.height * 0.01),
                          Expanded(
                            child: _buildLeaderboardTable(screenSize, isGameEnded),
                          ),
                        ],
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
                            child: _buildDeckRow(screenSize),
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

  Widget _buildLeaderboardTable(Size screenSize, bool isGameEnded) {
    final players = [
      {'name': 'Player 1', 'routePoints': 15, 'longestRoad': '✓', 'destinationPoints': 8, 'totalPoints': 33},
      {'name': 'Player 2', 'routePoints': 12, 'longestRoad': '✗', 'destinationPoints': 5, 'totalPoints': 17},
      {'name': 'Player 3', 'routePoints': 8, 'longestRoad': '✗', 'destinationPoints': 3, 'totalPoints': 11},
      {'name': 'Player 4', 'routePoints': 5, 'longestRoad': '✗', 'destinationPoints': 2, 'totalPoints': 7},
    ];

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
                  player['name'] as String,
                  style: TextStyle(fontSize: screenSize.width * 0.012),
                ),
              ),
              DataCell(
                Text(
                  '${player['routePoints']}',
                  style: TextStyle(fontSize: screenSize.width * 0.012),
                ),
              ),
              DataCell(
                Text(
                  player['longestRoad'] as String,
                  style: TextStyle(fontSize: screenSize.width * 0.012),
                ),
              ),
              if (isGameEnded) ...[
                DataCell(
                  Text(
                    '${player['destinationPoints']}',
                    style: TextStyle(fontSize: screenSize.width * 0.012),
                  ),
                ),
                DataCell(
                  Text(
                    '${player['totalPoints']}',
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

  Widget _buildDeckRow(Size screenSize) {
    final cardTexts = [
      'Red',
      'Blue',
      'Green',
      'Yellow',
      'Purple',
      'Orange',
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(6, (index) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: screenSize.width * 0.002),
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  // Cycle through colors when pressed
                  _cardColors[index] = _getNextColor(_cardColors[index]);
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _cardColors[index],
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
                cardTexts[index],
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: screenSize.width * 0.01,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      }),
    );
  }

  Color _getNextColor(Color currentColor) {
    final allColors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
      Colors.pink,
      Colors.teal,
      Colors.indigo,
      Colors.amber,
      Colors.cyan,
      Colors.lime,
    ];
    
    // Find current color index by comparing RGB values
    int currentIndex = 0;
    for (int i = 0; i < allColors.length; i++) {
      if (allColors[i].value == currentColor.value) {
        currentIndex = i;
        break;
      }
    }
    
    return allColors[(currentIndex + 1) % allColors.length];
  }
}
