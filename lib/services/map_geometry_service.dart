import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:xml/xml.dart';
import '../models/city_geometry.dart';
import '../models/route_geometry.dart';
import '../models/city.dart';
import '../models/route.dart';

class MapGeometryService {
  static Future<MapGeometryData> loadMapData() async {
    try {
      // Load JSON data
      final jsonString = await rootBundle.loadString('assets/map_info.JSON');
      final jsonData = json.decode(jsonString);

      // Parse cities from JSON
      final cities = <String, City>{};
      final citiesJson = jsonData['cities'] as Map<String, dynamic>;
      citiesJson.forEach((id, name) {
        cities[id] = City(id: id, name: name);
      });

      // Parse routes from JSON
      final routes = <Route>[];
      final routesJson = jsonData['routes'] as List<dynamic>;
      for (final routeJson in routesJson) {
        routes.add(Route.fromJson(routeJson));
      }

      // Load SVG data
      final svgString = await rootBundle.loadString('assets/images/map.svg');
      final document = XmlDocument.parse(svgString);

      // Extract city geometries
      final cityGeometries = <CityGeometry>[];
      final cityElements = document.findAllElements('circle');
      for (final element in cityElements) {
        final id = element.getAttribute('id');
        if (id != null && id.startsWith('C')) {
          // Extract circle center coordinates
          final cx = element.getAttribute('cx') ?? '0';
          final cy = element.getAttribute('cy') ?? '0';
          final r = element.getAttribute('r') ?? '5';

          // Create a simple path representation for the circle
          final rawPath =
              'M ${cx} ${cy} m -${r} 0 a ${r} ${r} 0 1 0 ${double.parse(r) * 2} 0 a ${r} ${r} 0 1 0 -${double.parse(r) * 2} 0';

          cityGeometries.add(CityGeometry(
            id: id,
            rawPath: rawPath,
          ));
        }
      }

      // Extract route geometries
      final routeGeometries = <RouteGeometry>[];
      final pathElements = document.findAllElements('path');
      for (final element in pathElements) {
        final id = element.getAttribute('id');
        if (id != null && id.startsWith('R')) {
          final rawPath = element.getAttribute('d') ?? '';
          if (rawPath.isNotEmpty) {
            routeGeometries.add(RouteGeometry(
              id: id,
              rawPath: rawPath,
            ));
          }
        }
      }

      // Extract SVG viewBox for transformation calculations
      final svgElement = document.rootElement;
      final viewBox = svgElement.getAttribute('viewBox') ?? '0 0 1000 1000';
      final viewBoxParts = viewBox.split(' ');
      final svgMinX = double.parse(viewBoxParts[0]); // New
      final svgMinY = double.parse(viewBoxParts[1]); // New
      final svgWidth = double.parse(viewBoxParts[2]);
      final svgHeight = double.parse(viewBoxParts[3]);

      print(
          'MapGeometryService: Loaded ${cities.length} cities, ${routes.length} routes');
      print(
          'MapGeometryService: Found ${cityGeometries.length} city geometries, ${routeGeometries.length} route geometries');
      print(
          'MapGeometryService: SVG viewBox: $viewBox (${svgWidth}x${svgHeight})');

      // Log first few examples for verification
      if (cityGeometries.isNotEmpty) {
        print(
            'MapGeometryService: First city geometry - ID: ${cityGeometries.first.id}, RawPath: ${cityGeometries.first.rawPath}');
      }
      if (routeGeometries.isNotEmpty) {
        print(
            'MapGeometryService: First route geometry - ID: ${routeGeometries.first.id}, RawPath: ${routeGeometries.first.rawPath}');
      }

      return MapGeometryData(
        cities: cities,
        routes: routes,
        cityGeometries: cityGeometries,
        routeGeometries: routeGeometries,
        svgWidth: svgWidth,
        svgHeight: svgHeight,
        svgMinX: svgMinX, // Passed to MapGeometryData
        svgMinY: svgMinY, // Passed to MapGeometryData
      );
    } catch (e) {
      print('MapGeometryService: Error loading map data: $e');
      rethrow;
    }
  }
}

class MapGeometryData {
  final Map<String, City> cities;
  final List<Route> routes;
  final List<CityGeometry> cityGeometries;
  final List<RouteGeometry> routeGeometries;
  final double svgWidth;
  final double svgHeight;
  final double svgMinX; // New field
  final double svgMinY; // New field

  MapGeometryData({
    required this.cities,
    required this.routes,
    required this.cityGeometries,
    required this.routeGeometries,
    required this.svgWidth,
    required this.svgHeight,
    required this.svgMinX, // Required
    required this.svgMinY, // Required
  });
}
