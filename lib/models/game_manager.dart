import 'package:flutter/material.dart';
import 'player.dart';
import 'deck.dart';
import 'card.dart' as game_card;
import 'destination_deck.dart';
import 'destination.dart';
import 'train_route.dart';
import 'dart:math' as math;

// Helper class for the Longest Road pathfinding graph
class _AdjacencyNode {
  final String cityId;
  final int routeLength;
  final String routeId;

  _AdjacencyNode(this.cityId, this.routeLength, this.routeId);
}

class GameManager {
  List<Player> players = [];
  Deck deck = Deck();
  DestinationDeck destinationDeck = DestinationDeck();
  bool gameStarted = false;
  Map<String, int?> routeOwners =
      {}; // Map<RouteId, PlayerIndex?>. null means unclaimed.
  List<TrainRoute> allRoutes = [];
  Map<String, TrainRoute> _routeMap = {};
  int currentPlayerIndex = 0; // Tracks whose turn it is
  bool isGameOver = false; // Flag for game state
  int finalTurnCounter = -1; // -1 = not started, 0 = final turn is over

  // Train Route Points Map (length: points)
  static const Map<int, int> _trainRoutePoints = {
    1: 1,
    2: 2,
    3: 4,
    4: 7,
    5: 10,
    6: 15,
  };

  // ORIGINAL CONSTRUCTOR (Used for deserialization)
  GameManager(); 

  // NEW: Factory method to create a new game instance, ready for the host.
  // We use this in the GameProvider's createGame method.
  factory GameManager.newGame({required String hostUserId}) {
    // Note: We don't add the host player here, as they choose name/color later.
    // We just return a clean slate. You could optionally store the hostUserId
    // in the GameManager class if needed for permissions/UI, but for now, 
    // a clean instance is sufficient.
    return GameManager();
  }
  
  // You would need a way to load all possible routes and initialize routeOwners.
  // For now, assume this map is correctly populated with all route IDs.
  // Example initialization for a new game:
  // void initializeRoutes(List<Route> allRoutes) {
  //   for (var route in allRoutes) {
  //     routeOwners[route.id] = null;
  //   }
  // }
  void setAllRoutes(List<TrainRoute> routes) {
    allRoutes = routes;
    _routeMap = {for (var route in routes) route.id: route};
  }

  // Add a player to the game
  void addPlayer(String name, Color color) {
    if (!gameStarted) {
      players.add(Player(name: name, color: color));
    }
  }

  // Start the game
  void startGame() {
    if (players.isNotEmpty && !gameStarted) {
      deck.initializeGame(players);

      // Note: Initial destination cards are now chosen by players during setup
      // No automatic dealing of destination cards

      gameStarted = true;
    }
  }

  void nextTurn() {
    // 1. Check for end-game trigger on the *current* player
    if (players[currentPlayerIndex].numberOfTrains <= 2 &&
        finalTurnCounter == -1) {
      // Trigger the final round. The current player (who triggered it)
      // will get one more turn as part of the final round.
      finalTurnCounter = 0;
      print('End-game triggered! Final turn counter started.');
    }

    // 2. Advance player index
    currentPlayerIndex = (currentPlayerIndex + 1) % players.length;

    // 3. Increment final turn counter if in final round
    if (finalTurnCounter != -1) {
      finalTurnCounter++;
      print('Final turn counter: $finalTurnCounter / ${players.length}');

      // 4. Check for game over condition
      if (finalTurnCounter >= players.length) {
        isGameOver = true;
        // Optionally call scoring here: calculateFinalScores();
        print('Game Over!');
      }
    }
  }

  // Get the current deck state for display
  List<game_card.Card> get visibleTableCards => deck.visibleTableCards;
  int get stackSize => deck.stackSize;
  int get usedPileSize => deck.usedPileSize;
  int get destinationDeckSize => destinationDeck.stackSize;

  // New: Place a route and update game state
  bool placeRoute({
    required int playerIndex,
    required TrainRoute route,
    required List<game_card.Card> cards,
  }) {
    final player = players[playerIndex];

    // Check if route is already claimed or other conditions
    if (routeOwners.containsKey(route.id) && routeOwners[route.id] != null)
      return false;
    if (player.numberOfTrains < route.length) return false;

    // Execute claim
    routeOwners[route.id] = playerIndex;
    player.numberOfTrains -= route.length;
    player.score += (GameManager._trainRoutePoints[route.length] ??
        0); // Assuming you have a score field on Player

    // 4. Return cards to the used pile and remove them from the player's hand
    for (final card in cards) {
      deck.addToUsedPile(card);
      // NOTE: This assumes the UI/place_Route.dart already handles the card
      // removal from the hand. If not, you may need a more robust removal loop here.
      player.handOfCards.removeWhere((c) => c.type == card.type);
    }

    return true;
  }

