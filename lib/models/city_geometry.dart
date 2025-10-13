import 'dart:ui';

class CityGeometry {
  final String id;
  final String rawPath;
  Path? transformedPath;

  CityGeometry({
    required this.id,
    required this.rawPath,
    this.transformedPath,
  });

  @override
  String toString() {
    return 'CityGeometry(id: $id, rawPath: $rawPath, hasTransformedPath: ${transformedPath != null})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CityGeometry && other.id == id && other.rawPath == rawPath;
  }

  @override
  int get hashCode => id.hashCode ^ rawPath.hashCode;
}
