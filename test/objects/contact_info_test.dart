import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/enums/address_type.dart';
import 'package:mobile_scanner/src/enums/email_type.dart';
import 'package:mobile_scanner/src/enums/phone_type.dart';
import 'package:mobile_scanner/src/objects/address.dart';
import 'package:mobile_scanner/src/objects/contact_info.dart';
import 'package:mobile_scanner/src/objects/email.dart';
import 'package:mobile_scanner/src/objects/person_name.dart';
import 'package:mobile_scanner/src/objects/phone.dart';

void main() {
  group('ContactInfo', () {
    test('constructor creates with default values', () {
      const info = ContactInfo();
      expect(info.addresses, isEmpty);
      expect(info.emails, isEmpty);
      expect(info.name, isNull);
      expect(info.organization, isNull);
      expect(info.phones, isEmpty);
      expect(info.title, isNull);
      expect(info.urls, isEmpty);
    });

    test('constructor creates with custom values', () {
      const info = ContactInfo(
        organization: 'Acme Corp',
        title: 'Engineer',
        urls: ['https://acme.com'],
      );
      expect(info.organization, 'Acme Corp');
      expect(info.title, 'Engineer');
      expect(info.urls.length, 1);
      expect(info.urls[0], 'https://acme.com');
    });

    test('fromNative parses data with all fields', () {
      final data = <Object?, Object?>{
        'addresses': <Object?>[
          <Object?, Object?>{
            'addressLines': <Object?>['123 Main St'],
            'type': 2, // home
          },
        ],
        'emails': <Object?>[
          <Object?, Object?>{
            'address': 'john@example.com',
            'type': 1, // work
          },
        ],
        'name': <Object?, Object?>{
          'first': 'John',
          'last': 'Doe',
        },
        'organization': 'Acme Corp',
        'phones': <Object?>[
          <Object?, Object?>{
            'number': '+1-555-1234',
            'type': 4, // mobile
          },
        ],
        'title': 'Engineer',
        'urls': <Object?>['https://acme.com'],
      };

      final info = ContactInfo.fromNative(data);
      expect(info.addresses.length, 1);
      expect(info.addresses[0].addressLines[0], '123 Main St');
      expect(info.addresses[0].type, AddressType.home);

      expect(info.emails.length, 1);
      expect(info.emails[0].address, 'john@example.com');
      expect(info.emails[0].type, EmailType.work);

      expect(info.name, isNotNull);
      expect(info.name!.first, 'John');
      expect(info.name!.last, 'Doe');

      expect(info.organization, 'Acme Corp');

      expect(info.phones.length, 1);
      expect(info.phones[0].number, '+1-555-1234');
      expect(info.phones[0].type, PhoneType.mobile);

      expect(info.title, 'Engineer');
      expect(info.urls.length, 1);
      expect(info.urls[0], 'https://acme.com');
    });

    test('fromNative handles missing fields', () {
      final data = <Object?, Object?>{};

      final info = ContactInfo.fromNative(data);
      expect(info.addresses, isEmpty);
      expect(info.emails, isEmpty);
      expect(info.name, isNull);
      expect(info.organization, isNull);
      expect(info.phones, isEmpty);
      expect(info.title, isNull);
      expect(info.urls, isEmpty);
    });

    test('fromNative handles null name', () {
      final data = <Object?, Object?>{
        'name': null,
      };

      final info = ContactInfo.fromNative(data);
      expect(info.name, isNull);
    });

    test('fromNative handles null lists', () {
      final data = <Object?, Object?>{
        'addresses': null,
        'emails': null,
        'phones': null,
        'urls': null,
      };

      final info = ContactInfo.fromNative(data);
      expect(info.addresses, isEmpty);
      expect(info.emails, isEmpty);
      expect(info.phones, isEmpty);
      expect(info.urls, isEmpty);
    });
  });
}