import 'package:flutter/material.dart';
import 'card.dart' as game_card;
import 'deck.dart';
import 'destination.dart';

class Player {
  final String name;
  final Color color;
  int numberOfTrains;
  List<game_card.Card> handOfCards;
  List<Destination> handOfDestinationCards;
  int score;

  Player({
    required this.name,
    required this.color,
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

  // Method to use a card (moves it to used pile)
  // void useCard(game_card.Card card, Deck deck) {
  //   handOfCards.remove(card);
  //   deck.addToUsedPile(card);
  // }

  @override
  String toString() {
    return 'Player(name: $name, color: $color, trains: $numberOfTrains, cards: ${handOfCards.length})';
  }

  // Firebase serialization
  Map<String, dynamic> toFirebase() {
    return {
      'name': name,
      'color': color.value,
      'numberOfTrains': numberOfTrains,
      'handOfCards': handOfCards.map((c) => c.toFirebase()).toList(),
      'handOfDestinationCards':
          handOfDestinationCards.map((c) => c.toFirebase()).toList(),
    };
  }

  factory Player.fromFirebase(Map<String, dynamic> data) {
    return Player(
      name: data['name'] as String,
      color: Color(data['color'] as int),
      numberOfTrains: data['numberOfTrains'] as int,
      handOfCards: (data['handOfCards'] as List)
          .map((c) => game_card.Card.fromFirebase(c))
          .toList(),
      handOfDestinationCards: (data['handOfDestinationCards'] as List)
          .map((d) => Destination.fromFirebase(d))
          .toList(),
    );
  }
}
