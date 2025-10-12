
class Destination {
  final String from;
  final String to;
  final int points;

  Destination({
    required this.from,
    required this.to,
    required this.points,
  });

  // Get display name for the destination
  String get displayName => '$from → $to';

  // Get short display name
  String get shortName => '$from-$to';

  @override
  String toString() {
    return 'Destination(from: $from, to: $to, points: $points)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Destination && 
           other.from == from && 
           other.to == to && 
           other.points == points;
  }

  @override
  int get hashCode => Object.hash(from, to, points);

  // Firebase serialization
  Map<String, dynamic> toFirebase() {
    return {
      'from': from,
      'to': to,
      'points': points,
    };
  }

  factory Destination.fromFirebase(Map<String, dynamic> data) {
    return Destination(
      from: data['from'] as String,
      to: data['to'] as String,
      points: data['points'] as int,
    );
  }
}