  // Player actions
  void playerDrawFromDeck(Player player) {
    if (gameStarted) {
      player.drawCards(deck);
    }
  }

  void playerTakeFromTable(Player player, int tableIndex) {
    if (gameStarted) {
      final card = deck.takeCardFromTable(tableIndex);
      if (card != null) {
        player.handOfCards.add(card);

        // If it's a rainbow card from table, player can only draw 1 more card
        if (card.type == game_card.CardType.rainbow) {
          // Player can only draw 1 more card this turn
          // This would be handled in the game logic
        }
      }
    }
  }

  // Not needed cause place route uses cards
  // void playerUseCard(Player player, game_card.Card card) {
  //   if (gameStarted) {
  //     player.useCard(card, deck);
  //   }
  // }

  // Player destination actions
  void playerDrawDestination(Player player) {
    if (gameStarted) {
      final destination = destinationDeck.drawDestination();
      if (destination != null) {
        player.handOfDestinationCards.add(destination);
      }
    }
  }

  // Get 3 new destinations for selection
  List<Destination> getNewDestinations() {
    return destinationDeck.dealInitialDestinations(3);
  }

  // Add selected destinations to player
  void addSelectedDestinations(Player player, List<Destination> destinations) {
    player.handOfDestinationCards.addAll(destinations);
  }

  // Get game statistics
  Map<String, dynamic> getGameStats() {
    return {
      'players': players.length,
      'stackSize': stackSize,
      'usedPileSize': usedPileSize,
      'destinationDeckSize': destinationDeckSize,
      'tableCards': visibleTableCards.length,
      'gameStarted': gameStarted,
    };
  }

  int _calculateTrainRoutePoints(int playerIndex) {
    int points = 0;

    // Find all route IDs owned by the player
    final playerRouteIds = routeOwners.entries
        .where((entry) => entry.value == playerIndex)
        .map((entry) => entry.key)
        .toList();

    // Find the actual TrainRoute objects and sum their points
    for (final routeId in playerRouteIds) {
      final route = _routeMap[routeId];
      if (route != null) {
        // Look up points from the static map
        points += _trainRoutePoints[route.length] ?? 0;
      }
    }

    return points;
  }

  // Checks if a path exists between start and end city using only player's routes.
  bool _isConnected(
      String startCityId, String endCityId, List<TrainRoute> playerRoutes) {
    if (startCityId == endCityId) return true;

    // 1. Build an Adjacency List (CityID -> List<NeighborCityID>)
    final Map<String, List<String>> adj = {};
    for (final route in playerRoutes) {
      // Add both directions for the route
      adj.putIfAbsent(route.fromId, () => []).add(route.toId);
      adj.putIfAbsent(route.toId, () => []).add(route.fromId);
    }

    // Handle case where cities might not even be in the player's network
    if (!adj.containsKey(startCityId) || !adj.containsKey(endCityId)) {
      return false;
    }

    // 2. Perform BFS to find a path
    final Set<String> visited = {};
    final List<String> queue = [startCityId]; // Use a List as a queue (FIFO)

    while (queue.isNotEmpty) {
      final currentCity = queue.removeAt(0);

      if (currentCity == endCityId) {
        return true;
      }

      if (visited.add(currentCity)) {
        // Add unvisited neighbors to the queue
        final neighbors = adj[currentCity];
        if (neighbors != null) {
          queue.addAll(neighbors.where((cityId) => !visited.contains(cityId)));
        }
      }
    }

    return false;
  }

  int _calculateDestinationPoints(int playerIndex) {
    int points = 0;

    final player = players[playerIndex];

    // Get all routes owned by the player (as full TrainRoute objects)
    final playerRoutes = _routeMap.entries
        .where((entry) =>
            entry.value.id != null && routeOwners[entry.key] == playerIndex)
        .map((entry) => entry.value)
        .toList();

    for (final destination in player.handOfDestinationCards) {
      final isConnected =
          _isConnected(destination.from, destination.to, playerRoutes);

      if (isConnected) {
        // Add points for achieved destination
        points += destination.points;
      } else {
        // Subtract points for unachieved destination
        points -= destination.points;
      }
    }

    return points;
  }

