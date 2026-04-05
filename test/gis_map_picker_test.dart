import 'package:flutter_test/flutter_test.dart';
import 'package:king_food/services/location_service.dart';

void main() {
  group('LocationService Tests', () {
    test('MapLocation should create correctly', () {
      const location = MapLocation(latitude: 55.8304, longitude: 49.0661);

      expect(location.latitude, 55.8304);
      expect(location.longitude, 49.0661);
    });

    test('LocationService should be singleton', () {
      final service1 = LocationService();
      final service2 = LocationService();

      expect(identical(service1, service2), true);
    });

    test('MapLocation equality', () {
      const location1 = MapLocation(latitude: 55.8304, longitude: 49.0661);
      const location2 = MapLocation(latitude: 55.8304, longitude: 49.0661);

      expect(location1.latitude == location2.latitude, true);
      expect(location1.longitude == location2.longitude, true);
    });
  });
}
