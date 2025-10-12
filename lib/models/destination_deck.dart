import 'dart:math';
import 'destination.dart';

class DestinationDeck {
  List<Destination> _stack = [];
  List<Destination> _usedPile = [];

  DestinationDeck() {
    _initializeDeck();
    _shuffleDeck();
  }

  void _initializeDeck() {
    _stack.clear();
    
    // Add all 30 destination cards
    final destinations = [
      Destination(from: 'Boston', to: 'Miami', points: 12),
      Destination(from: 'Calgary', to: 'Phoenix', points: 13),
      Destination(from: 'Calgary', to: 'Salt Lake City', points: 7),
      Destination(from: 'Chicago', to: 'New Orleans', points: 7),
      Destination(from: 'Chicago', to: 'Santa Fe', points: 9),
      Destination(from: 'Dallas', to: 'New York', points: 11),
      Destination(from: 'Denver', to: 'El Paso', points: 4),
      Destination(from: 'Denver', to: 'Pittsburgh', points: 11),
      Destination(from: 'Duluth', to: 'El Paso', points: 10),
      Destination(from: 'Duluth', to: 'Houston', points: 8),
      Destination(from: 'Helena', to: 'Los Angeles', points: 8),
      Destination(from: 'Kansas City', to: 'Houston', points: 5),
      Destination(from: 'Los Angeles', to: 'Chicago', points: 16),
      Destination(from: 'Los Angeles', to: 'Miami', points: 20),
      Destination(from: 'Los Angeles', to: 'New York', points: 21),
      Destination(from: 'Montréal', to: 'Atlanta', points: 9),
      Destination(from: 'Montréal', to: 'New Orleans', points: 13),
      Destination(from: 'New York', to: 'Atlanta', points: 6),
      Destination(from: 'Portland', to: 'Nashville', points: 17),
      Destination(from: 'Portland', to: 'Phoenix', points: 11),
      Destination(from: 'San Francisco', to: 'Atlanta', points: 17),
      Destination(from: 'Sault St. Marie', to: 'Nashville', points: 8),
      Destination(from: 'Sault St. Marie', to: 'Oklahoma City', points: 9),
      Destination(from: 'Seattle', to: 'Los Angeles', points: 9),
      Destination(from: 'Seattle', to: 'New York', points: 22),
      Destination(from: 'Toronto', to: 'Miami', points: 10),
      Destination(from: 'Vancouver', to: 'Montréal', points: 20),
      Destination(from: 'Vancouver', to: 'Santa Fe', points: 13),
      Destination(from: 'Winnipeg', to: 'Houston', points: 12),
      Destination(from: 'Winnipeg', to: 'Little Rock', points: 11),
    ];

    _stack.addAll(destinations);
  }

  // Fisher-Yates (Knuth) Shuffle Algorithm
  void _shuffleDeck() {
    final random = Random();
    for (int i = _stack.length - 1; i > 0; i--) {
      final j = random.nextInt(i + 1);
      final temp = _stack[i];
      _stack[i] = _stack[j];
      _stack[j] = temp;
    }
  }

  // Draw a destination card from the top of the stack
  Destination? drawDestination() {
    if (_stack.isEmpty) {
      _reshuffleUsedPile();
    }
    
    if (_stack.isNotEmpty) {
      return _stack.removeAt(0);
    }
    return null;
  }

  // Add a destination to the used pile
  void addToUsedPile(Destination destination) {
    _usedPile.add(destination);
  }

  // Reshuffle used pile back into stack
  void _reshuffleUsedPile() {
    _stack = List.from(_usedPile);
    _usedPile.clear();
    _shuffleDeck();
  }

  // Deal initial destination cards to players (typically 3-4 cards)
  List<Destination> dealInitialDestinations(int count) {
    List<Destination> dealtCards = [];
    for (int i = 0; i < count && _stack.isNotEmpty; i++) {
      final destination = drawDestination();
      if (destination != null) {
        dealtCards.add(destination);
      }
    }
    return dealtCards;
  }

  // Getters for game state
  int get stackSize => _stack.length;
  int get usedPileSize => _usedPile.length;
  List<Destination> get remainingDestinations => List.unmodifiable(_stack);

  @override
  String toString() {
    return 'DestinationDeck(stack: ${_stack.length}, used: ${_usedPile.length})';
  }

  // Firebase serialization
  Map<String, dynamic> toFirebase() {
    return {
      'stack': _stack.map((d) => d.toFirebase()).toList(),
      'usedPile': _usedPile.map((d) => d.toFirebase()).toList(),
    };
  }

  factory DestinationDeck.fromFirebase(Map<String, dynamic> data) {
    final deck = DestinationDeck();
    deck._stack = (data['stack'] as List)
        .map((d) => Destination.fromFirebase(d))
        .toList();
    deck._usedPile = (data['usedPile'] as List)
        .map((d) => Destination.fromFirebase(d))
        .toList();
    return deck;
  }
}
