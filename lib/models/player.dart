import 'package:flutter/material.dart';
import 'card.dart' as game_card;
import 'deck.dart';
import 'destination.dart';

class Player {
  final String name;
  final Color color;
  final String userId; // NEW: Add userId to identify player
  int numberOfTrains;
  List<game_card.Card> handOfCards;
  List<Destination> handOfDestinationCards;
  int score;

  Player({
    required this.name,
    required this.color,
    required this.userId, // NEW: Required parameter
    this.numberOfTrains = 45,
    List<game_card.Card>? handOfCards,
    List<Destination>? handOfDestinationCards,
    this.score = 0,
  })  : handOfCards = handOfCards ?? [],
        handOfDestinationCards = handOfDestinationCards ?? [];

  // Method to draw 2 cards (or 1 if rainbow card taken from table)
  void drawCards(Deck deck, {bool rainbowFromTable = false}) {
    int cardsToDraw = rainbowFromTable ? 1 : 2;

    for (int i = 0; i < cardsToDraw; i++) {
      game_card.Card? card = deck.drawCard();
      if (card != null) {
        handOfCards.add(card);
      }
    }
  }

  // Method to take a card from the table
  void takeCardFromTable(Deck deck, int tableIndex) {
    game_card.Card? card = deck.takeCardFromTable(tableIndex);
    if (card != null) {
      handOfCards.add(card);
    }
  }

  @override
  String toString() {
    return 'Player(name: $name, userId: $userId, color: $color, trains: $numberOfTrains, cards: ${handOfCards.length})';
  }

  // Firebase serialization
  Map<String, dynamic> toFirebase() {
    return {
      'name': name,
      'userId': userId, // NEW: Include userId
      'color': color.value,
      'numberOfTrains': numberOfTrains,
      'handOfCards': handOfCards.map((c) => c.toFirebase()).toList(),
      'handOfDestinationCards':
          handOfDestinationCards.map((c) => c.toFirebase()).toList(),
      'score': score,
    };
  }

  factory Player.fromFirebase(Map<String, dynamic> data) {
    return Player(
      name: data['name'] as String,
      userId: data['userId'] as String, // NEW: Read userId
      color: Color(data['color'] as int),
      numberOfTrains: data['numberOfTrains'] as int,
      handOfCards: (data['handOfCards'] as List)
          .map((c) => game_card.Card.fromFirebase(c))
          .toList(),
      handOfDestinationCards: (data['handOfDestinationCards'] as List)
          .map((d) => Destination.fromFirebase(d))
          .toList(),
      score: data['score'] ?? 0,
    );
  }
}