import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../models/card.dart' as game_card;

class PlaceRoute extends StatefulWidget {
  final int playerIndex;
  final String routeInfo; // This will be replaced with actual route data later
  
  const PlaceRoute({
    super.key,
    required this.playerIndex,
    this.routeInfo = 'Route: Boston → New York (3 segments, Red)',
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
    // This is a placeholder - later this will parse actual route data
    // For now, simulate a red route requiring 3 cards
    requiredColor = game_card.CardType.red;
    requiredCount = 3;
    
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
                widget.routeInfo,
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

  Widget _buildTrainCardSelection(Size screenSize, Map<game_card.CardType, int> availableCards) {
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
                      onPressed: selected > 0 ? () => _decreaseCard(cardType) : null,
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
                      onPressed: selected < available ? () => _increaseCard(cardType) : null,
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
    final totalSelected = selectedCards.values.fold(0, (sum, count) => sum + count);
    
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
              color: totalSelected == requiredCount ? Colors.green[700] : Colors.red[700],
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
    // Rainbow cards can always be selected
    if (cardType == game_card.CardType.rainbow) return true;
    
    // The required color can be selected
    if (cardType == requiredColor) return true;
    
    // No other colors can be selected
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

  bool _canPlaceRoute() {
    final totalSelected = selectedCards.values.fold(0, (sum, count) => sum + count);
    return totalSelected == requiredCount;
  }

  void _placeRoute() {
    if (_canPlaceRoute()) {
      // TODO: Implement actual route placement logic
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Route placed successfully!'),
        ),
      );
      Navigator.of(context).pop();
    }
  }
}
