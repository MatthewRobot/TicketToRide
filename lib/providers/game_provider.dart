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
  String? _myPlayerId;
  List<TrainRoute> _staticAllRoutes = [];

  // Firebase references
  DocumentReference? _gameRef;

  GameProvider({required String userId}) : _userId = userId;

  void updateUserId(String userId) {
    _userId = userId;
    notifyListeners();
  }

  // NEW: Get my player index
  int? get myPlayerIndex {
    // print('this is _myplayerID $_myPlayerId');
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
  String get userId => _userId;
  int get cardsDrawnThisTurn => _gameManager.cardsDrawnThisTurn;
  bool get drewRainbowFromTable => _gameManager.drewRainbowFromTable;
  int? get pendingDestinationDrawPlayerIndex =>
      _gameManager.pendingDestinationDrawPlayerIndex;
  int? get routePlacePlayerIndex => _gameManager.routePlacePlayerIndex;
  Map<String, int?> get routeOwners => _gameManager.routeOwners;

  // NEW: Getters for draw rules
  static const int _initialDrawCount = 3;
  static const int _midGameDrawCount = 3;

  // NEW: Minimum keep for initial setup (Keep 2-3 of 3)
  static const int minKeepInitial = 2;
  // NEW: Minimum keep for mid-game draw (Keep 1-3 of 3)
  static const int minKeepMidGame = 1;

  // Connect to a game session
  Future<void> connectToGame(String gameId) async {
    _gameId = gameId;
    _gameRef = FirebaseFirestore.instance.collection('games').doc(gameId);

    if (_gameManager.allRoutes.isEmpty) {
      await _loadRoutes();
    }

    // Listen to game state changes
    _gameRef!.snapshots().listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        // 1. Create the new dynamic state object
        final newGameManager = GameManager.fromFirebase(data);

        // 2. 🔑 INJECT the static routes into the new instance
        newGameManager.setAllRoutes(_staticAllRoutes);

        // 3. Replace the old instance with the new, COMPLETE instance
        _gameManager = newGameManager;
        notifyListeners();
      }
    });
  }

  // // Create a new game
  // Future<String> createGame() async {
  //   final newGameRef = FirebaseFirestore.instance.collection('games').doc();
  //   _gameId = newGameRef.id;
  //   _gameRef = newGameRef;

  //   // Initialize empty game
  //   _gameManager = GameManager();
  //   await _loadRoutes();
  //   await saveGame();

  //   // Start listening
  //   await connectToGame(_gameId!);

  //   return _gameId!;
  // }

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
    await _loadRoutes();
    _gameManager.startGame();
    await saveGame();
    notifyListeners();
  }

  TrainRoute? get routeToPlace {
    print('arrived at route to place');
    if (_gameManager.routeToPlaceId == null) return null;
    print('got into route to place if');
    try {
      return _gameManager.allRoutes.firstWhere(
        (r) => r.id == _gameManager.routeToPlaceId,
      );
    } catch (e) {
      print('exception caught');
      return null; // Route not found
    }
  }

  Future<bool> setRouteForPlacing(TrainRoute route) async {
    // Only allow the current player to initiate the claim

    // Check if route is already owned
    if (_gameManager.routeOwners[route.id] != null) {
      print('route is owned, saus gaem provider');
      return false;
    }

    // Set the state
    print(
        'made it to setting routePlacePlayer index to $currentPlayerIndex current & routeplace id');
    print('in setRoutForPlacing route.id is in $route');
    _gameManager.routePlacePlayerIndex = _gameManager.currentPlayerIndex;
    _gameManager.routeToPlaceId = route.id;

    // Save state to Firebase to trigger PlayerScreen navigation
    await saveGame();
    notifyListeners();
    return true;
  }
  // Draw destinations for a specific player
  // List<Destination> getNewDestinations() {
  //   print('=== GameProvider.getNewDestinations called ===');
  //   print('Stack size before: ${_gameManager.destinationDeck.stackSize}');

  //   final destinations = _gameManager.getNewDestinations();

  //   print('Drew ${destinations.length} destinations');
  //   print('Destinations: ${destinations.map((d) => d.shortName).join(", ")}');
  //   print('Stack size after: ${_gameManager.destinationDeck.stackSize}');

  //   // Save immediately so other players can't get the same cards
  //   // The destinations are marked as "pending" in the deck
  //   print('Calling saveGame...');
  //   saveGame();
  //   print('saveGame completed');

  //   return destinations;
  // }

  // // Add selected destinations during setup (doesn't end turn)
  // Future<void> addSelectedDestinationsSetup(
  //   Player player,
  //   List<Destination> selected,
  //   List<Destination> unselected,
  // ) async {
  //   _gameManager.addSelectedDestinations(player, selected);
  //   _gameManager.destinationDeck.completeSelection(unselected);
  //   await saveGame();
  //   notifyListeners();
  // }

  // // Add selected destinations during game (ends turn)
  // Future<void> completeDestinationSelection(
  //   Player player,
  //   List<Destination> selected,
  //   List<Destination> unselected,
  // ) async {
  //   _gameManager.addSelectedDestinations(player, selected);
  //   _gameManager.destinationDeck.completeSelection(unselected);
  //   _gameManager.nextTurn();
  //   await saveGame();
  //   notifyListeners();
  // }

  // game_provider.dart

