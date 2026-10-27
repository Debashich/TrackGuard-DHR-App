import 'package:geolocator/geolocator.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/dhr_waypoints.dart';
import '../../../shared/models/geo_location.dart';
import '../../../shared/models/location_source.dart';

class LocationService {
  Future<GeoLocation> getCurrentLocation() async {
    try {
      final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isServiceEnabled) {
        return createFallbackLocation();
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          return createFallbackLocation();
        }
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: AppConstants.gpsTimeoutSeconds),
        ),
      );

      final nearestWp = DhrWaypoints.findNearestWaypoint(
        position.latitude,
        position.longitude,
      );
      final distanceToWp = DhrWaypoints.haversineDistanceKm(
        position.latitude,
        position.longitude,
        nearestWp.latitude,
        nearestWp.longitude,
      );
      final sectionId = DhrWaypoints.estimateSection(nearestWp.km);

      return GeoLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracyMeters: position.accuracy,
        kmMarker: nearestWp.km,
        sectionId: sectionId,
        nearestStationName: nearestWp.name,
        distanceToAlignmentKm: distanceToWp,
        capturedAt: position.timestamp,
        source: LocationSource.gps,
        isSimulated: false,
      );
    } catch (_) {
      return createFallbackLocation();
    }
  }

  GeoLocation createFallbackLocation() {
    return GeoLocation(
      latitude: AppConstants.fallbackLat,
      longitude: AppConstants.fallbackLon,
      accuracyMeters: null,
      kmMarker: AppConstants.fallbackKm,
      sectionId: AppConstants.fallbackSection,
      nearestStationName: AppConstants.fallbackStation,
      distanceToAlignmentKm: null,
      capturedAt: DateTime.now(),
      source: LocationSource.fallback,
      isSimulated: true,
    );
  }

  GeoLocation createManualLocation({
    required DhrWaypoint waypoint,
    double? customKm,
  }) {
    final km = customKm ?? waypoint.km;
    final sectionId = DhrWaypoints.estimateSection(km);

    return GeoLocation(
      latitude: waypoint.latitude,
      longitude: waypoint.longitude,
      accuracyMeters: null,
      kmMarker: km,
      sectionId: sectionId,
      nearestStationName: waypoint.name,
      distanceToAlignmentKm: 0.0,
      capturedAt: DateTime.now(),
      source: LocationSource.manual,
      isSimulated: true,
    );
  }
}
