class Route {
  final String id;
  final String fromId;
  final String toId;
  final int length;
  final String color;

  Route({
    required this.id,
    required this.fromId,
    required this.toId,
    required this.length,
    required this.color,
  });

  factory Route.fromJson(Map<String, dynamic> json) {
    return Route(
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
    return other is Route &&
        other.id == id &&
        other.fromId == fromId &&
        other.toId == toId &&
        other.length == length &&
        other.color == color;
  }

  @override
  int get hashCode => id.hashCode ^ fromId.hashCode ^ toId.hashCode ^ length.hashCode ^ color.hashCode;
}
