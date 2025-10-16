import 'dart:ui';

import 'package:ticket_to_ride/models/train_route.dart';

class RouteGeometry {
  final String id;
  final String rawPath;
  final TrainRoute route;
  Path? transformedPath;

  RouteGeometry({
    required this.id,
    required this.rawPath,
    required this.route, 
    this.transformedPath,
  });

  @override
  String toString() {
    return 'RouteGeometry(id: $id, rawPath: $rawPath, hasTransformedPath: ${transformedPath != null})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RouteGeometry && other.id == id && other.rawPath == rawPath;
  }

  @override
  int get hashCode => id.hashCode ^ rawPath.hashCode;
}
