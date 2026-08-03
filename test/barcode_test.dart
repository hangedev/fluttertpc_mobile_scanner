import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/enums/barcode_format.dart';
import 'package:mobile_scanner/src/enums/barcode_type.dart';
import 'package:mobile_scanner/src/enums/encryption_type.dart';
import 'package:mobile_scanner/src/objects/barcode.dart';
import 'package:mobile_scanner/src/objects/calendar_event.dart';
import 'package:mobile_scanner/src/objects/contact_info.dart';
import 'package:mobile_scanner/src/objects/driver_license.dart';
import 'package:mobile_scanner/src/objects/email.dart';
import 'package:mobile_scanner/src/objects/geo_point.dart';
import 'package:mobile_scanner/src/objects/phone.dart';
import 'package:mobile_scanner/src/objects/sms.dart';
import 'package:mobile_scanner/src/objects/url_bookmark.dart';
import 'package:mobile_scanner/src/objects/wifi.dart';

void main() {
  group('Barcode', () {
    test('constructor creates with default values', () {
      const barcode = Barcode();
      expect(barcode.format, BarcodeFormat.unknown);
      expect(barcode.type, BarcodeType.unknown);
      expect(barcode.corners, isEmpty);
      expect(barcode.rawValue, isNull);
      expect(barcode.displayValue, isNull);
      expect(barcode.rawBytes, isNull);
      expect(barcode.size, Size.zero);
      expect(barcode.calendarEvent, isNull);
      expect(barcode.contactInfo, isNull);
      expect(barcode.email, isNull);
      expect(barcode.phone, isNull);
      expect(barcode.sms, isNull);
      expect(barcode.url, isNull);
      expect(barcode.wifi, isNull);
      expect(barcode.geoPoint, isNull);
      expect(barcode.driverLicense, isNull);
    });

    test('fromNative parses QR code data correctly', () {
      final nativeData = <Object?, Object?>{
        'format': 256, // qrCode
        'type': 7, // text
        'rawValue': 'https://example.com',
        'displayValue': 'https://example.com',
        'corners': <Object?>[
          <Object?, Object?>{'x': 0.0, 'y': 0.0},
          <Object?, Object?>{'x': 100.0, 'y': 0.0},
          <Object?, Object?>{'x': 100.0, 'y': 100.0},
          <Object?, Object?>{'x': 0.0, 'y': 100.0},
        ],
        'size': <Object?, Object?>{
          'width': 100.0,
          'height': 100.0,
        },
      };

      final barcode = Barcode.fromNative(nativeData);
      expect(barcode.format, BarcodeFormat.qrCode);
      expect(barcode.type, BarcodeType.text);
      expect(barcode.rawValue, 'https://example.com');
      expect(barcode.displayValue, 'https://example.com');
      expect(barcode.corners.length, 4);
      expect(barcode.size.width, 100.0);
      expect(barcode.size.height, 100.0);
    });

    test('fromNative parses code128 data correctly', () {
      final nativeData = <Object?, Object?>{
        'format': 1, // code128
        'type': 7, // text
        'rawValue': '1234567890',
        'displayValue': '1234567890',
      };

      final barcode = Barcode.fromNative(nativeData);
      expect(barcode.format, BarcodeFormat.code128);
      expect(barcode.type, BarcodeType.text);
      expect(barcode.rawValue, '1234567890');
    });

    test('fromNative parses EAN-13 data correctly', () {
      final nativeData = <Object?, Object?>{
        'format': 32, // ean13
        'type': 5, // product
        'rawValue': '5901234123457',
        'displayValue': '5901234123457',
      };

      final barcode = Barcode.fromNative(nativeData);
      expect(barcode.format, BarcodeFormat.ean13);
      expect(barcode.type, BarcodeType.product);
    });

    test('fromNative handles missing corners', () {
      final nativeData = <Object?, Object?>{
        'format': 256,
        'rawValue': 'test',
      };

      final barcode = Barcode.fromNative(nativeData);
      expect(barcode.corners, isEmpty);
    });

    test('fromNative handles null rawValue', () {
      final nativeData = <Object?, Object?>{
        'format': 256,
      };

      final barcode = Barcode.fromNative(nativeData);
      expect(barcode.rawValue, isNull);
      expect(barcode.format, BarcodeFormat.qrCode);
    });

    test('fromNative handles empty data', () {
      final nativeData = <Object?, Object?>{};

      final barcode = Barcode.fromNative(nativeData);
      expect(barcode.format, BarcodeFormat.unknown);
      expect(barcode.type, BarcodeType.unknown);
      expect(barcode.rawValue, isNull);
      expect(barcode.corners, isEmpty);
      expect(barcode.size, Size.zero);
    });

    test('fromNative parses rawBytes', () {
      final bytes = Uint8List.fromList([0x48, 0x65, 0x6C, 0x6C, 0x6F]);
      final nativeData = <Object?, Object?>{
        'format': 256,
        'rawValue': 'Hello',
        'rawBytes': bytes,
      };

      final barcode = Barcode.fromNative(nativeData);
      expect(barcode.rawBytes, bytes);
      expect(barcode.rawBytes!.length, 5);
    });

    test('fromNative handles unknown format gracefully', () {
      final nativeData = <Object?, Object?>{
        'format': 99999, // unknown format value
        'rawValue': 'test',
      };

      // Invalid format values throw ArgumentError from BarcodeFormat.fromRawValue
      expect(
        () => Barcode.fromNative(nativeData),
        throwsArgumentError,
      );
    });

    test('fromNative handles size with only width', () {
      final nativeData = <Object?, Object?>{
        'format': 256,
        'rawValue': 'test',
        'size': <Object?, Object?>{
          'width': 100.0,
        },
      };

      final barcode = Barcode.fromNative(nativeData);
      expect(barcode.size, Size.zero); // height missing, so zero
    });

    test('fromNative handles invalid corners data', () {
      final nativeData = <Object?, Object?>{
        'format': 256,
        'rawValue': 'test',
        'corners': 'invalid', // not a list - will throw type error
      };

      // Type cast of String to List<Object?>? throws
      expect(
        () => Barcode.fromNative(nativeData),
        throwsA(isA<TypeError>()),
      );
    });

    test('fromNative handles corners as empty list', () {
      final nativeData = <Object?, Object?>{
        'format': 256,
        'rawValue': 'test',
        'corners': <Object?>[],
      };

      final barcode = Barcode.fromNative(nativeData);
      expect(barcode.corners, isEmpty);
    });

    group('fromNative embedded sub-objects', () {
      test('parses calendarEvent', () {
        final nativeData = <Object?, Object?>{
          'format': 256,
          'rawValue': 'test',
          'calendarEvent': <Object?, Object?>{
            'description': 'Meeting',
            'location': 'Room 1',
            'summary': 'Sync',
          },
        };

        final barcode = Barcode.fromNative(nativeData);
        expect(barcode.calendarEvent, isNotNull);
        expect(barcode.calendarEvent!.description, 'Meeting');
        expect(barcode.calendarEvent!.location, 'Room 1');
        expect(barcode.calendarEvent!.summary, 'Sync');
      });

      test('parses contactInfo with nested name and phones', () {
        final nativeData = <Object?, Object?>{
          'format': 256,
          'rawValue': 'test',
          'contactInfo': <Object?, Object?>{
            'name': <Object?, Object?>{
              'first': 'John',
              'last': 'Doe',
            },
            'organization': 'Acme',
            'phones': <Object?>[
              <Object?, Object?>{
                'number': '+1-555-1234',
                'type': 1, // mobile
              },
            ],
            'emails': <Object?>[
              <Object?, Object?>{
                'address': 'john@acme.com',
              },
            ],
          },
        };

        final barcode = Barcode.fromNative(nativeData);
        expect(barcode.contactInfo, isNotNull);
        expect(barcode.contactInfo!.name, isNotNull);
        expect(barcode.contactInfo!.name!.first, 'John');
        expect(barcode.contactInfo!.name!.last, 'Doe');
        expect(barcode.contactInfo!.organization, 'Acme');
        expect(barcode.contactInfo!.phones.length, 1);
        expect(barcode.contactInfo!.phones[0].number, '+1-555-1234');
        expect(barcode.contactInfo!.emails.length, 1);
        expect(barcode.contactInfo!.emails[0].address, 'john@acme.com');
      });

      test('parses driverLicense', () {
        final nativeData = <Object?, Object?>{
          'format': 256,
          'rawValue': 'test',
          'driverLicense': <Object?, Object?>{
            'firstName': 'Jane',
            'lastName': 'Smith',
            'licenseNumber': 'D123-4567',
            'issuingCountry': 'USA',
          },
        };

        final barcode = Barcode.fromNative(nativeData);
        expect(barcode.driverLicense, isNotNull);
        expect(barcode.driverLicense!.firstName, 'Jane');
        expect(barcode.driverLicense!.lastName, 'Smith');
        expect(barcode.driverLicense!.licenseNumber, 'D123-4567');
        expect(barcode.driverLicense!.issuingCountry, 'USA');
      });

      test('parses email', () {
        final nativeData = <Object?, Object?>{
          'format': 256,
          'rawValue': 'test',
          'email': <Object?, Object?>{
            'address': 'alice@example.com',
            'subject': 'Hello',
            'body': 'Hi there',
            'type': 1, // work
          },
        };

        final barcode = Barcode.fromNative(nativeData);
        expect(barcode.email, isNotNull);
        expect(barcode.email!.address, 'alice@example.com');
        expect(barcode.email!.subject, 'Hello');
        expect(barcode.email!.body, 'Hi there');
      });

      test('parses geoPoint', () {
        final nativeData = <Object?, Object?>{
          'format': 256,
          'rawValue': 'test',
          'geoPoint': <Object?, Object?>{
            'latitude': 37.7749,
            'longitude': -122.4194,
          },
        };

        final barcode = Barcode.fromNative(nativeData);
        expect(barcode.geoPoint, isNotNull);
        expect(barcode.geoPoint!.latitude, 37.7749);
        expect(barcode.geoPoint!.longitude, -122.4194);
      });

      test('parses phone', () {
        final nativeData = <Object?, Object?>{
          'format': 256,
          'rawValue': 'test',
          'phone': <Object?, Object?>{
            'number': '+1-555-5678',
            'type': 2, // work
          },
        };

        final barcode = Barcode.fromNative(nativeData);
        expect(barcode.phone, isNotNull);
        expect(barcode.phone!.number, '+1-555-5678');
      });

      test('parses sms', () {
        final nativeData = <Object?, Object?>{
          'format': 256,
          'rawValue': 'test',
          'sms': <Object?, Object?>{
            'message': 'Hello!',
            'phoneNumber': '+1-555-9012',
          },
        };

        final barcode = Barcode.fromNative(nativeData);
        expect(barcode.sms, isNotNull);
        expect(barcode.sms!.message, 'Hello!');
        expect(barcode.sms!.phoneNumber, '+1-555-9012');
      });

      test('parses url bookmark', () {
        final nativeData = <Object?, Object?>{
          'format': 256,
          'rawValue': 'test',
          'url': <Object?, Object?>{
            'title': 'Example',
            'url': 'https://example.com',
          },
        };

        final barcode = Barcode.fromNative(nativeData);
        expect(barcode.url, isNotNull);
        expect(barcode.url!.title, 'Example');
        expect(barcode.url!.url, 'https://example.com');
      });

      test('parses wifi', () {
        final nativeData = <Object?, Object?>{
          'format': 256,
          'rawValue': 'test',
          'wifi': <Object?, Object?>{
            'ssid': 'HomeNet',
            'password': 'pass123',
            'encryptionType': 2, // wpa
          },
        };

        final barcode = Barcode.fromNative(nativeData);
        expect(barcode.wifi, isNotNull);
        expect(barcode.wifi!.ssid, 'HomeNet');
        expect(barcode.wifi!.password, 'pass123');
        expect(barcode.wifi!.encryptionType, EncryptionType.wpa);
      });

      test('handles null sub-objects', () {
        final nativeData = <Object?, Object?>{
          'format': 256,
          'rawValue': 'test',
          'calendarEvent': null,
          'contactInfo': null,
          'driverLicense': null,
          'email': null,
          'geoPoint': null,
          'phone': null,
          'sms': null,
          'url': null,
          'wifi': null,
        };

        final barcode = Barcode.fromNative(nativeData);
        expect(barcode.calendarEvent, isNull);
        expect(barcode.contactInfo, isNull);
        expect(barcode.driverLicense, isNull);
        expect(barcode.email, isNull);
        expect(barcode.geoPoint, isNull);
        expect(barcode.phone, isNull);
        expect(barcode.sms, isNull);
        expect(barcode.url, isNull);
        expect(barcode.wifi, isNull);
      });
    });
  });
}