// **--- TRANSACTIONAL METHODS FOR DESTINATION CARDS ---**

  /// Transactional method for initial draw (Player must keep 2 or 3)
  Future<List<Destination>> getInitialDestinations() async {
    return await _performDestinationDrawTransaction(_initialDrawCount,
        isInitial: true);
  }

  /// Transactional method for mid-game draw (Player must keep 1 or more)
  Future<List<Destination>> drawDestinations() async {
    return await _performDestinationDrawTransaction(_midGameDrawCount,
        isInitial: false);
  }

  // NEW: Initiate a mid-game destination draw for the current player
  Future<void> initiateMidGameDestinationDraw() async {
    if (!_gameManager.gameStarted) {
      throw Exception('Game has not started yet.');
    }
    // 1. Set the current player as the one expected to draw destinations
    _gameManager.pendingDestinationDrawPlayerIndex =
        _gameManager.currentPlayerIndex;

    // 2. The player will call drawDestinations() on their screen

    await saveGame();
    notifyListeners();
  }

  /// The core transactional logic to prevent destination card race conditions.
  Future<List<Destination>> _performDestinationDrawTransaction(int drawCount,
      {required bool isInitial}) async {
    if (_gameRef == null || myPlayerIndex == null) {
      throw Exception("Game not connected or player not found.");
    }

    List<Destination> dealtCards = [];

    try {
      await _gameRef!.firestore.runTransaction((transaction) async {
        // 1. Read the current game state within the transaction
        DocumentSnapshot snapshot = await transaction.get(_gameRef!);
        if (!snapshot.exists) {
          throw Exception("Game does not exist.");
        }

        final data = snapshot.data() as Map<String, dynamic>;
        final currentManager = GameManager.fromFirebase(data);
        final currentPlayer = currentManager.players[myPlayerIndex!];

        // 2. Safety Check: If the player already has destinations pending, abort.
        if (currentPlayer.hasPendingDestinations) {
          throw Exception("Player already has pending destinations.");
        }

        // 3. (Mid-Game Check): Ensure it's the current player's turn if not initial setup
        if (!isInitial && currentManager.currentPlayerIndex != myPlayerIndex) {
          throw Exception("It is not your turn to draw destinations.");
        }

        // 4. Draw the cards atomically (modifies the deck on currentManager)
        dealtCards = currentManager.destinationDeck.dealDestinations(drawCount);

        if (dealtCards.isEmpty) {
          throw Exception("Destination deck is empty.");
        }

        // 5. Assign the dealt cards to the current player's pending list
        currentPlayer.pendingDestinations.addAll(dealtCards);

        // 6. Write the updated game state back (includes the updated player and deck)
        transaction.set(_gameRef!, currentManager.toFirebase());
      });

      // Update local state after successful transaction
      _gameManager.players[myPlayerIndex!].pendingDestinations
          .addAll(dealtCards);

      notifyListeners();
      return dealtCards;
    } catch (e) {
      print(
          'Transaction failed for destination draw (Initial: $isInitial): $e');
      rethrow;
    }
  }

  // **--- NEW: Complete Selection Method ---**

  /// Completes the destination selection and updates the game state.
  /// This method also needs to be transactional, but for simplicity, we use the
  /// existing saveGame if it doesn't overlap with a deck draw.
  // game_provider.dart

  Future<void> completeDestinationSelection(
      Player player, List<Destination> selected, List<Destination> unselected,
      // The default value of 'endTurn' doesn't matter much as the caller (ChooseDestination)
      // will always explicitly pass true/false based on isInitialSelection.
      {bool endTurn = false}) async {
    if (_gameRef == null || myPlayerIndex == null) return;

    try {
      await _gameRef!.firestore.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(_gameRef!);
        if (!snapshot.exists) throw Exception("Game does not exist.");

        final data = snapshot.data() as Map<String, dynamic>;
        final currentManager = GameManager.fromFirebase(data);

        final playerIndex =
            currentManager.players.indexWhere((p) => p.userId == player.userId);
        if (playerIndex == -1) throw Exception("Player not found.");
        final currentPlayer = currentManager.players[playerIndex];

        // 1. Transfer cards from pending to hand
        currentPlayer.handOfDestinationCards.addAll(selected);
        currentPlayer.pendingDestinations.clear(); // Clear pending list

        // 2. Return unselected cards to the deck's used pile
        currentManager.destinationDeck.completeSelection(selected, unselected);

        // 3. NEW: Clear pending draw state (Crucial for mid-game flow control)
        if (currentManager.pendingDestinationDrawPlayerIndex == playerIndex) {
          currentManager.pendingDestinationDrawPlayerIndex = null;
        }

        // 4. NEW: End turn inside the transaction if required (CRITICAL FIX)
        if (endTurn) {
          currentManager.nextTurn();
        }

        // 5. Write the updated game state back
        transaction.set(_gameRef!, currentManager.toFirebase());
      });

      // Update local state AFTER successful transaction
      player.handOfDestinationCards.addAll(selected);
      player.pendingDestinations.clear();

      // Now, only notify listeners, the turn has already advanced in Firebase
      notifyListeners();

      // NOTE: We no longer need an explicit nextTurn() call here.
      // The previous saveGame() and notifyListeners() call is also handled by notifyListeners().
    } catch (e) {
      print('Transaction failed for completeDestinationSelection: $e');
      rethrow;
    }
  }

  // Draw ONE card from deck
  void drawCardFromDeck(int playerIndex) async {
    // Enforce the rule checks
    if (!canDrawDeckCard) {
      print('Draw from deck failed: Draw limit reached or rainbow taken.');
      return;
    }

    if (playerIndex >= _gameManager.players.length) return;

    final player = _gameManager.players[playerIndex];
    final card = _gameManager.deck.drawCard();

    if (card != null) {
      player.handOfCards.add(card);

      _gameManager.cardsDrawnThisTurn++;

      await saveGame();
      notifyListeners();
    }
  }

