import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/objects/geo_point.dart';

void main() {
  group('GeoPoint', () {
    test('constructor creates with coordinates', () {
      const point = GeoPoint(latitude: 45.5, longitude: -122.6);
      expect(point.latitude, 45.5);
      expect(point.longitude, -122.6);
    });

    test('fromNative parses data correctly', () {
      final data = <Object?, Object?>{
        'latitude': 37.7749,
        'longitude': -122.4194,
      };

      final point = GeoPoint.fromNative(data);
      expect(point.latitude, 37.7749);
      expect(point.longitude, -122.4194);
    });

    test('fromNative returns 0,0 when latitude is missing', () {
      final data = <Object?, Object?>{
        'longitude': -122.4194,
      };

      final point = GeoPoint.fromNative(data);
      expect(point.latitude, 0.0);
      expect(point.longitude, 0.0);
    });

    test('fromNative returns 0,0 when longitude is missing', () {
      final data = <Object?, Object?>{
        'latitude': 37.7749,
      };

      final point = GeoPoint.fromNative(data);
      expect(point.latitude, 0.0);
      expect(point.longitude, 0.0);
    });

    test('fromNative returns 0,0 when both coordinates are missing', () {
      final data = <Object?, Object?>{};

      final point = GeoPoint.fromNative(data);
      expect(point.latitude, 0.0);
      expect(point.longitude, 0.0);
    });

    test('fromNative handles null coordinates', () {
      final data = <Object?, Object?>{
        'latitude': null,
        'longitude': null,
      };

      final point = GeoPoint.fromNative(data);
      expect(point.latitude, 0.0);
      expect(point.longitude, 0.0);
    });

    test('fromNative handles negative coordinates', () {
      final data = <Object?, Object?>{
        'latitude': -33.8688,
        'longitude': 151.2093,
      };

      final point = GeoPoint.fromNative(data);
      expect(point.latitude, -33.8688);
      expect(point.longitude, 151.2093);
    });
  });
}