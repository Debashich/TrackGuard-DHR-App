import 'dart:math';

class DhrWaypoint {
  final String id;
  final String name;
  final double km;
  final double latitude;
  final double longitude;
  final String sectionId;

  const DhrWaypoint({
    required this.id,
    required this.name,
    required this.km,
    required this.latitude,
    required this.longitude,
    required this.sectionId,
  });
}

class DhrSection {
  final String id;
  final String name;
  final double startKm;
  final double endKm;

  const DhrSection({
    required this.id,
    required this.name,
    required this.startKm,
    required this.endKm,
  });
}

class DhrWaypoints {
  static const List<DhrSection> sections = [
    DhrSection(
      id: 'kurseong-ghum',
      name: 'Kurseong → Ghum',
      startKm: 31.0,
      endKm: 74.0,
    ),
    DhrSection(
      id: 'ghum-darjeeling',
      name: 'Ghum → Darjeeling',
      startKm: 74.0,
      endKm: 88.0,
    ),
  ];

  static const List<DhrWaypoint> waypoints = [
    DhrWaypoint(
      id: 'kurseong',
      name: 'Kurseong Station',
      km: 51.0,
      latitude: 26.8812,
      longitude: 88.2789,
      sectionId: 'kurseong-ghum',
    ),
    DhrWaypoint(
      id: 'tung',
      name: 'Tung Station',
      km: 58.0,
      latitude: 26.9200,
      longitude: 88.2678,
      sectionId: 'kurseong-ghum',
    ),
    DhrWaypoint(
      id: 'dilaram',
      name: 'Dilaram Point',
      km: 61.2,
      latitude: 26.9421,
      longitude: 88.2690,
      sectionId: 'kurseong-ghum',
    ),
    DhrWaypoint(
      id: 'sonada',
      name: 'Sonada Station',
      km: 64.5,
      latitude: 26.9634,
      longitude: 88.2721,
      sectionId: 'kurseong-ghum',
    ),
    DhrWaypoint(
      id: 'rongbull',
      name: 'Rongbull Loop',
      km: 70.0,
      latitude: 26.9850,
      longitude: 88.2780,
      sectionId: 'kurseong-ghum',
    ),
    DhrWaypoint(
      id: 'jorebungalow',
      name: 'Jorebungalow',
      km: 72.8,
      latitude: 27.0090,
      longitude: 88.2680,
      sectionId: 'kurseong-ghum',
    ),
    DhrWaypoint(
      id: 'ghum',
      name: 'Ghum Station',
      km: 74.2,
      latitude: 27.0150,
      longitude: 88.2635,
      sectionId: 'ghum-darjeeling',
    ),
    DhrWaypoint(
      id: 'batasia',
      name: 'Batasia Loop',
      km: 78.5,
      latitude: 27.0168,
      longitude: 88.2464,
      sectionId: 'ghum-darjeeling',
    ),
    DhrWaypoint(
      id: 'darjeeling',
      name: 'Darjeeling Station',
      km: 88.0,
      latitude: 27.0425,
      longitude: 88.2625,
      sectionId: 'ghum-darjeeling',
    ),
  ];

  /// Find nearest waypoint by Haversine distance
  static DhrWaypoint findNearestWaypoint(double lat, double lon) {
    DhrWaypoint nearest = waypoints.first;
    double minDistance = double.infinity;

    for (final wp in waypoints) {
      final d = haversineDistanceKm(lat, lon, wp.latitude, wp.longitude);
      if (d < minDistance) {
        minDistance = d;
        nearest = wp;
      }
    }
    return nearest;
  }

  /// Estimate section ID from a kilometer marker
  static String estimateSection(double kmMarker) {
    for (final sec in sections) {
      if (kmMarker >= sec.startKm && kmMarker <= sec.endKm) {
        return sec.id;
      }
    }
    if (kmMarker < 74.0) return 'kurseong-ghum';
    return 'ghum-darjeeling';
  }

  /// Section human readable name
  static String getSectionName(String sectionId) {
    for (final sec in sections) {
      if (sec.id == sectionId) return sec.name;
    }
    return sectionId;
  }

  /// Calculate distance between two lat/lon coordinates in kilometers
  static double haversineDistanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadiusKm = 6371.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) *
            cos(_deg2rad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _deg2rad(double deg) => deg * (pi / 180.0);
}
