import 'package:google_maps_flutter/google_maps_flutter.dart';

class RouteInfo {
  final List<LatLng> polylinePoints;
  final String distance;
  final String duration;
  final List<RouteStep> steps;

  RouteInfo({
    required this.polylinePoints,
    required this.distance,
    required this.duration,
    required this.steps,
  });
}

class RouteStep {
  final String instruction;
  final String distance;
  final String duration;
  final LatLng startLocation;
  final LatLng endLocation;

  RouteStep({
    required this.instruction,
    required this.distance,
    required this.duration,
    required this.startLocation,
    required this.endLocation,
  });
}
