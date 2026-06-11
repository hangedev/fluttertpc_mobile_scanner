import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/objects/driver_license.dart';

void main() {
  group('DriverLicense', () {
    test('constructor creates with default values', () {
      const license = DriverLicense();
      expect(license.addressCity, isNull);
      expect(license.addressState, isNull);
      expect(license.addressStreet, isNull);
      expect(license.addressZip, isNull);
      expect(license.birthDate, isNull);
      expect(license.documentType, isNull);
      expect(license.expiryDate, isNull);
      expect(license.firstName, isNull);
      expect(license.gender, isNull);
      expect(license.issueDate, isNull);
      expect(license.issuingCountry, isNull);
      expect(license.lastName, isNull);
      expect(license.licenseNumber, isNull);
      expect(license.middleName, isNull);
    });

    test('constructor creates with custom values', () {
      const license = DriverLicense(
        firstName: 'John',
        lastName: 'Doe',
        licenseNumber: 'D123-4567-8901',
        issuingCountry: 'USA',
      );
      expect(license.firstName, 'John');
      expect(license.lastName, 'Doe');
      expect(license.licenseNumber, 'D123-4567-8901');
      expect(license.issuingCountry, 'USA');
    });

    test('fromNative parses all fields correctly', () {
      final data = <Object?, Object?>{
        'addressCity': 'Portland',
        'addressState': 'OR',
        'addressStreet': '456 Oak Ave',
        'addressZip': '97201',
        'birthDate': '01/15/1990',
        'documentType': 'DL',
        'expiryDate': '01/15/2028',
        'firstName': 'Jane',
        'gender': '2',
        'issueDate': '01/15/2020',
        'issuingCountry': 'USA',
        'lastName': 'Smith',
        'licenseNumber': 'S987-6543-2101',
        'middleName': 'Anne',
      };

      final license = DriverLicense.fromNative(data);
      expect(license.addressCity, 'Portland');
      expect(license.addressState, 'OR');
      expect(license.addressStreet, '456 Oak Ave');
      expect(license.addressZip, '97201');
      expect(license.birthDate, '01/15/1990');
      expect(license.documentType, 'DL');
      expect(license.expiryDate, '01/15/2028');
      expect(license.firstName, 'Jane');
      expect(license.gender, '2');
      expect(license.issueDate, '01/15/2020');
      expect(license.issuingCountry, 'USA');
      expect(license.lastName, 'Smith');
      expect(license.licenseNumber, 'S987-6543-2101');
      expect(license.middleName, 'Anne');
    });

    test('fromNative handles ID card document type', () {
      final data = <Object?, Object?>{
        'documentType': 'ID',
        'firstName': 'Bob',
        'lastName': 'Johnson',
      };

      final license = DriverLicense.fromNative(data);
      expect(license.documentType, 'ID');
      expect(license.firstName, 'Bob');
      expect(license.lastName, 'Johnson');
    });

    test('fromNative handles missing fields', () {
      final data = <Object?, Object?>{};

      final license = DriverLicense.fromNative(data);
      expect(license.addressCity, isNull);
      expect(license.addressState, isNull);
      expect(license.addressStreet, isNull);
      expect(license.addressZip, isNull);
      expect(license.birthDate, isNull);
      expect(license.documentType, isNull);
      expect(license.expiryDate, isNull);
      expect(license.firstName, isNull);
      expect(license.gender, isNull);
      expect(license.issueDate, isNull);
      expect(license.issuingCountry, isNull);
      expect(license.lastName, isNull);
      expect(license.licenseNumber, isNull);
      expect(license.middleName, isNull);
    });

    test('fromNative handles partial fields', () {
      final data = <Object?, Object?>{
        'firstName': 'Alice',
        'lastName': 'Wang',
        'licenseNumber': 'A123-4567',
      };

      final license = DriverLicense.fromNative(data);
      expect(license.firstName, 'Alice');
      expect(license.lastName, 'Wang');
      expect(license.licenseNumber, 'A123-4567');
      expect(license.addressCity, isNull);
      expect(license.birthDate, isNull);
    });
  });
}