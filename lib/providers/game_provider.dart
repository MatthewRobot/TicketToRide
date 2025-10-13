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

  String? _gameId;
  StreamSubscription? _gameSubscription;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Getters
  String? get gameId => _gameId;
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
      saveGame();
    }
  }

  // Add a player
  void addPlayer(String name, Color color) {
    _gameManager.addPlayer(name, color);
    // REMOVE: notifyListeners();
    saveGame(); // <- NEW: Save the updated player list to Firebase
  }

  // Start the game
  void startGame() {
    _gameManager.startGame();
    notifyListeners();
  }

  // Player actions
  void playerDrawFromDeck(Player player) {
    _gameManager.playerDrawFromDeck(player);
    saveGame();
  }

  void playerTakeFromTable(Player player, int tableIndex) {
    _gameManager.playerTakeFromTable(player, tableIndex);
    saveGame();
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
      // REMOVE: notifyListeners();
      saveGame(); // <- NEW: Save the new route and player state
    }

    return success;
  }

  // Player destination actions
  void playerDrawDestination(Player player) {
    _gameManager.playerDrawDestination(player);
    saveGame();
  }

  // Get new destinations for selection
  List<Destination> getNewDestinations() {
    return _gameManager.getNewDestinations();
  }

  // Add selected destinations to player
  void addSelectedDestinations(Player player, List<Destination> destinations) {
    _gameManager.addSelectedDestinations(player, destinations);
    // REMOVE: notifyListeners();
    saveGame(); // <- NEW: Save the updated player destination cards
  }

  // Get game statistics
  Map<String, dynamic> getGameStats() {
    return _gameManager.getGameStats();
  }

  // NEW: Starts listening to a game document for real-time updates
  Future<void> connectToGame(String gameId) async {
    _gameId = gameId;

    _gameSubscription?.cancel(); // Cancel previous subscription

    _gameSubscription = _firestore
        .collection('games') // The main collection for games
        .doc(gameId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        // Deserialize the game state from Firebase
        fromFirebase(snapshot.data() as Map<String, dynamic>);
        notifyListeners(); // Update all UI widgets
      } else {
        print('Game document $gameId not found or deleted.');
      }
    }, onError: (error) {
      print('Firestore stream error: $error');
    });
  }

  Future<void> saveGame() async {
    if (_gameId != null) {
      final gameData = toFirebase();
      // Write the entire state to the Firestore document
      await _firestore.collection('games').doc(_gameId!).set(gameData);
    }
  }

  @override
  void dispose() {
    _gameSubscription?.cancel();
    super.dispose();
  }

  // Reset game
  void resetGame() {
    _gameManager = GameManager();
    _isInitialized = false;
    saveGame();
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
