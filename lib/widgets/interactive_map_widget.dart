import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math' as math;
import 'dart:ui';
import 'package:path_drawing/path_drawing.dart';
import '../services/map_geometry_service.dart';
import '../models/city_geometry.dart';
import '../models/route_geometry.dart';
import 'package:provider/provider.dart'; // ADD Provider for game data lookup
import '../providers/game_provider.dart';
import '../models/train_route.dart' as game_route;

class InteractiveMapWidget extends StatefulWidget {
  final void Function(game_route.TrainRoute route)? onRouteTap;

  const InteractiveMapWidget({
    super.key,
    this.onRouteTap, // Add to constructor
  });

  @override
  State<InteractiveMapWidget> createState() => _InteractiveMapWidgetState();
}

class _InteractiveMapWidgetState extends State<InteractiveMapWidget> {
  MapGeometryData? _mapData;
  bool _isLoading = true;
  String? _error;
  Matrix4? _transformationMatrix;
  bool _showDebugOverlay = false; // Toggle for debug visualization
  Size? _lastWidgetSize;

  // bool _isTapNearRoutePath(Offset tapPoint, Path routePath) {
  //   const double hitTolerance = 25.0; // Increase this for easier tapping

  //   // Check if the tap point is within the bounding box of the route path,
  //   // inflated by the hit tolerance. This is a simple, non-geometric check.
  //   return routePath.getBounds().inflate(hitTolerance).contains(tapPoint);
  // }

  @override
  void initState() {
    super.initState();
    _loadMapData();
  }

