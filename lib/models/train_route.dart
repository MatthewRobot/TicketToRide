import 'card.dart' as game_card;

class TrainRoute {
  final String id;
  final String fromId;
  final String toId;
  final int length;
  final String color;

  TrainRoute({
    required this.id,
    required this.fromId,
    required this.toId,
    required this.length,
    required this.color,
  });

  game_card.CardType? get requiredCardType {
    switch (color.toLowerCase()) {
      case 'pink':
        return game_card.CardType.pink;
      case 'white':
        return game_card.CardType.white;
      case 'yellow':
        return game_card.CardType.yellow;
      case 'orange':
        return game_card.CardType.orange;
      case 'blue':
        return game_card.CardType.blue;
      case 'black':
        return game_card.CardType.black;
      case 'red':
        return game_card.CardType.red;
      case 'green':
        return game_card.CardType.green;
      // Grey/Any maps to null or a special value if needed, but the PlaceRoute
      // logic below handles 'grey' explicitly. For simplicity, we can let the
      // widget handle 'grey'.
      default:
        return null; // For 'grey' or other non-train colors
    }
  }

  factory TrainRoute.fromJson(Map<String, dynamic> json) {
    return TrainRoute(
      id: json['id'] ?? '',
      fromId: json['from'] ?? '',
      toId: json['to'] ?? '',
      length: json['length'] ?? 0,
      color: json['color'] ?? 'grey',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'from': fromId,
      'to': toId,
      'length': length,
      'color': color,
    };
  }

  @override
  String toString() {
    return 'Route(id: $id, from: $fromId, to: $toId, length: $length, color: $color)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TrainRoute &&
        other.id == id &&
        other.fromId == fromId &&
        other.toId == toId &&
        other.length == length &&
        other.color == color;
  }

  @override
  int get hashCode =>
      id.hashCode ^
      fromId.hashCode ^
      toId.hashCode ^
      length.hashCode ^
      color.hashCode;
}