  int _findLongestRoadLength(int playerIndex) {
    final playerRoutes = _routeMap.entries
        .where((entry) => routeOwners[entry.key] == playerIndex)
        .map((entry) => entry.value)
        .toList();

    if (playerRoutes.isEmpty) return 0;

    final Set<String> cities = {};
    for (final route in playerRoutes) {
      cities.add(route.fromId);
      cities.add(route.toId);
    }

    // Build Adjacency List: CityID -> List<_AdjacencyNode (Neighbor, Length, RouteID)>
    final Map<String, List<_AdjacencyNode>> adj = {};
    for (final route in playerRoutes) {
      adj
          .putIfAbsent(route.fromId, () => [])
          .add(_AdjacencyNode(route.toId, route.length, route.id));
      adj
          .putIfAbsent(route.toId, () => [])
          .add(_AdjacencyNode(route.fromId, route.length, route.id));
    }

    int maxRoadLength = 0;

    // Perform DFS from every city to find the longest path
    for (final startCity in cities) {
      // DFS function: currentCity, currentPathLength, usedRouteIDs
      int dfs(String currentCity, int currentLength, Set<String> usedRoutes) {
        int longestPathFromHere = currentLength;

        final neighbors = adj[currentCity] ?? [];

        for (final node in neighbors) {
          // Key check: Only traverse a route if it hasn't been used in this path
          if (!usedRoutes.contains(node.routeId)) {
            final newUsedRoutes = Set<String>.from(usedRoutes)
              ..add(node.routeId);
            final newLength = currentLength + node.routeLength;

            // Recurse and update the longest path found starting from the initial city
            longestPathFromHere = math.max(longestPathFromHere,
                dfs(node.cityId, newLength, newUsedRoutes));
          }
        }

        return longestPathFromHere;
      }

      // Start DFS from the current city.
      maxRoadLength = math.max(maxRoadLength, dfs(startCity, 0, {}));
    }

    return maxRoadLength;
  }

  List<Map<String, dynamic>> getFinalScores() {
    if (players.isEmpty) {
      return [];
    }

    // 1. Calculate base points and longest road length for all players
    final List<Map<String, dynamic>> scoreResults = [];
    final List<int> longestRoadLengths = [];

    for (int i = 0; i < players.length; i++) {
      final player = players[i];

      final trainPoints = _calculateTrainRoutePoints(i);
      final destinationPoints = _calculateDestinationPoints(i);
      final longestRoadLength = _findLongestRoadLength(i);

      scoreResults.add({
        'playerIndex': i,
        'name': player.name,
        'color': player.color.value, // Pass the color value for UI rendering
        'trainRoutePoints': trainPoints,
        'destinationPoints': destinationPoints,
        'baseTotal': trainPoints + destinationPoints,
        'longestRoadLength': longestRoadLength,
        'longestRoadBonus': 0, // Placeholder
        'finalTotal': 0, // Placeholder
      });
      longestRoadLengths.add(longestRoadLength);
    }

    // 2. Determine the Longest Road Bonus
    int maxLongestRoad = 0;
    if (longestRoadLengths.isNotEmpty) {
      maxLongestRoad = longestRoadLengths.reduce(math.max);
    }

    // Apply the 10-point bonus to all players tied for the longest road (max length > 0)
    if (maxLongestRoad > 0) {
      for (final result in scoreResults) {
        if (result['longestRoadLength'] == maxLongestRoad) {
          result['longestRoadBonus'] = 10;
        }
      }
    }

    // 3. Calculate Final Total
    for (final result in scoreResults) {
      result['finalTotal'] = result['baseTotal'] + result['longestRoadBonus'];
    }

    // You can also sort the list by 'finalTotal' descending here for a leaderboard display
    scoreResults.sort((a, b) => b['finalTotal'].compareTo(a['finalTotal']));

    return scoreResults;
  }

  // Firebase serialization
  Map<String, dynamic> toFirebase() {
    return {
      'players': players.map((p) => p.toFirebase()).toList(),
      'deck': deck.toFirebase(),
      'destinationDeck': destinationDeck.toFirebase(),
      'gameStarted': gameStarted,
      'routeOwners': routeOwners,
      'currentPlayerIndex': currentPlayerIndex,
      'isGameOver': isGameOver,
      'finalTurnCounter': finalTurnCounter,
    };
  }

  factory GameManager.fromFirebase(Map<String, dynamic> data) {
    final gameManager = GameManager();
    gameManager.players =
        (data['players'] as List).map((p) => Player.fromFirebase(p)).toList();
    gameManager.deck = Deck.fromFirebase(data['deck']);
    gameManager.destinationDeck =
        DestinationDeck.fromFirebase(data['destinationDeck']);
    gameManager.gameStarted = data['gameStarted'] as bool;
    gameManager.routeOwners = (data['routeOwners'] as Map<String, dynamic>?)
            ?.map(
              (key, value) => MapEntry(key, value as int?),
            )
            .cast<String, int?>() ??
        {};
    gameManager.currentPlayerIndex = data['currentPlayerIndex'] ?? 0;
    gameManager.isGameOver = data['isGameOver'] ?? false;
    gameManager.finalTurnCounter = data['finalTurnCounter'] ?? -1;
    return gameManager;
  }
}