// Take card from table
  void takeCardFromTable(int playerIndex, int tableIndex) async {
    // Enforce the rule checks
    if (!canTakeTableCard(tableIndex)) {
      print('Take from table failed: Invalid draw action.');
      return;
    }

    if (playerIndex >= _gameManager.players.length) return;

    final cardToTake = _gameManager.visibleTableCards[tableIndex];

    _gameManager.playerTakeFromTable(
      _gameManager.players[playerIndex],
      tableIndex,
    );

    _gameManager.cardsDrawnThisTurn++;
    if (cardToTake.type == game_card.CardType.rainbow) {
      // If the player took a Rainbow, it MUST be their first draw
      if (_gameManager.cardsDrawnThisTurn == 1) {
        _gameManager.drewRainbowFromTable = true;
      } else {
        // This case should be caught by canTakeTableCard, but for safety:
        print('ERROR: Took rainbow as second card.');
      }
    }

    await saveGame();
    notifyListeners();
  }

  Future<bool> placeRoute({
    required int playerIndex,
    required TrainRoute route,
    required List<game_card.Card> cards,
  }) async {
    // 1. Perform the claim logic in GameManager (updates player trains/score, sets owner)
    final success = _gameManager.placeRoute(
      playerIndex: playerIndex,
      route: route,
      cards: cards,
    );

    if (success) {
      // 2. Reset the temporary state and advance turn
      _gameManager
          .resetPlaceRouteState(); // Resets routePlacePlayerIndex and routeToPlaceId
      _gameManager.nextTurn(); // Advances currentPlayerIndex

      // 3. Save to Firebase
      await saveGame();
      notifyListeners();
    }
    return success;
  }

  void cancelRoutPlaceHelper() async{
    _gameManager.resetPlaceRouteState();

    await saveGame();
    notifyListeners();
  }

  void nextTurn() {
    // Reset draw state before advancing turn
    _gameManager.cardsDrawnThisTurn = 0;
    _gameManager.drewRainbowFromTable = false;

    _gameManager.nextTurn();
    saveGame();
    notifyListeners();
  }

  // In game_provider.dart

  bool get canDrawDeckCard {
    if (cardsDrawnThisTurn >= 2) {
      // This is the source of your "Draw limit reached" error.
      print('DBG: Draw deck fail: Cards drawn ($cardsDrawnThisTurn) >= 2.');
      return false;
    }
    if (drewRainbowFromTable) {
      print('DBG: Draw deck fail: Already drew table rainbow.');
      return false;
    }
    print('DBG: Draw deck SUCCESS.');
    return true;
  }

  bool canTakeTableCard(int tableIndex) {
    if (cardsDrawnThisTurn >= 2) {
      print('DBG: Draw drawn ($cardsDrawnThisTurn) >= 2.');
      return false;
    }

    if (drewRainbowFromTable) {
      print('DBG: Draw table fail: Already drew table rainbow.');
      return false;
    }

    final card = _gameManager.visibleTableCards[tableIndex];

    // Cannot take a Rainbow card as the second draw
    if (card.type == game_card.CardType.rainbow && cardsDrawnThisTurn == 1) {
      print('DBG: Draw table fail: Already drew table rainbow.');
      return false;
    }
    print('DBG: Draw table SUCCESS.');

    return true;
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

      _staticAllRoutes = routes;

      _gameManager.setAllRoutes(routes);

      for (var route in routes) {
        if (!routeOwners.containsKey(route.id)) {
          routeOwners[route.id] = null;
        }
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
