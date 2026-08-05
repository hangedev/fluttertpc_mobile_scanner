import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mobile_scanner/src/objects/barcode.dart';

void main() {
  group('scaleCorners', () {
    setUp(() {
      // No setup needed for pure function tests
    });

    tearDown(() {
      // No teardown needed
    });

    test('returns empty list if barcode has no size or corners', () {
      const barcode = Barcode();

      expect(barcode.scaleCorners(const Size(100, 100)), isEmpty);
    });

    test('returns empty list if barcode has no corners', () {
      const barcode = Barcode(size: Size(200, 200));

      expect(barcode.scaleCorners(const Size(100, 100)), isEmpty);
    });

    test('returns zeroed corners if barcode has corners but no size', () {
      const barcode = Barcode(
        corners: [Offset.zero, Offset.zero, Offset.zero, Offset.zero],
      );

      expect(barcode.scaleCorners(const Size(100, 100)), [
        Offset.zero,
        Offset.zero,
        Offset.zero,
        Offset.zero,
      ]);
    });

    test('returns zeroed corners if target size is empty', () {
      const barcode = Barcode(
        size: Size(200, 200),
        corners: [
          Offset(50, 50),
          Offset(150, 50),
          Offset(150, 150),
          Offset(50, 150),
        ],
      );

      expect(barcode.scaleCorners(Size.zero), [
        Offset.zero,
        Offset.zero,
        Offset.zero,
        Offset.zero,
      ]);
    });

    test('returns scaled corners', () {
      const barcode = Barcode(
        size: Size(100, 100),
        corners: [
          Offset(25, 25),
          Offset(75, 25),
          Offset(75, 75),
          Offset(25, 75),
        ],
      );

      expect(barcode.scaleCorners(const Size(200, 200)), const [
        Offset(50, 50),
        Offset(150, 50),
        Offset(150, 150),
        Offset(50, 150),
      ]);
    });
  });

  group('Barcode', () {
    test('displayValue property is set correctly', () {
      const barcode = Barcode(displayValue: 'Product: 12345');
      expect(barcode.displayValue, 'Product: 12345');
    });

    test('displayValue is null by default', () {
      const barcode = Barcode();
      expect(barcode.displayValue, isNull);
    });

    test('rawBytes property is set correctly', () {
      final bytes = Uint8List.fromList([0x48, 0x65, 0x6C, 0x6C, 0x6F]);
      final barcode = Barcode(rawBytes: bytes);
      expect(barcode.rawBytes, bytes);
    });

    test('rawValue property is set correctly', () {
      const barcode = Barcode(rawValue: 'test-value');
      expect(barcode.rawValue, 'test-value');
    });

    test('calendarEvent property is set correctly', () {
      final barcode = Barcode(
        calendarEvent: CalendarEvent(description: 'Meeting'),
      );
      expect(barcode.calendarEvent?.description, 'Meeting');
    });

    test('contactInfo property is set correctly', () {
      final barcode = Barcode(
        contactInfo: ContactInfo(organization: 'Acme Inc'),
      );
      expect(barcode.contactInfo?.organization, 'Acme Inc');
    });

    test('driverLicense property is set correctly', () {
      final barcode = Barcode(
        driverLicense: DriverLicense(firstName: 'John'),
      );
      expect(barcode.driverLicense?.firstName, 'John');
    });

    test('email property is set correctly', () {
      final barcode = Barcode(email: Email(address: 'test@example.com'));
      expect(barcode.email?.address, 'test@example.com');
    });

    test('geoPoint property is set correctly', () {
      final barcode = Barcode(
        geoPoint: const GeoPoint(latitude: 37.7749, longitude: -122.4194),
      );
      expect(barcode.geoPoint?.latitude, 37.7749);
    });

    test('phone property is set correctly', () {
      final barcode = Barcode(phone: Phone(number: '555-1234'));
      expect(barcode.phone?.number, '555-1234');
    });

    test('sms property is set correctly', () {
      final barcode = Barcode(sms: SMS(phoneNumber: '555-5678'));
      expect(barcode.sms?.phoneNumber, '555-5678');
    });

    test('url property is set correctly', () {
      final barcode = Barcode(
        url: UrlBookmark(url: 'https://example.com'),
      );
      expect(barcode.url?.url, 'https://example.com');
    });

    test('wifi property is set correctly', () {
      final barcode = Barcode(wifi: WiFi(ssid: 'HomeNetwork'));
      expect(barcode.wifi?.ssid, 'HomeNetwork');
    });
  });

  group('BarcodeCapture', () {
    test('raw property is set correctly', () {
      final raw = {'test': 'data'};
      final capture = BarcodeCapture(raw: raw);
      expect(capture.raw, raw);
    });

    test('raw property is null by default', () {
      const capture = BarcodeCapture();
      expect(capture.raw, isNull);
    });

    test('image property is set correctly', () {
      final image = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0]);
      final capture = BarcodeCapture(image: image);
      expect(capture.image, image);
    });

    test('size property is set correctly', () {
      const capture = BarcodeCapture(size: Size(1920, 1080));
      expect(capture.size, const Size(1920, 1080));
    });
  });
}
