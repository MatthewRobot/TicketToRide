import 'package:flutter/material.dart';
import 'package:ticket_to_ride/models/train_route.dart';
import '../models/game_manager.dart';
import '../models/player.dart';
import '../models/card.dart' as game_card;
import '../models/destination.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class GameProvider extends ChangeNotifier {
  GameManager _gameManager = GameManager();
  bool _isInitialized = false;
  
  // NEW: Field for the authenticated user ID
  String _userId; 

  String? _gameId;
  StreamSubscription? _gameSubscription;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // NEW: Constructor now requires the user ID
  GameProvider({required String userId}) : _userId = userId;

  // NEW: Getter for the current authenticated user ID.
  String get userId => _userId;

  // NEW: Method to update the user ID (called by AuthWrapper)
  void updateUserId(String newId) {
    if (_userId != newId) {
      _userId = newId;
      notifyListeners(); 
    }
  }

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
  Color? _currentPlayerColor; 

  Color? get currentPlayerColor => _currentPlayerColor;

  void setCurrentPlayerColor(Color color) {
    _currentPlayerColor = color;
  }
  
  void removePlayer(Color? color) {
    if (color != null) {
      players.removeWhere((p) => p.color == color);
      _currentPlayerColor = null;
      notifyListeners();
    }
  }
  // Initialize game with test players
  void initializeTestGame() {
    if (!_isInitialized) {
      // NOTE: You may want to remove this test function once the app is fully authenticated
      _gameManager.addPlayer('Player 1', Colors.red);
      _gameManager.addPlayer('Player 2', Colors.blue);
      _gameManager.addPlayer('Player 3', Colors.green);
      _gameManager.addPlayer('Player 4', Colors.yellow);

      _gameManager.startGame();
      _isInitialized = true;
      saveGame();
    }
  }

  // Add a player
  void addPlayer(String name, Color color) {
    _gameManager.addPlayer(name, color);
    saveGame();
  }
  
  // NEW: Method to create a new game in Firestore
  Future<String> createGame() async {
    // Assuming GameManager has a way to identify the host/first player by UID
    // You will need to ensure GameManager.newGame accepts the hostUserId
    _gameManager = GameManager.newGame(hostUserId: _userId); 
    
    // Create the document, Firestore generates the ID
    final docRef = await _firestore.collection('games').add(_gameManager.toFirebase());
    _gameId = docRef.id;
    await connectToGame(_gameId!); // Start listening to the newly created game
    return _gameId!;
  }
  
  // Start the game
  void startGame() {
    _gameManager.startGame();
    saveGame(); // Save the game state after starting
  }

  // FIXED: Draw card from deck
  Future<void> drawCardFromDeck(int playerIndex) async {
    if (playerIndex != _gameManager.currentPlayerIndex ||
        _gameManager.isGameOver) return;

    _gameManager.players[playerIndex].drawCards(_gameManager.deck,
        rainbowFromTable: false);

    await saveGame();
  }

  // FIXED: Take card from table
  Future<void> takeCardFromTable(int playerIndex, int tableIndex) async {
    if (playerIndex != _gameManager.currentPlayerIndex ||
        _gameManager.isGameOver) return;

    final cardType = _gameManager.deck.table[tableIndex].type;

    _gameManager.players[playerIndex]
        .takeCardFromTable(_gameManager.deck, tableIndex);

    final isRainbowFromTable = (cardType == game_card.CardType.rainbow);

    await saveGame();

    if (isRainbowFromTable) {
      await endTurn(); // FIXED: Removed playerIndex argument
    }
  }

  // FIXED: Place route
  Future<bool> placeRoute({
    required int playerIndex,
    required TrainRoute route,
    required List<game_card.Card> cards,
  }) async {
    if (playerIndex != _gameManager.currentPlayerIndex ||
        _gameManager.isGameOver) {
      return false;
    }

    final success = _gameManager.placeRoute(
        playerIndex: playerIndex, route: route, cards: cards);

    if (success) {
      await endTurn(); // FIXED: Removed playerIndex argument
    } else {
      await saveGame();
    }

    return success;
  }

  // FIXED: Complete destination selection
  Future<void> completeDestinationSelection(
      Player player,
      List<Destination> selectedDestinations,
      List<Destination> unselectedDestinations) async {
    _gameManager.addSelectedDestinations(player, selectedDestinations);
    _gameManager.destinationDeck.addToUsedPile(unselectedDestinations);

    await endTurn(); // FIXED: Removed playerIndex argument
  }

  // FIXED: End turn - no parameters needed
  Future<void> endTurn() async {
    if (_gameManager.isGameOver) return;

    _gameManager.nextTurn();
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
    _gameManager.addSelectedDestinations(player, selectedDestinations);
    _gameManager.destinationDeck.addToUsedPile(unselectedDestinations);
    await saveGame();
  }

  // Add selected destinations to player
  void addSelectedDestinations(Player player, List<Destination> destinations) {
    _gameManager.addSelectedDestinations(player, destinations);
    saveGame();
  }

  void loadMapDataAndSetRoutes(List<TrainRoute> allRoutes) {
    _gameManager.setAllRoutes(allRoutes);
  }

  List<Map<String, dynamic>> getFinalScores() {
    return _gameManager.getFinalScores();
  }

  Map<String, dynamic> getGameStats() {
    return _gameManager.getGameStats();
  }

  // Connects to Firebase and listens for real-time updates
  Future<void> connectToGame(String gameId) async {
    _gameId = gameId;

    _gameSubscription?.cancel();

    _gameSubscription = _firestore
        .collection('games')
        .doc(gameId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        fromFirebase(snapshot.data() as Map<String, dynamic>);
        notifyListeners();
      } else {
        print('Game document $gameId not found or deleted.');
      }
    }, onError: (error) {
      print('Firestore stream error: $error');
    });
  }

  Future<void> saveGame() async {
    if (_gameId != null) {
        try {
            final gameData = toFirebase();
            print('DEBUG (Provider): Successfully serialized game data.'); // ⬅️ ADD THIS

            // The Firestore write operation that might be hanging:
            await _firestore.collection('games').doc(_gameId!).set(gameData);
            print('DEBUG (Provider): Firestore set operation completed successfully.'); // ⬅️ ADD THIS

        } catch (e) {
            // This catches serialization errors (from toFirebase) or write errors
            print('FATAL ERROR (Provider): Exception during saveGame: $e');
            // Re-throw the error so it can be caught in the HostScreen's try-catch block
            rethrow; 
        }
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
