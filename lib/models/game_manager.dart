import 'package:flutter/material.dart';
import 'player.dart';
import 'deck.dart';
import 'card.dart' as game_card;

class GameManager {
  List<Player> players = [];
  Deck deck = Deck();
  bool gameStarted = false;

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
      gameStarted = true;
    }
  }

  // Get the current deck state for display
  List<game_card.Card> get visibleTableCards => deck.visibleTableCards;
  int get stackSize => deck.stackSize;
  int get usedPileSize => deck.usedPileSize;

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

  // Get game statistics
  Map<String, dynamic> getGameStats() {
    return {
      'players': players.length,
      'stackSize': stackSize,
      'usedPileSize': usedPileSize,
      'tableCards': visibleTableCards.length,
      'gameStarted': gameStarted,
    };
  }
}
