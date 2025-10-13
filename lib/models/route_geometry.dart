import 'dart:ui';

class RouteGeometry {
  final String id;
  final String rawPath;
  Path? transformedPath;

  RouteGeometry({
    required this.id,
    required this.rawPath,
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