  Future<void> _loadMapData() async {
    try {
      final mapData = await MapGeometryService.loadMapData();
      setState(() {
        _mapData = mapData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _calculateTransformationMatrix(
      Size widgetSize, MapGeometryData mapData) {
    // Calculate scale factors to fit SVG into widget while maintaining aspect ratio
    final scaleX = widgetSize.width / mapData.svgWidth;
    final scaleY = widgetSize.height / mapData.svgHeight;
    final scale =
        math.min(scaleX, scaleY); // Use smaller scale to maintain aspect ratio

    // 1. Calculate centering translation (Tx, Ty)
    final centeredTranslateX =
        (widgetSize.width - mapData.svgWidth * scale) / 2;
    final centeredTranslateY =
        (widgetSize.height - mapData.svgHeight * scale) / 2;

    // 2. Adjust translation by the scaled ViewBox minimums (+- makes no difference becuase view box is 0 0 x y)
    final translateX = centeredTranslateX - mapData.svgMinX * scale;
    final translateY = centeredTranslateY - mapData.svgMinY * scale;

    // Create transformation matrix: M_Final = M_T × M_S (Translate → Scale)
    final matrix = Matrix4.identity()
      ..translate(translateX, translateY) // Translation matrix
      ..scale(scale); // Scale matrix

    print('InteractiveMapWidget: Transformation calculation:');
    print('  SVG dimensions: ${mapData.svgWidth} x ${mapData.svgHeight}');
    print('  Widget size: ${widgetSize.width} x ${widgetSize.height}');
    print('  Scale factors: X=$scaleX, Y=$scaleY, Final scale=$scale');
    print('  Translation: X=$translateX, Y=$translateY');
    // print('  Scaled dimensions: ${scaledWidth} x ${scaledHeight}');
    print('  Final matrix: $matrix');

    // Transform all path objects
    _transformPaths(mapData, matrix);

    _transformationMatrix = matrix;
    _lastWidgetSize = widgetSize;
  }

  void _transformPaths(MapGeometryData mapData, Matrix4 matrix) {
    // Transform city geometries
    for (final cityGeometry in mapData.cityGeometries) {
      try {
        final basePath = parseSvgPathData(cityGeometry.rawPath);
        final transformedPath = basePath.transform(matrix.storage);
        cityGeometry.transformedPath = transformedPath;

        // Log first city for verification
        if (cityGeometry.id == mapData.cityGeometries.first.id) {
          final firstPoint = basePath.getBounds().topLeft;
          final transformedFirstPoint = transformedPath.getBounds().topLeft;
          print(
              'InteractiveMapWidget: City ${cityGeometry.id} transformation:');
          print('  Raw path start: $firstPoint');
          print('  Transformed path start: $transformedFirstPoint');
        }
      } catch (e) {
        print(
            'InteractiveMapWidget: Error transforming city ${cityGeometry.id}: $e');
      }
    }

    // Transform route geometries
    for (final routeGeometry in mapData.routeGeometries) {
      try {
        final basePath = parseSvgPathData(routeGeometry.rawPath);
        final transformedPath = basePath.transform(matrix.storage);
        routeGeometry.transformedPath = transformedPath;

        // Log first route for verification
        if (routeGeometry.id == mapData.routeGeometries.first.id) {
          final firstPoint = basePath.getBounds().topLeft;
          final transformedFirstPoint = transformedPath.getBounds().topLeft;
          print(
              'InteractiveMapWidget: Route ${routeGeometry.id} transformation:');
          print('  Raw path start: $firstPoint');
          print('  Transformed path start: $transformedFirstPoint');
        }
      } catch (e) {
        print(
            'InteractiveMapWidget: Error transforming route ${routeGeometry.id}: $e');
      }
    }
  }

  void _handleTap(Offset tapPosition) {
    if (_mapData == null) return;

    print('InteractiveMapWidget: Tap detected at $tapPosition');

    // Check cities first (they should have priority)
    for (final cityGeometry in _mapData!.cityGeometries) {
      if (cityGeometry.transformedPath != null &&
          cityGeometry.transformedPath!.contains(tapPosition)) {
        print('InteractiveMapWidget: Hit city ${cityGeometry.id}');
        _showTapInfo('City', cityGeometry.id);
        return;
      }
    }

    // Check routes
    for (final routeGeometry in _mapData!.routeGeometries) {
      if (routeGeometry.transformedPath != null &&
          routeGeometry.transformedPath!.contains(tapPosition)) {
        print('InteractiveMapWidget: Hit route ${routeGeometry.id}');
        _showTapInfo('Route', routeGeometry.id);
        return;
      }
    }

    print('InteractiveMapWidget: No hit detected');
  }

  void _showTapInfo(String type, String id) {
    if (_mapData == null) return;

    String infoText = '';

    if (type == 'City') {
      final city = _mapData!.cities[id];
      if (city != null) {
        infoText = 'Tapped City: ${city.name} (${city.id})';
      } else {
        infoText = 'Tapped City: $id (not found in JSON)';
      }
    } else if (type == 'Route') {
      final route = _mapData!.routes.firstWhere(
        (r) => r.id == id,
        orElse: () => game_route.TrainRoute(
            id: '', fromId: '', toId: '', length: 0, color: ''),
      );
      if (route.id.isNotEmpty) {
        final fromCity = _mapData!.cities[route.fromId];
        final toCity = _mapData!.cities[route.toId];
        final fromName = fromCity?.name ?? route.fromId;
        final toName = toCity?.name ?? route.toId;
        infoText =
            'Tapped Route: $fromName → $toName, Length ${route.length}, Color ${route.color} (${route.id})';
      } else {
        infoText = 'Tapped Route: $id (not found in JSON)';
      }
    }

    print('InteractiveMapWidget: $infoText');

    // Show SnackBar with the information
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(infoText),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Text('Error loading map: $_error'),
      );
    }

    if (_mapData == null) {
      return const Center(
        child: Text('No map data available'),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final maxHeight = constraints.maxHeight;
        final widgetSize = Size(maxWidth, maxHeight);

        // print(
        //     'InteractiveMapWidget: LayoutBuilder - maxWidth: $maxWidth, maxHeight: $maxHeight');
        // print('InteractiveMapWidget: Constraints - ${constraints.toString()}');
        // print(
        //     'InteractiveMapWidget: Is height infinite? ${constraints.maxHeight == double.infinity}');

        // Calculate transformation matrix if we have map data and widget size changed
        if (_mapData != null &&
            (_transformationMatrix == null || _lastWidgetSize != widgetSize)) {
          // Use WidgetsBinding to defer the calculation until after build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _calculateTransformationMatrix(widgetSize, _mapData!);
            setState(() {}); // Trigger rebuild after calculation
          });
        }

        return GestureDetector(
          onTapUp: (details) {
            if (_mapData == null || widget.onRouteTap == null) {
              return;
            }

            if (_mapData != null) {
              _handleTap(details.localPosition);
            }
            // final Offset tapPoint = details.localPosition;

            // Loop through all transformed route geometries
            for (final routeGeometry in _mapData!.routeGeometries) {
              if (routeGeometry.transformedPath != null &&
                  routeGeometry.transformedPath!.contains(details.localPosition)) {
                widget.onRouteTap!(routeGeometry.route);
                return;
              }
            }
            // }
          },
          onDoubleTap: () {
            setState(() {
              _showDebugOverlay = !_showDebugOverlay;
            });
            print(
                'InteractiveMapWidget: Debug overlay ${_showDebugOverlay ? 'enabled' : 'disabled'}');
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Base SVG map - this will scale with available space
              SvgPicture.asset(
                'assets/images/map.svg',
                fit: BoxFit.contain,
                placeholderBuilder: (context) =>
                    const CircularProgressIndicator(),
              ),
              // Visual debugging overlay (toggle with double-tap)
              if (_showDebugOverlay &&
                  _mapData != null &&
                  _transformationMatrix != null)
                CustomPaint(
                  painter: MapDebugPainter(
                    cityGeometries: _mapData!.cityGeometries,
                    routeGeometries: _mapData!.routeGeometries,
                  ),
                  size: widgetSize,
                ),
            ],
          ),
        );
      },
    );
  }
}

class MapDebugPainter extends CustomPainter {
  final List<CityGeometry> cityGeometries;
  final List<RouteGeometry> routeGeometries;

  MapDebugPainter({
    required this.cityGeometries,
    required this.routeGeometries,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    // Draw city geometries with red strokes
    for (final cityGeometry in cityGeometries) {
      if (cityGeometry.transformedPath != null) {
        canvas.drawPath(cityGeometry.transformedPath!, paint);
      }
    }

    // Draw route geometries with red strokes
    for (final routeGeometry in routeGeometries) {
      if (routeGeometry.transformedPath != null) {
        canvas.drawPath(routeGeometry.transformedPath!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
