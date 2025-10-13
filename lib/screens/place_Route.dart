import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../models/card.dart' as game_card;
import 'package:ticket_to_ride/models/train_route.dart';

class PlaceRoute extends StatefulWidget {
  final int playerIndex;
  final TrainRoute route; // Use the Route object

  const PlaceRoute({
    super.key,
    required this.playerIndex,
    required this.route, // Route must be provided
  });

  @override
  State<PlaceRoute> createState() => _PlaceRouteState();
}

class _PlaceRouteState extends State<PlaceRoute> {
  Map<game_card.CardType, int> selectedCards = {};
  game_card.CardType? requiredColor;
  int requiredCount = 0;

  @override
  void initState() {
    super.initState();
    _parseRouteInfo();
  }

  void _parseRouteInfo() {
    requiredColor = widget.route.requiredCardType;
    requiredCount = widget.route.length;

    // Initialize selected cards
    for (final cardType in game_card.CardType.values) {
      selectedCards[cardType] = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final gameProvider = Provider.of<GameProvider>(context);

    if (widget.playerIndex >= gameProvider.players.length) {
      return Scaffold(
        body: Center(child: Text('Player not found')),
      );
    }

    final player = gameProvider.players[widget.playerIndex];
    final playerCards = player.handOfCards;

    // Count available cards
    final availableCards = <game_card.CardType, int>{};
    for (final cardType in game_card.CardType.values) {
      availableCards[cardType] = 0;
    }

    for (final card in playerCards) {
      availableCards[card.type] = (availableCards[card.type] ?? 0) + 1;
    }

    // Create a display string from the TrainRoute object
    final routeDisplayInfo =
        'Route: ${widget.route.fromId} → ${widget.route.toId} ' +
            '(${widget.route.length} segments, ${widget.route.color.toUpperCase()})';

    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(screenSize.width * 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: screenSize.height * 0.05),

            // Route information
            Container(
              padding: EdgeInsets.all(screenSize.width * 0.04),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[300]!),
              ),
              child: Text(
                routeDisplayInfo,
                style: TextStyle(
                  fontSize: screenSize.width * 0.05,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
                textAlign: TextAlign.center,
              ),
            ),

            SizedBox(height: screenSize.height * 0.03),

            // Instructions
            Text(
              'Select train cards to place route:',
              style: TextStyle(
                fontSize: screenSize.width * 0.04,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: screenSize.height * 0.02),

            // Train cards selection
            Expanded(
              child: _buildTrainCardSelection(screenSize, availableCards),
            ),

            SizedBox(height: screenSize.height * 0.02),

            // Selected cards summary
            _buildSelectedCardsSummary(screenSize),

            SizedBox(height: screenSize.height * 0.02),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _canPlaceRoute() ? _placeRoute : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: screenSize.height * 0.02,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Place Route',
                      style: TextStyle(
                        fontSize: screenSize.width * 0.04,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: screenSize.width * 0.02),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[600],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: screenSize.height * 0.02,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: screenSize.width * 0.04,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: screenSize.height * 0.02),
          ],
        ),
      ),
    );
  }

  Widget _buildTrainCardSelection(
      Size screenSize, Map<game_card.CardType, int> availableCards) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: screenSize.width * 0.02,
        mainAxisSpacing: screenSize.height * 0.01,
        childAspectRatio: 1.1,
      ),
      itemCount: game_card.CardType.values.length,
      itemBuilder: (context, index) {
        final cardType = game_card.CardType.values[index];
        final available = availableCards[cardType] ?? 0;
        final selected = selectedCards[cardType] ?? 0;
        final card = game_card.Card(type: cardType);

        // Check if this card type can be selected
        final canSelect = _canSelectCardType(cardType);

        return Container(
          decoration: BoxDecoration(
            color: canSelect ? card.color : Colors.grey[400],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected > 0 ? Colors.yellow : Colors.black,
              width: selected > 0 ? 3 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                card.name,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: screenSize.width * 0.03,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: screenSize.height * 0.005),
              Text(
                'Available: $available',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: screenSize.width * 0.025,
                ),
              ),
              if (canSelect) ...[
                SizedBox(height: screenSize.height * 0.005),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed:
                          selected > 0 ? () => _decreaseCard(cardType) : null,
                      icon: Icon(
                        Icons.remove_circle,
                        color: Colors.white,
                        size: screenSize.width * 0.05,
                      ),
                    ),
                    Text(
                      '$selected',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenSize.width * 0.04,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: selected < available
                          ? () => _increaseCard(cardType)
                          : null,
                      icon: Icon(
                        Icons.add_circle,
                        color: Colors.white,
                        size: screenSize.width * 0.05,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSelectedCardsSummary(Size screenSize) {
    final totalSelected =
        selectedCards.values.fold(0, (sum, count) => sum + count);

    return Container(
      padding: EdgeInsets.all(screenSize.width * 0.03),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Text(
            'Selected: $totalSelected / $requiredCount',
            style: TextStyle(
              fontSize: screenSize.width * 0.04,
              fontWeight: FontWeight.bold,
              color: totalSelected == requiredCount
                  ? Colors.green[700]
                  : Colors.red[700],
            ),
          ),
          if (totalSelected > 0) ...[
            SizedBox(height: screenSize.height * 0.01),
            Wrap(
              spacing: screenSize.width * 0.02,
              children: selectedCards.entries
                  .where((entry) => entry.value > 0)
                  .map((entry) {
                final card = game_card.Card(type: entry.key);
                return Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenSize.width * 0.02,
                    vertical: screenSize.height * 0.005,
                  ),
                  decoration: BoxDecoration(
                    color: card.color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${card.name}: ${entry.value}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: screenSize.width * 0.03,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  bool _canSelectCardType(game_card.CardType cardType) {
    // 1. Rainbow cards can always be selected
    if (cardType == game_card.CardType.rainbow) return true;

    // 2. The *other* color card that can be selected.
    if (cardType == requiredColor) return true;

    // 3. No other colors can be selected
    return false;
  }

  void _increaseCard(game_card.CardType cardType) {
    setState(() {
      selectedCards[cardType] = (selectedCards[cardType] ?? 0) + 1;
    });
  }

  void _decreaseCard(game_card.CardType cardType) {
    setState(() {
      if ((selectedCards[cardType] ?? 0) > 0) {
        selectedCards[cardType] = selectedCards[cardType]! - 1;
      }
    });
  }

  // Inside _PlaceRouteState:

  bool _canPlaceRoute() {
    final totalSelected =
        selectedCards.values.fold(0, (sum, count) => sum + count);

    if (totalSelected != requiredCount) {
      return false; // Must select the exact number of cards
    }

    // Check that all non-rainbow cards are of the required color
    int nonRainbowCards = 0;
    game_card.CardType? chosenColor;

    for (final entry in selectedCards.entries) {
      if (entry.value > 0 && entry.key != game_card.CardType.rainbow) {
        if (chosenColor == null) {
          chosenColor = entry.key;
        } else if (chosenColor != entry.key) {
          // Player selected two different non-rainbow colors
          return false;
        }
        nonRainbowCards += entry.value;
      }
    }

    // Check if the chosen color is valid for the route
    if (chosenColor != null &&
        requiredColor != null &&
        chosenColor != requiredColor) {
      // If the route has a color (not grey) but the chosen non-rainbow card doesn't match
      return false;
    }

    // For 'grey' routes (requiredColor is null), all non-rainbow cards must be of the *same* color.
    // The logic above ensures this by setting chosenColor.

    // The selection is valid if the total count is correct, and all non-rainbow cards
    // are of a single, valid color (or if only Rainbow cards were used).
    return true;
  }

  // Inside _PlaceRouteState:
  void _placeRoute() {
    if (_canPlaceRoute()) {
      final gameProvider = Provider.of<GameProvider>(context, listen: false);

      // 1. Get the list of cards to use
      List<game_card.Card> cardsToUse = [];
      for (final entry in selectedCards.entries) {
        final cardType = entry.key;
        final count = entry.value;

        // Get the *actual* cards from the player's hand
        final playerHand = gameProvider.players[widget.playerIndex].handOfCards;

        for (int i = 0; i < count; i++) {
          // Find and remove the card from the player's hand for collection
          final cardIndex =
              playerHand.indexWhere((card) => card.type == cardType);
          if (cardIndex != -1) {
            cardsToUse.add(playerHand.removeAt(cardIndex));
          } else {
            // This should not happen if _canPlaceRoute and availableCards were correct
            return;
          }
        }
      }

      // 2. Call the new method on GameManager
      final success = gameProvider.placeRoute(
        playerIndex: widget.playerIndex,
        route: widget.route,
        cards: cardsToUse,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Route placed successfully!'),
          ),
        );
        Navigator.of(context).pop();
      } else {
        // Handle error (e.g., trains limit reached, route already claimed)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to place route.'),
          ),
        );
        // If failed, you might need to revert the cards removed from the hand.
        // Better to handle the full removal within the successful GameManager call.
      }
    }
  }
}
