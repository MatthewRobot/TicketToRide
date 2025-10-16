import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ticket_to_ride/screens/choose_destination.dart';
import 'package:ticket_to_ride/screens/place_Route.dart';
import '../providers/game_provider.dart';
import '../models/card.dart' as game_card;

class PlayerScreen extends StatefulWidget {
  final int? playerIndex; // Make optional for auto-detection

  const PlayerScreen({
    super.key,
    this.playerIndex,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final gameProvider = Provider.of<GameProvider>(context);

    // Use myPlayerIndex if playerIndex not provided
    final int? effectivePlayerIndex =
        widget.playerIndex ?? gameProvider.myPlayerIndex;

    if (effectivePlayerIndex == null ||
        effectivePlayerIndex >= gameProvider.players.length) {
      return Scaffold(
        appBar: AppBar(title: const Text('Player Not Found')),
        body: const Center(child: Text('Player not found or not joined')),
      );
    }

    final player = gameProvider.players[effectivePlayerIndex];
    final isMyTurn = effectivePlayerIndex == gameProvider.currentPlayerIndex;
    final isGameOver = gameProvider.isGameOver;

    // player_screen.dart (inside _PlayerScreenState's build method)

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (gameProvider.gameStarted &&
          gameProvider.pendingDestinationDrawPlayerIndex ==
              effectivePlayerIndex) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ChooseDestination(
              isInitialSelection: false, // Mid-game flag
              playerIndex: effectivePlayerIndex,
            ),
          ),
        );
      }
      final routeToPlace = gameProvider.routeToPlace;
      print('made it to add pst frame call back');
      var tempppp = gameProvider.routePlacePlayerIndex;
      print('routePlacePlayerIndex $tempppp');
      print('effectivePlayerIndex $effectivePlayerIndex');
      print('routeToPlace $routeToPlace');

      if (gameProvider.gameStarted &&
          gameProvider.routePlacePlayerIndex == effectivePlayerIndex &&
          routeToPlace != null) {
        // Navigate to PlaceRoute screen
        // Use a replacement/dialog/push that prevents going back until an action is taken
        print('made it to navitation');
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PlaceRoute(
              playerIndex: effectivePlayerIndex,
              route: routeToPlace,
            ),
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(player.name),
        centerTitle: true,
        backgroundColor: player.color,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: Padding(
        padding: EdgeInsets.all(screenSize.width * 0.03),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              color: isMyTurn ? Colors.green.shade700 : Colors.red.shade700,
              child: Text(
                isGameOver
                    ? 'GAME OVER! Awaiting Final Scores.'
                    : isMyTurn
                        ? 'YOUR TURN!'
                        : 'Waiting for ${gameProvider.players[gameProvider.currentPlayerIndex].name}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
            ),

            SizedBox(height: screenSize.height * 0.01),

            // Number of trains
            Container(
              padding: EdgeInsets.all(screenSize.width * 0.03),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.train,
                    color: player.color,
                    size: screenSize.width * 0.06,
                  ),
                  SizedBox(width: screenSize.width * 0.02),
                  Text(
                    'Trains: ${player.numberOfTrains}',
                    style: TextStyle(
                      fontSize: screenSize.width * 0.05,
                      fontWeight: FontWeight.bold,
                      color: player.color,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: screenSize.height * 0.02),

            // Destination cards section
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Destination Cards',
                    style: TextStyle(
                      fontSize: screenSize.width * 0.04,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: screenSize.height * 0.01),
                  Expanded(
                    child: _buildDestinationCards(screenSize, player),
                  ),
                ],
              ),
            ),

            SizedBox(height: screenSize.height * 0.01),

            // Train cards section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Train Cards',
                  style: TextStyle(
                    fontSize: screenSize.width * 0.04,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: screenSize.height * 0.01),
                _buildTrainCards(screenSize, player),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDestinationCards(Size screenSize, player) {
    final destinations = player.handOfDestinationCards;

    if (destinations.isEmpty) {
      return Center(
        child: Text(
          'No destination cards',
          style: TextStyle(
            fontSize: screenSize.width * 0.04,
            color: Colors.grey[600],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Wrap(
        spacing: screenSize.width * 0.02,
        runSpacing: screenSize.height * 0.01,
        children: [
          // <--- START LIST LITERAL
          ...destinations.map((destination) {
            return Container(
              width: screenSize.width * 0.4,
              child: Card(
                elevation: 2,
                child: Padding(
                  padding: EdgeInsets.all(screenSize.width * 0.02),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        destination.displayName,
                        style: TextStyle(
                          fontSize: screenSize.width * 0.035,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: screenSize.height * 0.005),
                      Text(
                        '${destination.points} points',
                        style: TextStyle(
                          fontSize: screenSize.width * 0.03,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          })
        ],
      ),
    );
  }

  Widget _buildTrainCards(Size screenSize, player) {
    final trainCards = player.handOfCards;

    // Count cards by color
    final cardCounts = <game_card.CardType, int>{};
    for (final cardType in game_card.CardType.values) {
      cardCounts[cardType] = 0;
    }

    for (final card in trainCards) {
      cardCounts[card.type] = (cardCounts[card.type] ?? 0) + 1;
    }

    // Calculate card size to fit screen
    final cardWidth = (screenSize.width -
            (screenSize.width * 0.06) -
            (4 * screenSize.width * 0.02)) /
        3;
    final cardHeight = screenSize.height / 10;

    return SizedBox(
      height:
          cardHeight * 3 + (2 * screenSize.height * 0.01), // 3 rows + spacing
      child: Column(
        children: [
          // First row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTrainCard(
                  screenSize,
                  game_card.CardType.red,
                  cardCounts[game_card.CardType.red] ?? 0,
                  cardWidth,
                  cardHeight),
              _buildTrainCard(
                  screenSize,
                  game_card.CardType.blue,
                  cardCounts[game_card.CardType.blue] ?? 0,
                  cardWidth,
                  cardHeight),
              _buildTrainCard(
                  screenSize,
                  game_card.CardType.green,
                  cardCounts[game_card.CardType.green] ?? 0,
                  cardWidth,
                  cardHeight),
            ],
          ),
          SizedBox(height: screenSize.height * 0.01),
          // Second row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTrainCard(
                  screenSize,
                  game_card.CardType.yellow,
                  cardCounts[game_card.CardType.yellow] ?? 0,
                  cardWidth,
                  cardHeight),
              _buildTrainCard(
                  screenSize,
                  game_card.CardType.pink,
                  cardCounts[game_card.CardType.pink] ?? 0,
                  cardWidth,
                  cardHeight),
              _buildTrainCard(
                  screenSize,
                  game_card.CardType.white,
                  cardCounts[game_card.CardType.white] ?? 0,
                  cardWidth,
                  cardHeight),
            ],
          ),
          SizedBox(height: screenSize.height * 0.01),
          // Third row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTrainCard(
                  screenSize,
                  game_card.CardType.orange,
                  cardCounts[game_card.CardType.orange] ?? 0,
                  cardWidth,
                  cardHeight),
              _buildTrainCard(
                  screenSize,
                  game_card.CardType.black,
                  cardCounts[game_card.CardType.black] ?? 0,
                  cardWidth,
                  cardHeight),
              _buildTrainCard(
                  screenSize,
                  game_card.CardType.rainbow,
                  cardCounts[game_card.CardType.rainbow] ?? 0,
                  cardWidth,
                  cardHeight),
            ],
          ),
        ],
      ),
    );
  }

  // Widget _buildTrainCard(Size screenSize, game_card.CardType cardType,
  //     int count, double cardWidth, double cardHeight) {
  //   final card = game_card.Card(type: cardType);

  //   return Container(
  //     width: cardWidth,
  //     height: cardHeight,
  //     decoration: BoxDecoration(
  //       color: card.color,
  //       borderRadius: BorderRadius.circular(8),
  //       border: Border.all(color: Colors.black, width: 2),
  //     ),
  //     child: Column(
  //       mainAxisAlignment: MainAxisAlignment.center,
  //       children: [
  //         Text(
  //           card.name,
  //           style: TextStyle(
  //             color: Colors.white,
  //             fontSize: screenSize.width * 0.03,
  //             fontWeight: FontWeight.bold,
  //           ),
  //           textAlign: TextAlign.center,
  //         ),
  //         SizedBox(height: screenSize.height * 0.005),
  //         Container(
  //           padding: EdgeInsets.symmetric(
  //             horizontal: screenSize.width * 0.02,
  //             vertical: screenSize.height * 0.005,
  //           ),
  //           decoration: BoxDecoration(
  //             color: Colors.white,
  //             borderRadius: BorderRadius.circular(12),
  //           ),
  //           child: Text(
  //             '$count',
  //             style: TextStyle(
  //               color: Colors.black,
  //               fontSize: screenSize.width * 0.04,
  //               fontWeight: FontWeight.bold,
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }
  Widget _buildTrainCard(Size screenSize, game_card.CardType cardType,
      int count, double cardWidth, double cardHeight) {
    final card = game_card.Card(type: cardType);

    return Container(
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        color: card.color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding:
                  EdgeInsets.symmetric(horizontal: screenSize.width * 0.01),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  card.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(offset: Offset(-1.5, -1.5), color: Colors.black),
                      Shadow(offset: Offset(1.5, -1.5), color: Colors.black),
                      Shadow(offset: Offset(1.5, 1.5), color: Colors.black),
                      Shadow(offset: Offset(-1.5, 1.5), color: Colors.black),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            SizedBox(height: screenSize.height * 0.005),
            // Removed the outer Container that had the white background
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '$count',
                style: const TextStyle(
                  color: Colors.black, // The main text color for the number
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    // White stroke for the number
                    Shadow(offset: Offset(-1.5, -1.5), color: Colors.white),
                    Shadow(offset: Offset(1.5, -1.5), color: Colors.white),
                    Shadow(offset: Offset(1.5, 1.5), color: Colors.white),
                    Shadow(offset: Offset(-1.5, 1.5), color: Colors.white),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
