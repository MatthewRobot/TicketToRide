import 'package:flutter/material.dart';
import 'package:ticket_to_ride/models/train_route.dart';
import '../models/game_manager.dart';
import '../models/player.dart';
import '../models/card.dart' as game_card;
import '../models/destination.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async'; // Add this for StreamSubscription

class GameProvider extends ChangeNotifier {
  GameManager _gameManager = GameManager();
  bool _isInitialized = false;

  // Getters
  GameManager get gameManager => _gameManager;
  bool get isInitialized => _isInitialized;
  List<Player> get players => _gameManager.players;
  List<game_card.Card> get tableCards => _gameManager.visibleTableCards;
  int get stackSize => _gameManager.stackSize;
  int get usedPileSize => _gameManager.usedPileSize;
  int get destinationDeckSize => _gameManager.destinationDeckSize;
  bool get gameStarted => _gameManager.gameStarted;

  // Initialize game with test players
  void initializeTestGame() {
    if (!_isInitialized) {
      // Add test players
      _gameManager.addPlayer('Player 1', Colors.red);
      _gameManager.addPlayer('Player 2', Colors.blue);
      _gameManager.addPlayer('Player 3', Colors.green);
      _gameManager.addPlayer('Player 4', Colors.yellow);
      
      // Start the game
      _gameManager.startGame();
      _isInitialized = true;
      notifyListeners();
    }
  }

  // Add a player
  void addPlayer(String name, Color color) {
    _gameManager.addPlayer(name, color);
    notifyListeners();
  }

  // Start the game
  void startGame() {
    _gameManager.startGame();
    notifyListeners();
  }

  // Player actions
  void playerDrawFromDeck(Player player) {
    _gameManager.playerDrawFromDeck(player);
    notifyListeners();
  }

  void playerTakeFromTable(Player player, int tableIndex) {
    _gameManager.playerTakeFromTable(player, tableIndex);
    notifyListeners();
  }

  // void playerUseCard(Player player, game_card.Card card) {
  //   _gameManager.playerUseCard(player, card);
  //   notifyListeners();
  // }

  bool placeRoute({
  required int playerIndex,
  required TrainRoute route,
  required List<game_card.Card> cards,
}) {
  // Call the method on the underlying GameManager
  final success = _gameManager.placeRoute(playerIndex, route, cards);
  
  if (success) {
    // Notify all listening widgets (like PlayerScreen) to rebuild
    // because the player's hand, trains, and route map have changed.
    notifyListeners();
  }
  
  return success;
}

  // Player destination actions
  void playerDrawDestination(Player player) {
    _gameManager.playerDrawDestination(player);
    notifyListeners();
  }

  // Get new destinations for selection
  List<Destination> getNewDestinations() {
    return _gameManager.getNewDestinations();
  }

  // Add selected destinations to player
  void addSelectedDestinations(Player player, List<Destination> destinations) {
    _gameManager.addSelectedDestinations(player, destinations);
    notifyListeners();
  }

  // Get game statistics
  Map<String, dynamic> getGameStats() {
    return _gameManager.getGameStats();
  }

  // Reset game
  void resetGame() {
    _gameManager = GameManager();
    _isInitialized = false;
    notifyListeners();
  }

  // Firebase serialization
  Map<String, dynamic> toFirebase() {
    return {
      'gameManager': _gameManager.toFirebase(),
      'isInitialized': _isInitialized,
    };
  }

  void fromFirebase(Map<String, dynamic> data) {
    _gameManager = GameManager.fromFirebase(data['gameManager']);
    _isInitialized = data['isInitialized'] as bool;
    notifyListeners();
  }
}
