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
  Map<String, int?> routeOwners = {};
  List<TrainRoute> allRoutes = [];
  Map<String, TrainRoute> _routeMap = {};
  int currentPlayerIndex = 0;
  bool isGameOver = false;
  int finalTurnCounter = -1;
  int? pendingDestinationDrawPlayerIndex = null;
  int cardsDrawnThisTurn = 0; // Tracks train card draws
  bool drewRainbowFromTable = false; // Tracks rainbow draw limit
  int? routePlacePlayerIndex = null;
  String? routeToPlaceId = null;

  // Train Route Points Map (length: points)
  static const Map<int, int> _trainRoutePoints = {
    1: 1,
    2: 2,
    3: 4,
    4: 7,
    5: 10,
    6: 15,
  };

  GameManager();

  factory GameManager.newGame({required String hostUserId}) {
    return GameManager();
  }

  void setAllRoutes(List<TrainRoute> routes) {
    allRoutes = routes;
    _routeMap = {for (var route in routes) route.id: route};
  }

  // Add a player to the game - UPDATED to include userId
  void addPlayer(String name, Color color, String userId) {
    if (players.any((p) => p.userId == userId)) {
      return; // Already added
    }
    if (!gameStarted) {
      players.add(Player(
        name: name,
        color: color,
        userId: userId,
      ));
    }
  }

  // Start the game
  void startGame() {
    if (players.isNotEmpty && !gameStarted) {
      deck.initializeGame(players);
      gameStarted = true;
    }
  }

  void resetPlaceRouteState() {
    routePlacePlayerIndex = null;
    routeToPlaceId = null;
  }

  void nextTurn() {
    // 1. Check for end-game trigger on the *current* player
    if (players[currentPlayerIndex].numberOfTrains <= 2 &&
        finalTurnCounter == -1) {
      finalTurnCounter = 0;
      print('End-game triggered! Final turn counter started.');
    }

    // 2. Advance player index
    currentPlayerIndex = (currentPlayerIndex + 1) % players.length;

    cardsDrawnThisTurn = 0;
    drewRainbowFromTable = false;

    // 3. Increment final turn counter if in final round
    if (finalTurnCounter != -1) {
      finalTurnCounter++;
      print('Final turn counter: $finalTurnCounter / ${players.length}');

      // 4. Check for game over condition
      if (finalTurnCounter >= players.length) {
        isGameOver = true;
        print('Game Over!');
      }
    }
  }

  // Get the current deck state for display
  List<game_card.Card> get visibleTableCards => deck.visibleTableCards;
  int get stackSize => deck.stackSize;
  int get usedPileSize => deck.usedPileSize;
  int get destinationDeckSize => destinationDeck.stackSize;

  bool placeRoute({
    required int playerIndex,
    required TrainRoute route,
    required List<game_card.Card> cards,
  }) {
    final player = players[playerIndex];

    if (routeOwners.containsKey(route.id) && routeOwners[route.id] != null)
      return false;
    if (player.numberOfTrains < route.length) return false;

    routeOwners[route.id] = playerIndex;
    player.numberOfTrains -= route.length;
    player.score += (GameManager._trainRoutePoints[route.length] ?? 0);

    for (final card in cards) {
      deck.addToUsedPile(card);
      player.handOfCards.removeWhere((c) => c.type == card.type);
    }

    return true;
  }

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

        if (card.type == game_card.CardType.rainbow) {
          // Player can only draw 1 more card this turn
        }
      }
    }
  }

  void playerDrawDestination(Player player) {
    if (gameStarted) {
      final destination = destinationDeck.drawDestination();
      if (destination != null) {
        player.handOfDestinationCards.add(destination);
      }
    }
  }

  // List<Destination> getNewDestinations() {
  //   return destinationDeck.dealInitialDestinations(3);
  // }

  void addSelectedDestinations(Player player, List<Destination> destinations) {
    player.handOfDestinationCards.addAll(destinations);
  }

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

    final playerRouteIds = routeOwners.entries
        .where((entry) => entry.value == playerIndex)
        .map((entry) => entry.key)
        .toList();

    for (final routeId in playerRouteIds) {
      final route = _routeMap[routeId];
      if (route != null) {
        points += _trainRoutePoints[route.length] ?? 0;
      }
    }

    return points;
  }

  bool _isConnected(
      String startCityId, String endCityId, List<TrainRoute> playerRoutes) {
    if (startCityId == endCityId) return true;

    final Map<String, List<String>> adj = {};
    for (final route in playerRoutes) {
      adj.putIfAbsent(route.fromId, () => []).add(route.toId);
      adj.putIfAbsent(route.toId, () => []).add(route.fromId);
    }

    if (!adj.containsKey(startCityId) || !adj.containsKey(endCityId)) {
      return false;
    }

    final Set<String> visited = {};
    final List<String> queue = [startCityId];

    while (queue.isNotEmpty) {
      final currentCity = queue.removeAt(0);

      if (currentCity == endCityId) {
        return true;
      }

      if (visited.add(currentCity)) {
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

    final playerRoutes = _routeMap.entries
        .where((entry) =>
            entry.value.id != null && routeOwners[entry.key] == playerIndex)
        .map((entry) => entry.value)
        .toList();

    for (final destination in player.handOfDestinationCards) {
      final isConnected =
          _isConnected(destination.from, destination.to, playerRoutes);

      if (isConnected) {
        points += destination.points;
      } else {
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

    for (final startCity in cities) {
      int dfs(String currentCity, int currentLength, Set<String> usedRoutes) {
        int longestPathFromHere = currentLength;

        final neighbors = adj[currentCity] ?? [];

        for (final node in neighbors) {
          if (!usedRoutes.contains(node.routeId)) {
            final newUsedRoutes = Set<String>.from(usedRoutes)
              ..add(node.routeId);
            final newLength = currentLength + node.routeLength;

            longestPathFromHere = math.max(longestPathFromHere,
                dfs(node.cityId, newLength, newUsedRoutes));
          }
        }

        return longestPathFromHere;
      }

      maxRoadLength = math.max(maxRoadLength, dfs(startCity, 0, {}));
    }

    return maxRoadLength;
  }

  List<Map<String, dynamic>> getFinalScores() {
    if (players.isEmpty) {
      return [];
    }

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
        'userId': player.userId,
        'color': player.color.value,
        'trainRoutePoints': trainPoints,
        'destinationPoints': destinationPoints,
        'baseTotal': trainPoints + destinationPoints,
        'longestRoadLength': longestRoadLength,
        'longestRoadBonus': 0,
        'finalTotal': 0,
      });
      longestRoadLengths.add(longestRoadLength);
    }

    int maxLongestRoad = 0;
    if (longestRoadLengths.isNotEmpty) {
      maxLongestRoad = longestRoadLengths.reduce(math.max);
    }

    if (maxLongestRoad > 0) {
      for (final result in scoreResults) {
        if (result['longestRoadLength'] == maxLongestRoad) {
          result['longestRoadBonus'] = 10;
        }
      }
    }

    for (final result in scoreResults) {
      result['finalTotal'] = result['baseTotal'] + result['longestRoadBonus'];
    }

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
      'pendingDestinationDrawPlayerIndex': pendingDestinationDrawPlayerIndex,
      'cardsDrawnThisTurn': cardsDrawnThisTurn,
      'drewRainbowFromTable': drewRainbowFromTable,
      'routePlacePlayerIndex': routePlacePlayerIndex, // ADD THIS
      'routeToPlaceId': routeToPlaceId, // ADD THIS
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
    gameManager.pendingDestinationDrawPlayerIndex =
        data['pendingDestinationDrawPlayerIndex'] as int?;
    gameManager.cardsDrawnThisTurn = data['cardsDrawnThisTurn'] ?? 0;
    gameManager.drewRainbowFromTable = data['drewRainbowFromTable'] ?? false;
    gameManager.routePlacePlayerIndex = data['routePlacePlayerIndex'] as int?;
    gameManager.routeToPlaceId = data['routeToPlaceId'] as String?;
    return gameManager;
  }
}