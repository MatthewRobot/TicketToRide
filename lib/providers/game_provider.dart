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
  int get currentPlayerIndex => _gameManager.currentPlayerIndex;
  bool get isGameOver => _gameManager.isGameOver;


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
  // --- Player Actions ---

// 1. Action: Player draws a card from the deck
// This replaces the old `player.drawCards` logic if you only draw one at a time.
// Note: A full turn is **two** draw actions, or one draw and one action (place/dest).
// This is one part of the turn.
  Future<void> drawCardFromDeck(int playerIndex) async {
    if (playerIndex != _gameManager.currentPlayerIndex ||
        _gameManager.isGameOver) return;

    // NOTE: This assumes the action is valid (player hasn't taken max actions yet)
    _gameManager.players[playerIndex].drawCards(_gameManager.deck,
        rainbowFromTable: false); // Draws 2 cards if used like this

    await saveGame();
  }

// 2. Action: Player takes a card from the table
  Future<void> takeCardFromTable(int playerIndex, int tableIndex) async {
    if (playerIndex != _gameManager.currentPlayerIndex ||
        _gameManager.isGameOver) return;

    final cardType = _gameManager.deck.table[tableIndex].type;

    // Note: Your player.takeCardFromTable handles the draw/replacement logic in the Deck.
    _gameManager.players[playerIndex]
        .takeCardFromTable(_gameManager.deck, tableIndex);

    // Determine if this draw ends the player's draw phase
    // TTR rule: taking a Rainbow card from the table counts as both actions.
    final isRainbowFromTable = (cardType == game_card.CardType.rainbow);

    // Save state
    await saveGame();

    // If it was a Rainbow card, the turn ends immediately
    if (isRainbowFromTable) {
      await endTurn(playerIndex);//Too many positional arguments: 0 expected, but 1 found.
    }
  }

  // void playerUseCard(Player player, game_card.Card card) {
  //   _gameManager.playerUseCard(player, card);
  //   notifyListeners();
  // }

  Future<bool> placeRoute({
    required int playerIndex,
    required TrainRoute route,
    required List<game_card.Card> cards,
  }) async {
    if (playerIndex != _gameManager.currentPlayerIndex ||
        _gameManager.isGameOver) {
      return false;
    }

    // 1. Call the core game logic method in GameManager
    final success = _gameManager.placeRoute(
        playerIndex: playerIndex, route: route, cards: cards);

    if (success) {
      // 2. Turn ends on success
      await endTurn(playerIndex);//Too many positional arguments: 0 expected, but 1 found.

    } else {
      // 3. Save state even if it failed, in case of small internal state change
      await saveGame();
    }

    return success;
  }

  

  Future<void> completeDestinationSelection(
      Player player,
      List<Destination> selectedDestinations,
      List<Destination> unselectedDestinations) async {
    // 1. Add selected and return unselected
    _gameManager.addSelectedDestinations(player, selectedDestinations);
    _gameManager.destinationDeck.addToUsedPile(unselectedDestinations);

    // 2. End the player's turn
    await endTurn(currentPlayerIndex);
  }

  Future<void> endTurn(int playerIndex) async {
    if (playerIndex != _gameManager.currentPlayerIndex ||
        _gameManager.isGameOver) return;

    // 1. Advance the game state
    _gameManager.nextTurn();

    // 2. Save the new state
    await saveGame();
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

  Future<void> addSelectedDestinationsSetup(
      Player player,
      List<Destination> selectedDestinations,
      List<Destination> unselectedDestinations) async {
    // Add selected cards to the player's permanent hand
    _gameManager.addSelectedDestinations(player, selectedDestinations);

    // Return unselected cards to the destination deck's used pile
    _gameManager.destinationDeck.addToUsedPile(unselectedDestinations);

    await saveGame();
  }

  // Add selected destinations to player
  void addSelectedDestinations(Player player, List<Destination> destinations) {
    _gameManager.addSelectedDestinations(player, destinations);
    // REMOVE: notifyListeners();
    saveGame(); // <- NEW: Save the updated player destination cards
  }

  // You would need to make sure you call _gameManager.setAllRoutes(routes)
  // after loading the routes from MapGeometryService, likely when the game is
  // hosted/joined or when GameProvider is created.

  // <<< NEW METHOD TO SET ROUTES (Required for Scoring to work) >>>
  // You'll need to call this after loading map data in your setup logic.
  void loadMapDataAndSetRoutes(List<TrainRoute> allRoutes) {
    _gameManager.setAllRoutes(allRoutes);
  }

  // <<< NEW METHOD TO GET FINAL SCORES >>>
  List<Map<String, dynamic>> getFinalScores() {
    // Returns a list of maps containing all final score breakdowns.
    return _gameManager.getFinalScores();
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
