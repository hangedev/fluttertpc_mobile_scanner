import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/objects/sms.dart';

void main() {
  group('SMS', () {
    test('constructor creates with phone number', () {
      const sms = SMS(phoneNumber: '+1-555-1234');
      expect(sms.phoneNumber, '+1-555-1234');
      expect(sms.message, isNull);
    });

    test('constructor creates with message', () {
      const sms = SMS(
        message: 'Hello!',
        phoneNumber: '+1-555-5678',
      );
      expect(sms.phoneNumber, '+1-555-5678');
      expect(sms.message, 'Hello!');
    });

    test('fromNative parses data correctly', () {
      final data = <Object?, Object?>{
        'message': 'Meeting at 3pm',
        'phoneNumber': '+1-555-9012',
      };

      final sms = SMS.fromNative(data);
      expect(sms.message, 'Meeting at 3pm');
      expect(sms.phoneNumber, '+1-555-9012');
    });

    test('fromNative handles missing phoneNumber', () {
      final data = <Object?, Object?>{
        'message': 'Hello',
      };

      final sms = SMS.fromNative(data);
      expect(sms.message, 'Hello');
      expect(sms.phoneNumber, '');
    });

    test('fromNative handles null phoneNumber', () {
      final data = <Object?, Object?>{
        'message': 'Test',
        'phoneNumber': null,
      };

      final sms = SMS.fromNative(data);
      expect(sms.message, 'Test');
      expect(sms.phoneNumber, '');
    });

    test('fromNative handles missing message', () {
      final data = <Object?, Object?>{
        'phoneNumber': '+1-555-3456',
      };

      final sms = SMS.fromNative(data);
      expect(sms.message, isNull);
      expect(sms.phoneNumber, '+1-555-3456');
    });

    test('fromNative handles empty data', () {
      final data = <Object?, Object?>{};

      final sms = SMS.fromNative(data);
      expect(sms.message, isNull);
      expect(sms.phoneNumber, '');
    });
  });
}