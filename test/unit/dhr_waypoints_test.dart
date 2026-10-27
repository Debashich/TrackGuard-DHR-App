import 'package:flutter_test/flutter_test.dart';
import 'package:trackguard_dhr/core/constants/dhr_waypoints.dart';

void main() {
  group('DHR Waypoints & Geometry Tests', () {
    test('Nearest waypoint detection near Ghum Station', () {
      // Coordinates very close to Ghum (lat 27.0150, lon 88.2635)
      final nearest = DhrWaypoints.findNearestWaypoint(27.0152, 88.2638);
      expect(nearest.id, 'ghum');
      expect(nearest.name, 'Ghum Station');
      expect(nearest.km, 74.2);
    });

    test('Nearest waypoint detection near Kurseong Station', () {
      // Coordinates close to Kurseong (lat 26.8812, lon 88.2789)
      final nearest = DhrWaypoints.findNearestWaypoint(26.8810, 88.2785);
      expect(nearest.id, 'kurseong');
      expect(nearest.name, 'Kurseong Station');
      expect(nearest.km, 51.0);
    });

    test('Haversine distance is accurate', () {
      // Distance between Kurseong and Tung stations
      final d = DhrWaypoints.haversineDistanceKm(
        26.8812,
        88.2789,
        26.9200,
        88.2678,
      );
      // Rough distance is ~4.4 km as the crow flies
      expect(d, greaterThan(4.0));
      expect(d, lessThan(5.0));
    });

    test('Section estimation from km marker', () {
      expect(DhrWaypoints.estimateSection(45.0), 'kurseong-ghum');
      expect(DhrWaypoints.estimateSection(70.0), 'kurseong-ghum');
      expect(DhrWaypoints.estimateSection(74.0), 'kurseong-ghum');
      expect(DhrWaypoints.estimateSection(75.0), 'ghum-darjeeling');
      expect(DhrWaypoints.estimateSection(88.0), 'ghum-darjeeling');
    });

    test('Section human readable name resolution', () {
      expect(DhrWaypoints.getSectionName('kurseong-ghum'), 'Kurseong → Ghum');
      expect(
        DhrWaypoints.getSectionName('ghum-darjeeling'),
        'Ghum → Darjeeling',
      );
    });
  });
}
