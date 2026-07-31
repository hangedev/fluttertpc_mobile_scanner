import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/enums/address_type.dart';
import 'package:mobile_scanner/src/objects/address.dart';

void main() {
  group('Address', () {
    group('constructor', () {
      test('should create Address with default parameters', () {
        const address = Address();
        expect(address.addressLines, isEmpty);
        expect(address.type, AddressType.unknown);
      });

      test('should create Address with custom parameters', () {
        const address = Address(
          addressLines: ['123 Main St', 'Suite 100'],
          type: AddressType.work,
        );
        expect(address.addressLines, ['123 Main St', 'Suite 100']);
        expect(address.type, AddressType.work);
      });
    });

    group('fromNative', () {
      test('should create Address with null address lines', () {
        final data = <Object?, Object?>{
          'addressLines': null,
          'type': 0,
        };
        final address = Address.fromNative(data);
        expect(address.addressLines, isEmpty);
        expect(address.type, AddressType.unknown);
      });

      test('should create Address with address lines', () {
        final data = <Object?, Object?>{
          'addressLines': <Object?>['123 Main St', 'Suite 100'],
          'type': 1,
        };
        final address = Address.fromNative(data);
        expect(address.addressLines, ['123 Main St', 'Suite 100']);
        expect(address.type, AddressType.work);
      });

      test('should create Address with default type', () {
        final data = <Object?, Object?>{
          'addressLines': null,
          'type': null,
        };
        final address = Address.fromNative(data);
        expect(address.addressLines, isEmpty);
        expect(address.type, AddressType.unknown);
      });
    });
  });
}
