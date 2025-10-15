import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/game_manager.dart';
import '../models/player.dart';
import '../models/card.dart' as game_card;
import '../models/destination.dart';
import '../models/train_route.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class GameProvider with ChangeNotifier {
  GameManager _gameManager = GameManager();
  String _userId = '';
  String? _gameId;
  String? _myPlayerId; // NEW: Track which player this user is

  // Firebase references
  DocumentReference? _gameRef;

  GameProvider({required String userId}) : _userId = userId;

  void updateUserId(String userId) {
    _userId = userId;
    notifyListeners();
  }

  // NEW: Get my player index
  int? get myPlayerIndex {
    if (_myPlayerId == null) return null;
    return _gameManager.players.indexWhere((p) => p.userId == _myPlayerId);
  }

  // Getters
  List<Player> get players => _gameManager.players;
  bool get gameStarted => _gameManager.gameStarted;
  List<game_card.Card> get tableCards => _gameManager.visibleTableCards;
  int get stackSize => _gameManager.stackSize;
  int get currentPlayerIndex => _gameManager.currentPlayerIndex;
  bool get isGameOver => _gameManager.isGameOver;
  String? get gameId => _gameId;

  // Connect to a game session
  Future<void> connectToGame(String gameId) async {
    _gameId = gameId;
    _gameRef = FirebaseFirestore.instance.collection('games').doc(gameId);

    // Listen to game state changes
    _gameRef!.snapshots().listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        _gameManager = GameManager.fromFirebase(data);
        notifyListeners();
      }
    });
  }

  // Create a new game
  Future<String> createGame() async {
    final newGameRef = FirebaseFirestore.instance.collection('games').doc();
    _gameId = newGameRef.id;
    _gameRef = newGameRef;

    // Initialize empty game
    _gameManager = GameManager();
    await _loadRoutes();
    await saveGame();

    // Start listening
    await connectToGame(_gameId!);

    return _gameId!;
  }

  // Add player with unique ID
  // Future<bool> addPlayer(String name, Color color) async {
  //   if (_myPlayerId != null) {
  //     // This user already has a player
  //     return false;
  //   }

  //   // Check if color is taken (real-time check)
  //   if (_gameManager.players.any((p) => p.color == color)) {
  //     return false;
  //   }

  //   // Create player with userId as identifier
  //   _myPlayerId = _userId;

  //   // Use GameManager's addPlayer method
  //   _gameManager.addPlayer(name, color, _userId);

  //   await saveGame();
  //   notifyListeners();
  //   return true;
  // }

  //new transaction method so that players don't choose same color
  // Add player with unique ID using a transaction to prevent race conditions
  Future<bool> addPlayer(String name, Color color) async {
    if (_myPlayerId != null) {
      // This user already has a player
      return false;
    }

    if (_gameRef == null) {
      // Should not happen if connected to a game
      return false;
    }

    // Use a transaction to ensure atomic color selection
    try {
      await _gameRef!.firestore.runTransaction((transaction) async {
        // 1. Read the current game state within the transaction
        DocumentSnapshot snapshot = await transaction.get(_gameRef!);
        if (!snapshot.exists) {
          throw Exception("Game does not exist.");
        }

        final data = snapshot.data() as Map<String, dynamic>;
        final currentManager = GameManager.fromFirebase(data);

        // 2. Check if the color is taken (transactional read)
        if (currentManager.players.any((p) => p.color.value == color.value)) {
          // Throw an error to stop the transaction and return false
          throw Exception('Color already taken.');
        }

        // 3. Update the game state (transactional write)
        _myPlayerId = _userId;
        currentManager.addPlayer(name, color, _userId);

        // 4. Write the updated state back
        transaction.set(_gameRef!, currentManager.toFirebase());

        // Update the local state after successful transaction
        _gameManager = currentManager;
      });

      // The transaction was successful
      notifyListeners();
      return true;
    } catch (e) {
      // Catch exceptions from the transaction (including 'Color already taken.')
      print('Transaction failed: $e');
      _myPlayerId = null; // Ensure ID is not set if transaction failed
      return false;
    }
  }

  Future<void> startGame() async {
    if (_gameManager.players.length < 2) {
      throw Exception('Need at least 2 players to start');
    }

    _gameManager.startGame();
    await saveGame();
    notifyListeners();
  }

  // Draw destinations for a specific player
  List<Destination> getNewDestinations() {
    print('=== GameProvider.getNewDestinations called ===');
    print('Stack size before: ${_gameManager.destinationDeck.stackSize}');

    final destinations = _gameManager.getNewDestinations();

    print('Drew ${destinations.length} destinations');
    print('Destinations: ${destinations.map((d) => d.shortName).join(", ")}');
    print('Stack size after: ${_gameManager.destinationDeck.stackSize}');

    // Save immediately so other players can't get the same cards
    // The destinations are marked as "pending" in the deck
    print('Calling saveGame...');
    saveGame();
    print('saveGame completed');

    return destinations;
  }

  // Add selected destinations during setup (doesn't end turn)
  Future<void> addSelectedDestinationsSetup(
    Player player,
    List<Destination> selected,
    List<Destination> unselected,
  ) async {
    _gameManager.addSelectedDestinations(player, selected);
    _gameManager.destinationDeck.completeSelection(unselected);
    await saveGame();
    notifyListeners();
  }

  // Add selected destinations during game (ends turn)
  Future<void> completeDestinationSelection(
    Player player,
    List<Destination> selected,
    List<Destination> unselected,
  ) async {
    _gameManager.addSelectedDestinations(player, selected);
    _gameManager.destinationDeck.completeSelection(unselected);
    _gameManager.nextTurn();
    await saveGame();
    notifyListeners();
  }

  // Draw ONE card from deck
  void drawCardFromDeck(int playerIndex) {
    if (playerIndex >= _gameManager.players.length) return;

    final player = _gameManager.players[playerIndex];
    final card = _gameManager.deck.drawCard();

    if (card != null) {
      player.handOfCards.add(card);
      saveGame();
      notifyListeners();
    }
  }

  // Take card from table
  void takeCardFromTable(int playerIndex, int tableIndex) {
    if (playerIndex >= _gameManager.players.length) return;

    _gameManager.playerTakeFromTable(
      _gameManager.players[playerIndex],
      tableIndex,
    );
    saveGame();
    notifyListeners();
  }

  bool placeRoute({
    required int playerIndex,
    required TrainRoute route,
    required List<game_card.Card> cards,
  }) {
    final success = _gameManager.placeRoute(
      playerIndex: playerIndex,
      route: route,
      cards: cards,
    );

    if (success) {
      saveGame();
      notifyListeners();
    }

    return success;
  }

  void nextTurn() {
    _gameManager.nextTurn();
    saveGame();
    notifyListeners();
  }

  // Save game state to Firebase
  Future<void> saveGame() async {
    if (_gameRef == null) return;

    try {
      await _gameRef!.set(_gameManager.toFirebase());
    } catch (e) {
      print('Error saving game: $e');
    }
  }

  Future<void> _loadRoutes() async {
    try {
      final String jsonString =
          await rootBundle.loadString('assets/map_info.JSON');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      final List<dynamic> routesJson = jsonData['routes'] ?? [];

      final routes =
          routesJson.map((json) => TrainRoute.fromJson(json)).toList();
      _gameManager.setAllRoutes(routes);

      for (var route in routes) {
        _gameManager.routeOwners[route.id] = null;
      }
    } catch (e) {
      print('Error loading routes: $e');
    }
  }

  void resetGame() {
    _gameManager = GameManager();
    _myPlayerId = null;
    notifyListeners();
  }

  // Test game initialization
  void initializeTestGame() {
    _gameManager = GameManager();

    // Generate test user IDs
    _gameManager.addPlayer('Player 1', Colors.red, 'test_user_1');
    _gameManager.addPlayer('Player 2', Colors.blue, 'test_user_2');
    _gameManager.addPlayer('Player 3', Colors.green, 'test_user_3');
    _gameManager.addPlayer('Player 4', Colors.yellow, 'test_user_4');

    _loadRoutes();
    saveGame();
    notifyListeners();
  }
}
