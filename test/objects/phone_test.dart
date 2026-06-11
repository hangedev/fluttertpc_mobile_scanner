import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/enums/phone_type.dart';
import 'package:mobile_scanner/src/objects/phone.dart';

void main() {
  group('Phone', () {
    test('constructor creates with default values', () {
      const phone = Phone();
      expect(phone.number, isNull);
      expect(phone.type, PhoneType.unknown);
    });

    test('constructor creates with custom values', () {
      const phone = Phone(
        number: '+1-555-1234',
        type: PhoneType.mobile,
      );
      expect(phone.number, '+1-555-1234');
      expect(phone.type, PhoneType.mobile);
    });

    test('fromNative parses data correctly', () {
      final data = <Object?, Object?>{
        'number': '+1-555-5678',
        'type': 4, // mobile
      };

      final phone = Phone.fromNative(data);
      expect(phone.number, '+1-555-5678');
      expect(phone.type, PhoneType.mobile);
    });

    test('fromNative handles missing number', () {
      final data = <Object?, Object?>{
        'type': 4, // mobile
      };

      final phone = Phone.fromNative(data);
      expect(phone.number, isNull);
      expect(phone.type, PhoneType.mobile);
    });

    test('fromNative handles missing type', () {
      final data = <Object?, Object?>{
        'number': '+1-555-9999',
      };

      final phone = Phone.fromNative(data);
      expect(phone.number, '+1-555-9999');
      expect(phone.type, PhoneType.unknown);
    });

    test('fromNative handles empty data', () {
      final data = <Object?, Object?>{};

      final phone = Phone.fromNative(data);
      expect(phone.number, isNull);
      expect(phone.type, PhoneType.unknown);
    });

    test('fromNative handles null type', () {
      final data = <Object?, Object?>{
        'number': '+1-555-0000',
        'type': null,
      };

      final phone = Phone.fromNative(data);
      expect(phone.number, '+1-555-0000');
      expect(phone.type, PhoneType.unknown);
    });
  });
}