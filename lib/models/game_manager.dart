import 'package:flutter/material.dart';
import 'player.dart';
import 'deck.dart';
import 'card.dart' as game_card;
import 'destination_deck.dart';
import 'destination.dart';
import 'train_route.dart';

class GameManager {
  List<Player> players = [];
  Deck deck = Deck();
  DestinationDeck destinationDeck = DestinationDeck();
  bool gameStarted = false;
  Map<String, int?> routeOwners = {}; // Map<RouteId, PlayerIndex?>. null means unclaimed.

  GameManager();

  // You would need a way to load all possible routes and initialize routeOwners.
  // For now, assume this map is correctly populated with all route IDs.
  // Example initialization for a new game:
  // void initializeRoutes(List<Route> allRoutes) {
  //   for (var route in allRoutes) {
  //     routeOwners[route.id] = null;
  //   }
  // }

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

  // Get the current deck state for display
  List<game_card.Card> get visibleTableCards => deck.visibleTableCards;
  int get stackSize => deck.stackSize;
  int get usedPileSize => deck.usedPileSize;
  int get destinationDeckSize => destinationDeck.stackSize;

  
  // New: Place a route and update game state
  bool placeRoute(int playerIndex, TrainRoute route, List<game_card.Card> cards) {
    if (!gameStarted || playerIndex < 0 || playerIndex >= players.length) {
      return false;
    }
    
    final player = players[playerIndex];
    
    // 1. Basic validation (route length, ownership, train count)
    if (route.length != cards.length) {
      // This shouldn't happen if _canPlaceRoute was correct, but is a safety check.
      return false; 
    }
    
    // Check if route is already owned
    if (routeOwners[route.id] != null) {
      return false; 
    }
    
    // Check if player has enough trains
    if (player.numberOfTrains < route.length) {
      return false;
    }
    
    // 2. Commit changes
    
    // Move cards from player's hand to the used pile in the Deck.
    // NOTE: Cards were already removed from player hand in _placeRoute for simplicity
    // in the widget. In a more robust system, you'd move them here.
    for (final card in cards) {
      deck.addToUsedPile(card);
    }
    
    // Reduce player's train count
    player.numberOfTrains -= route.length;
    
    // Update route ownership
    routeOwners[route.id] = playerIndex;
    
    // TODO: Add points to player score (if Player class had a score property)
    
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

  // Firebase serialization
  Map<String, dynamic> toFirebase() {
    return {
      'players': players.map((p) => p.toFirebase()).toList(),
      'deck': deck.toFirebase(),
      'destinationDeck': destinationDeck.toFirebase(),
      'gameStarted': gameStarted,
    };
  }

  factory GameManager.fromFirebase(Map<String, dynamic> data) {
    final gameManager = GameManager();
    gameManager.players = (data['players'] as List)
        .map((p) => Player.fromFirebase(p))
        .toList();
    gameManager.deck = Deck.fromFirebase(data['deck']);
    gameManager.destinationDeck = DestinationDeck.fromFirebase(data['destinationDeck']);
    gameManager.gameStarted = data['gameStarted'] as bool;
    return gameManager;
  }
}
