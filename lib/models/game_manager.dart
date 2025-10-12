import 'package:flutter/material.dart';
import 'player.dart';
import 'deck.dart';
import 'card.dart' as game_card;
import 'destination_deck.dart';
import 'destination.dart';

class GameManager {
  List<Player> players = [];
  Deck deck = Deck();
  DestinationDeck destinationDeck = DestinationDeck();
  bool gameStarted = false;

  GameManager();

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

  void playerUseCard(Player player, game_card.Card card) {
    if (gameStarted) {
      player.useCard(card, deck);
    }
  }

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
