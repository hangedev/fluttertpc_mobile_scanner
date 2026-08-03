import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/enums/address_type.dart';
import 'package:mobile_scanner/src/objects/address.dart';

void main() {
  group('Address', () {
    test('constructor creates with default values', () {
      const address = Address();
      expect(address.addressLines, isEmpty);
      expect(address.type, AddressType.unknown);
    });

    test('constructor creates with custom values', () {
      const address = Address(
        addressLines: ['123 Main St', 'Apt 4B'],
        type: AddressType.work,
      );
      expect(address.addressLines.length, 2);
      expect(address.addressLines[0], '123 Main St');
      expect(address.addressLines[1], 'Apt 4B');
      expect(address.type, AddressType.work);
    });

    test('fromNative parses data correctly', () {
      final data = <Object?, Object?>{
        'addressLines': <Object?>['456 Oak Ave', 'Suite 100'],
        'type': 1, // work
      };

      final address = Address.fromNative(data);
      expect(address.addressLines.length, 2);
      expect(address.addressLines[0], '456 Oak Ave');
      expect(address.addressLines[1], 'Suite 100');
      expect(address.type, AddressType.work);
    });

    test('fromNative handles missing addressLines', () {
      final data = <Object?, Object?>{
        'type': 2, // home
      };

      final address = Address.fromNative(data);
      expect(address.addressLines, isEmpty);
      expect(address.type, AddressType.home);
    });

    test('fromNative handles null addressLines', () {
      final data = <Object?, Object?>{
        'addressLines': null,
        'type': 2,
      };

      final address = Address.fromNative(data);
      expect(address.addressLines, isEmpty);
    });

    test('fromNative handles missing type', () {
      final data = <Object?, Object?>{
        'addressLines': <Object?>['789 Pine St'],
      };

      final address = Address.fromNative(data);
      expect(address.addressLines.length, 1);
      expect(address.type, AddressType.unknown);
    });

    test('fromNative handles empty data', () {
      final data = <Object?, Object?>{};

      final address = Address.fromNative(data);
      expect(address.addressLines, isEmpty);
      expect(address.type, AddressType.unknown);
    });
  });
}