import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/enums/barcode_format.dart';
import 'package:mobile_scanner/src/enums/barcode_type.dart';
import 'package:mobile_scanner/src/objects/barcode.dart';

void main() {
  group('Barcode', () {
    group('fromNative', () {
      test('should create barcode from valid data', () {
        final data = <Object?, Object?>{
          'calendarEvent': null,
          'contactInfo': null,
          'corners': <Object?>[
            <Object?, Object?>{'x': 0.0, 'y': 0.0},
            <Object?, Object?>{'x': 100.0, 'y': 0.0},
            <Object?, Object?>{'x': 100.0, 'y': 100.0},
            <Object?, Object?>{'x': 0.0, 'y': 100.0},
          ],
          'displayValue': 'test-value',
          'driverLicense': null,
          'email': null,
          'format': 256, // qrCode
          'geoPoint': null,
          'phone': null,
          'rawBytes': null,
          'rawValue': 'test-raw',
          'size': <Object?, Object?>{'width': 100.0, 'height': 100.0},
          'sms': null,
          'type': 7, // text
          'url': null,
          'wifi': null,
        };

        final barcode = Barcode.fromNative(data);
        expect(barcode.displayValue, 'test-value');
        expect(barcode.rawValue, 'test-raw');
        expect(barcode.format, BarcodeFormat.qrCode);
        expect(barcode.type, BarcodeType.text);
        expect(barcode.corners.length, 4);
        expect(barcode.size.width, 100.0);
        expect(barcode.size.height, 100.0);
        expect(barcode.calendarEvent, isNull);
        expect(barcode.contactInfo, isNull);
        expect(barcode.driverLicense, isNull);
        expect(barcode.email, isNull);
        expect(barcode.geoPoint, isNull);
        expect(barcode.phone, isNull);
        expect(barcode.rawBytes, isNull);
        expect(barcode.sms, isNull);
        expect(barcode.url, isNull);
        expect(barcode.wifi, isNull);
      });

      test('should create barcode with embedded structured data', () {
        final data = <Object?, Object?>{
          'calendarEvent': <Object?, Object?>{
            'description': 'Meeting',
            'start': '2024-01-01T09:00:00Z',
            'end': '2024-01-01T10:00:00Z',
            'location': 'Room 1',
            'organizer': 'test@example.com',
            'status': 'confirmed',
            'summary': 'Team meeting',
          },
          'contactInfo': <Object?, Object?>{
            'name': <Object?, Object?>{
              'first': 'John', 'formattedName': 'John Doe', 'last': 'Doe',
            },
            'organization': 'ACME',
            'title': 'Engineer',
          },
          'corners': null,
          'displayValue': 'test',
          'driverLicense': <Object?, Object?>{
            'firstName': 'John', 'lastName': 'Doe', 'licenseNumber': 'D12345',
          },
          'email': <Object?, Object?>{
            'address': 'test@example.com', 'body': 'Body', 'subject': 'Sub', 'type': 1,
          },
          'format': 256,
          'geoPoint': <Object?, Object?>{'latitude': 37.77, 'longitude': -122.42},
          'phone': <Object?, Object?>{'number': '+1234567890', 'type': 2},
          'rawBytes': Uint8List.fromList([0, 1, 2]),
          'rawValue': 'test-raw',
          'size': null,
          'sms': <Object?, Object?>{'message': 'Hello', 'phoneNumber': '+123'},
          'type': 0,
          'url': <Object?, Object?>{'title': 'Example', 'url': 'https://example.com'},
          'wifi': <Object?, Object?>{'ssid': 'MyWiFi', 'password': 'pass', 'encryptionType': 3},
        };

        final barcode = Barcode.fromNative(data);
        expect(barcode.calendarEvent, isNotNull);
        expect(barcode.calendarEvent!.description, 'Meeting');
        expect(barcode.contactInfo, isNotNull);
        expect(barcode.contactInfo!.organization, 'ACME');
        expect(barcode.driverLicense, isNotNull);
        expect(barcode.driverLicense!.firstName, 'John');
        expect(barcode.email, isNotNull);
        expect(barcode.email!.address, 'test@example.com');
        expect(barcode.geoPoint, isNotNull);
        expect(barcode.geoPoint!.latitude, 37.77);
        expect(barcode.phone, isNotNull);
        expect(barcode.phone!.number, '+1234567890');
        expect(barcode.rawBytes, isNotNull);
        expect(barcode.sms, isNotNull);
        expect(barcode.sms!.message, 'Hello');
        expect(barcode.url, isNotNull);
        expect(barcode.url!.url, 'https://example.com');
        expect(barcode.wifi, isNotNull);
        expect(barcode.wifi!.ssid, 'MyWiFi');
      });

      test('should create barcode with null values', () {
        final data = <Object?, Object?>{
          'calendarEvent': null,
          'contactInfo': null,
          'corners': null,
          'displayValue': null,
          'driverLicense': null,
          'email': null,
          'format': -1, // unknown
          'geoPoint': null,
          'phone': null,
          'rawBytes': null,
          'rawValue': null,
          'size': null,
          'sms': null,
          'type': 0, // unknown
          'url': null,
          'wifi': null,
        };

        final barcode = Barcode.fromNative(data);
        expect(barcode.displayValue, isNull);
        expect(barcode.rawValue, isNull);
        expect(barcode.format, BarcodeFormat.unknown);
        expect(barcode.type, BarcodeType.unknown);
        expect(barcode.corners, isEmpty);
        expect(barcode.size, isNotNull);
      });

      test('should create barcode with all known formats', () {
        final formatValues = <int, BarcodeFormat>{
          -1: BarcodeFormat.unknown,
          0: BarcodeFormat.all,
          1: BarcodeFormat.code128,
          2: BarcodeFormat.code39,
          4: BarcodeFormat.code93,
          8: BarcodeFormat.codabar,
          16: BarcodeFormat.dataMatrix,
          32: BarcodeFormat.ean13,
          64: BarcodeFormat.ean8,
          128: BarcodeFormat.itf,
          256: BarcodeFormat.qrCode,
          512: BarcodeFormat.upcA,
          1024: BarcodeFormat.upcE,
          2048: BarcodeFormat.pdf417,
          4096: BarcodeFormat.aztec,
        };

        for (final entry in formatValues.entries) {
          final data = <Object?, Object?>{
            'calendarEvent': null, 'contactInfo': null, 'corners': null,
            'displayValue': 'test', 'driverLicense': null, 'email': null,
            'format': entry.key, 'geoPoint': null, 'phone': null,
            'rawBytes': null, 'rawValue': 'test', 'size': null,
            'sms': null, 'type': 0, 'url': null, 'wifi': null,
          };

          final barcode = Barcode.fromNative(data);
          expect(barcode.format, entry.value,
              reason: 'Expected format ${entry.value} for raw value ${entry.key}');
        }
      });

      test('should create barcode with all known types', () {
        final typeValues = <int, BarcodeType>{
          0: BarcodeType.unknown,
          1: BarcodeType.contactInfo,
          2: BarcodeType.email,
          3: BarcodeType.isbn,
          4: BarcodeType.phone,
          5: BarcodeType.product,
          6: BarcodeType.sms,
          7: BarcodeType.text,
          8: BarcodeType.url,
          9: BarcodeType.wifi,
          10: BarcodeType.geo,
          11: BarcodeType.calendarEvent,
          12: BarcodeType.driverLicense,
        };

        for (final entry in typeValues.entries) {
          final data = <Object?, Object?>{
            'calendarEvent': null, 'contactInfo': null, 'corners': null,
            'displayValue': 'test', 'driverLicense': null, 'email': null,
            'format': 256, 'geoPoint': null, 'phone': null,
            'rawBytes': null, 'rawValue': 'test', 'size': null,
            'sms': null, 'type': entry.key, 'url': null, 'wifi': null,
          };

          final barcode = Barcode.fromNative(data);
          expect(barcode.type, entry.value,
              reason: 'Expected type ${entry.value} for raw value ${entry.key}');
        }
      });

      test('should create barcode with corners', () {
        final data = <Object?, Object?>{
          'calendarEvent': null, 'contactInfo': null, 'corners': null,
          'displayValue': 'test', 'driverLicense': null, 'email': null,
          'format': 256, 'geoPoint': null, 'phone': null,
          'rawBytes': null, 'rawValue': 'test', 'size': <Object?, Object?>{'width': 200.0, 'height': 150.0},
          'sms': null, 'type': 0, 'url': null, 'wifi': null,
        };

        final barcode = Barcode.fromNative(data);
        expect(barcode.corners.length, 0);
        expect(barcode.size.width, 200.0);
        expect(barcode.size.height, 150.0);
      });
    });

    group('constructor', () {
      test('should create with default values', () {
        const barcode = Barcode();
        expect(barcode.displayValue, isNull);
        expect(barcode.rawValue, isNull);
        expect(barcode.format, BarcodeFormat.unknown);
        expect(barcode.type, BarcodeType.unknown);
        expect(barcode.corners, isEmpty);
        expect(barcode.size, isNotNull);
      });

      test('should create with custom values', () {
        const barcode = Barcode(
          displayValue: 'test',
          rawValue: 'test-raw',
          format: BarcodeFormat.qrCode,
          type: BarcodeType.text,
        );
        expect(barcode.displayValue, 'test');
        expect(barcode.rawValue, 'test-raw');
        expect(barcode.format, BarcodeFormat.qrCode);
        expect(barcode.type, BarcodeType.text);
      });
    });
  });
}