import 'dart:math';
import 'card.dart';
import 'player.dart';

class Deck {
  List<Card> _stack = [];
  List<Card> _table = [];
  List<Card> _usedPile = [];

  Deck() {
    _initializeDeck();
    _shuffleDeck();
  }

  void _initializeDeck() {
    _stack.clear();

    // Add cards according to the specified counts
    final cardCounts = {
      CardType.pink: 12,
      CardType.white: 12,
      CardType.yellow: 12,
      CardType.orange: 12,
      CardType.blue: 12,
      CardType.black: 12,
      CardType.red: 12,
      CardType.green: 12,
      CardType.rainbow: 14,
    };

    for (final entry in cardCounts.entries) {
      for (int i = 0; i < entry.value; i++) {
        _stack.add(Card(type: entry.key, isVisible: false));
      }
    }
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

  // Initialize game: give 4 cards to each player, put 5 on table
  void initializeGame(List<Player> players) {
    // Give 4 cards to each player
    for (final player in players) {
      for (int i = 0; i < 4; i++) {
        final card = drawCard();
        if (card != null) {
          player.handOfCards.add(card);
        }
      }
    }

    // Put 5 cards on table (visible)
    for (int i = 0; i < 5; i++) {
      final card = drawCard();
      if (card != null) {
        _table.add(Card(type: card.type, isVisible: true));
      }
    }
  }

  // Draw a card from the top of the stack
  Card? drawCard() {
    if (_stack.isEmpty) {
      _reshuffleUsedPile();
    }

    if (_stack.isNotEmpty) {
      return _stack.removeAt(0);
    }
    return null;
  }

  // Take a card from the table
  Card? takeCardFromTable(int tableIndex) {
    if (tableIndex >= 0 && tableIndex < _table.length) {
      // 1. Remove the card the player is taking
      final card = _table.removeAt(tableIndex);

      // 2. Replace with a card from the stack
      // The replacement logic must ensure the table is always full (5 cards)
      final replacementCard = drawCard();
      if (replacementCard != null) {
        _table.insert(
            tableIndex, Card(type: replacementCard.type, isVisible: true));
      }

      // 3. --- CORRECTED LOGIC: Check for Rainbow Card Flush *AFTER* replacement ---
      // We loop in case the reshuffle results in another flush condition
      while (_table.length == 5 &&
          _table.where((c) => c.type == CardType.rainbow).length >= 3) {
        print(
            'Flushing table: 3 or more Rainbow cards detected after replacement.');

        // Move all current table cards to the used pile
        _usedPile.addAll(_table);
        _table.clear();

        // Replace with 5 new cards from the stack
        for (int i = 0; i < 5; i++) {
          final newCard = drawCard();
          if (newCard != null) {
            _table.add(Card(type: newCard.type, isVisible: true));
          } else {
            break;
          }
        }
      }

      return card;
    }
    return null;
  }

  // Add a card to the used pile
  void addToUsedPile(Card card) {
    _usedPile.add(card);
  }

  // Reshuffle used pile back into stack
  void _reshuffleUsedPile() {
    _stack = List.from(_usedPile);
    _usedPile.clear();
    _shuffleDeck();
  }

  // Getters for game state
  List<Card> get table => List.unmodifiable(_table);
  int get stackSize => _stack.length;
  int get usedPileSize => _usedPile.length;

  // Get table cards for display (with their colors visible)
  List<Card> get visibleTableCards => List.unmodifiable(_table);

  @override
  String toString() {
    return 'Deck(stack: ${_stack.length}, table: ${_table.length}, used: ${_usedPile.length})';
  }

  // Firebase serialization
  Map<String, dynamic> toFirebase() {
    return {
      'stack': _stack.map((c) => c.toFirebase()).toList(),
      'table': _table.map((c) => c.toFirebase()).toList(),
      'usedPile': _usedPile.map((c) => c.toFirebase()).toList(),
    };
  }

  factory Deck.fromFirebase(Map<String, dynamic> data) {
    final deck = Deck();
    deck._stack =
        (data['stack'] as List).map((c) => Card.fromFirebase(c)).toList();
    deck._table =
        (data['table'] as List).map((c) => Card.fromFirebase(c)).toList();
    deck._usedPile =
        (data['usedPile'] as List).map((c) => Card.fromFirebase(c)).toList();
    return deck;
  }
}
