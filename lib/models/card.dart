import 'package:flutter/material.dart';

enum CardType {
  pink,
  white,
  yellow,
  orange,
  blue,
  black,
  red,
  green,
  rainbow,
}

class Card {
  final CardType type;
  final bool isVisible; // true if on table, false if from deck

  Card({required this.type, this.isVisible = true});

  Color get color {
    switch (type) {
      case CardType.pink:
        return Colors.pink;
      case CardType.white:
        return Colors.white;
      case CardType.yellow:
        return Colors.yellow;
      case CardType.orange:
        return Colors.orange;
      case CardType.blue:
        return Colors.blue;
      case CardType.black:
        return Colors.black;
      case CardType.red:
        return Colors.red;
      case CardType.green:
        return Colors.green;
      case CardType.rainbow:
        return Colors.purple; // Rainbow cards are purple
    }
  }

  String get name {
    switch (type) {
      case CardType.pink:
        return 'Pink';
      case CardType.white:
        return 'White';
      case CardType.yellow:
        return 'Yellow';
      case CardType.orange:
        return 'Orange';
      case CardType.blue:
        return 'Blue';
      case CardType.black:
        return 'Black';
      case CardType.red:
        return 'Red';
      case CardType.green:
        return 'Green';
      case CardType.rainbow:
        return 'Rainbow';
    }
  }

  @override
  String toString() {
    return 'Card(type: $type, visible: $isVisible)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Card && other.type == type && other.isVisible == isVisible;
  }

  @override
  int get hashCode => Object.hash(type, isVisible);
}
