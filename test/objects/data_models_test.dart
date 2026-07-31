import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/enums/email_type.dart';
import 'package:mobile_scanner/src/enums/encryption_type.dart';
import 'package:mobile_scanner/src/enums/phone_type.dart';
import 'package:mobile_scanner/src/objects/calendar_event.dart';
import 'package:mobile_scanner/src/objects/contact_info.dart';
import 'package:mobile_scanner/src/objects/driver_license.dart';
import 'package:mobile_scanner/src/objects/email.dart';
import 'package:mobile_scanner/src/objects/geo_point.dart';
import 'package:mobile_scanner/src/objects/person_name.dart';
import 'package:mobile_scanner/src/objects/phone.dart';
import 'package:mobile_scanner/src/objects/sms.dart';
import 'package:mobile_scanner/src/objects/url_bookmark.dart';
import 'package:mobile_scanner/src/objects/wifi.dart';

void main() {
  group('GeoPoint', () {
    group('constructor', () {
      test('should create GeoPoint with required parameters', () {
        const point = GeoPoint(latitude: 37.7749, longitude: -122.4194);
        expect(point.latitude, 37.7749);
        expect(point.longitude, -122.4194);
      });
    });

    group('fromNative', () {
      test('should create GeoPoint with valid data', () {
        final data = <Object?, Object?>{
          'latitude': 37.7749,
          'longitude': -122.4194,
        };
        final point = GeoPoint.fromNative(data);
        expect(point.latitude, 37.7749);
        expect(point.longitude, -122.4194);
      });

      test('should create GeoPoint with null values', () {
        final data = <Object?, Object?>{
          'latitude': null,
          'longitude': null,
        };
        final point = GeoPoint.fromNative(data);
        expect(point.latitude, 0.0);
        expect(point.longitude, 0.0);
      });
    });
  });

  group('Email', () {
    group('constructor', () {
      test('should create Email with default parameters', () {
        const email = Email();
        expect(email.address, isNull);
        expect(email.body, isNull);
        expect(email.subject, isNull);
        expect(email.type, EmailType.unknown);
      });

      test('should create Email with custom parameters', () {
        const email = Email(
          address: 'test@example.com',
          body: 'Hello',
          subject: 'Test',
          type: EmailType.work,
        );
        expect(email.address, 'test@example.com');
        expect(email.body, 'Hello');
        expect(email.subject, 'Test');
        expect(email.type, EmailType.work);
      });
    });

    group('fromNative', () {
      test('should create Email with valid data', () {
        final data = <Object?, Object?>{
          'address': 'test@example.com',
          'body': 'Hello',
          'subject': 'Test',
          'type': 1,
        };
        final email = Email.fromNative(data);
        expect(email.address, 'test@example.com');
        expect(email.body, 'Hello');
        expect(email.subject, 'Test');
        expect(email.type, EmailType.work);
      });

      test('should create Email with null values', () {
        final data = <Object?, Object?>{
          'address': null,
          'body': null,
          'subject': null,
          'type': 0,
        };
        final email = Email.fromNative(data);
        expect(email.address, isNull);
        expect(email.body, isNull);
        expect(email.subject, isNull);
        expect(email.type, EmailType.unknown);
      });
    });
  });

  group('Phone', () {
    group('constructor', () {
      test('should create Phone with default parameters', () {
        const phone = Phone();
        expect(phone.number, isNull);
        expect(phone.type, PhoneType.unknown);
      });

      test('should create Phone with custom parameters', () {
        const phone = Phone(number: '+1234567890', type: PhoneType.work);
        expect(phone.number, '+1234567890');
        expect(phone.type, PhoneType.work);
      });
    });

    group('fromNative', () {
      test('should create Phone with valid data', () {
        final data = <Object?, Object?>{
          'number': '+1234567890',
          'type': 1,
        };
        final phone = Phone.fromNative(data);
        expect(phone.number, '+1234567890');
        expect(phone.type, PhoneType.work);
      });

      test('should create Phone with null values', () {
        final data = <Object?, Object?>{
          'number': null,
          'type': 0,
        };
        final phone = Phone.fromNative(data);
        expect(phone.number, isNull);
        expect(phone.type, PhoneType.unknown);
      });
    });
  });

  group('SMS', () {
    group('constructor', () {
      test('should create SMS with required parameters', () {
        const sms = SMS(phoneNumber: '+1234567890');
        expect(sms.message, isNull);
        expect(sms.phoneNumber, '+1234567890');
      });

      test('should create SMS with all parameters', () {
        const sms = SMS(message: 'Hello', phoneNumber: '+1234567890');
        expect(sms.message, 'Hello');
        expect(sms.phoneNumber, '+1234567890');
      });
    });

    group('fromNative', () {
      test('should create SMS with valid data', () {
        final data = <Object?, Object?>{
          'message': 'Hello',
          'phoneNumber': '+1234567890',
        };
        final sms = SMS.fromNative(data);
        expect(sms.message, 'Hello');
        expect(sms.phoneNumber, '+1234567890');
      });
    });
  });

  group('UrlBookmark', () {
    group('constructor', () {
      test('should create UrlBookmark with required parameters', () {
        const bookmark = UrlBookmark(url: 'https://example.com');
        expect(bookmark.title, isNull);
        expect(bookmark.url, 'https://example.com');
      });

      test('should create UrlBookmark with all parameters', () {
        const bookmark = UrlBookmark(title: 'Example', url: 'https://example.com');
        expect(bookmark.title, 'Example');
        expect(bookmark.url, 'https://example.com');
      });
    });

    group('fromNative', () {
      test('should create UrlBookmark with valid data', () {
        final data = <Object?, Object?>{
          'title': 'Example',
          'url': 'https://example.com',
        };
        final bookmark = UrlBookmark.fromNative(data);
        expect(bookmark.title, 'Example');
        expect(bookmark.url, 'https://example.com');
      });
    });
  });

  group('WiFi', () {
    group('constructor', () {
      test('should create WiFi with default parameters', () {
        const wifi = WiFi();
        expect(wifi.ssid, isNull);
        expect(wifi.password, isNull);
        expect(wifi.encryptionType, EncryptionType.unknown);
      });

      test('should create WiFi with custom parameters', () {
        const wifi = WiFi(
          encryptionType: EncryptionType.wep,
          password: 'password123',
          ssid: 'MyWiFi',
        );
        expect(wifi.ssid, 'MyWiFi');
        expect(wifi.password, 'password123');
        expect(wifi.encryptionType, EncryptionType.wep);
      });
    });

    group('fromNative', () {
      test('should create WiFi with valid data', () {
        final data = <Object?, Object?>{
          'encryptionType': 3,
          'password': 'password123',
          'ssid': 'MyWiFi',
        };
        final wifi = WiFi.fromNative(data);
        expect(wifi.ssid, 'MyWiFi');
        expect(wifi.password, 'password123');
        expect(wifi.encryptionType, EncryptionType.wep);
      });

      test('should create WiFi with null values', () {
        final data = <Object?, Object?>{
          'encryptionType': 0,
          'password': null,
          'ssid': null,
        };
        final wifi = WiFi.fromNative(data);
        expect(wifi.ssid, isNull);
        expect(wifi.password, isNull);
        expect(wifi.encryptionType, EncryptionType.unknown);
      });
    });
  });

  group('PersonName', () {
    group('constructor', () {
      test('should create PersonName with default parameters', () {
        const name = PersonName();
        expect(name.first, isNull);
        expect(name.middle, isNull);
        expect(name.last, isNull);
        expect(name.prefix, isNull);
        expect(name.suffix, isNull);
        expect(name.formattedName, isNull);
        expect(name.pronunciation, isNull);
      });

      test('should create PersonName with all parameters', () {
        const name = PersonName(
          first: 'John',
          formattedName: 'John Doe',
          last: 'Doe',
          middle: 'M',
          prefix: 'Dr.',
          pronunciation: 'john-doe',
          suffix: 'Jr.',
        );
        expect(name.first, 'John');
        expect(name.formattedName, 'John Doe');
        expect(name.last, 'Doe');
        expect(name.middle, 'M');
        expect(name.prefix, 'Dr.');
        expect(name.pronunciation, 'john-doe');
        expect(name.suffix, 'Jr.');
      });
    });

    group('fromNative', () {
      test('should create PersonName with valid data', () {
        final data = <Object?, Object?>{
          'first': 'John',
          'formattedName': 'John Doe',
          'last': 'Doe',
          'middle': 'M',
          'prefix': 'Dr.',
          'pronunciation': 'john-doe',
          'suffix': 'Jr.',
        };
        final name = PersonName.fromNative(data);
        expect(name.first, 'John');
        expect(name.formattedName, 'John Doe');
        expect(name.last, 'Doe');
        expect(name.middle, 'M');
        expect(name.prefix, 'Dr.');
        expect(name.pronunciation, 'john-doe');
        expect(name.suffix, 'Jr.');
      });
    });
  });

  group('ContactInfo', () {
    group('constructor', () {
      test('should create ContactInfo with default parameters', () {
        const contact = ContactInfo();
        expect(contact.addresses, isEmpty);
        expect(contact.emails, isEmpty);
        expect(contact.name, isNull);
        expect(contact.organization, isNull);
        expect(contact.phones, isEmpty);
        expect(contact.title, isNull);
        expect(contact.urls, isEmpty);
      });
    });

    group('fromNative', () {
      test('should create ContactInfo with all fields', () {
        final data = <Object?, Object?>{
          'addresses': <Object?>[
            <Object?, Object?>{'addressLines': null, 'type': 1},
          ],
          'emails': <Object?>[
            <Object?, Object?>{'address': 'test@example.com', 'body': null, 'subject': null, 'type': 1},
          ],
          'name': <Object?, Object?>{
            'first': 'John', 'formattedName': 'John Doe', 'last': 'Doe',
          },
          'organization': 'ACME Corp',
          'phones': <Object?>[
            <Object?, Object?>{'number': '+1234567890', 'type': 2},
          ],
          'title': 'Engineer',
          'urls': <Object?>[
            'https://blog.example.com',
          ],
        };
        final contact = ContactInfo.fromNative(data);
        expect(contact.organization, 'ACME Corp');
        expect(contact.title, 'Engineer');
        expect(contact.addresses, isNotNull);
        expect(contact.addresses.length, 1);
        expect(contact.emails, isNotNull);
        expect(contact.emails.length, 1);
        expect(contact.name, isNotNull);
        expect(contact.name!.first, 'John');
        expect(contact.phones, isNotNull);
        expect(contact.phones.length, 1);
        expect(contact.urls, isNotNull);
        expect(contact.urls.length, 1);
      });
    });
  });

  group('CalendarEvent', () {
    group('constructor', () {
      test('should create CalendarEvent with default parameters', () {
        const event = CalendarEvent();
        expect(event.description, isNull);
        expect(event.start, isNull);
        expect(event.end, isNull);
        expect(event.location, isNull);
        expect(event.organizer, isNull);
        expect(event.status, isNull);
        expect(event.summary, isNull);
      });
    });

    group('fromNative', () {
      test('should create CalendarEvent with valid data', () {
        final data = <Object?, Object?>{
          'description': 'Team meeting',
          'end': '2024-01-01T10:00:00Z',
          'location': 'Room 101',
          'organizer': 'boss@example.com',
          'start': '2024-01-01T09:00:00Z',
          'status': 'confirmed',
          'summary': 'Meeting',
        };
        final event = CalendarEvent.fromNative(data);
        expect(event.description, 'Team meeting');
        expect(event.location, 'Room 101');
        expect(event.summary, 'Meeting');
        expect(event.start, isNotNull);
        expect(event.organizer, 'boss@example.com');
        expect(event.end, isNotNull);
        expect(event.status, 'confirmed');
      });
    });
  });

  group('DriverLicense', () {
    group('constructor', () {
      test('should create DriverLicense with default parameters', () {
        const license = DriverLicense();
        expect(license.firstName, isNull);
        expect(license.lastName, isNull);
        expect(license.licenseNumber, isNull);
        expect(license.addressCity, isNull);
        expect(license.addressState, isNull);
        expect(license.addressStreet, isNull);
        expect(license.addressZip, isNull);
        expect(license.birthDate, isNull);
        expect(license.documentType, isNull);
        expect(license.expiryDate, isNull);
        expect(license.gender, isNull);
        expect(license.issueDate, isNull);
        expect(license.issuingCountry, isNull);
        expect(license.middleName, isNull);
      });
    });

    group('fromNative', () {
      test('should create DriverLicense with all fields', () {
        final data = <Object?, Object?>{
          'addressStreet': '123 Main St',
          'addressCity': 'Anytown',
          'addressState': 'CA',
          'addressZip': '12345',
          'birthDate': '01/01/1990',
          'documentType': 'US',
          'expiryDate': '01/01/2030',
          'firstName': 'John',
          'fullName': 'John Doe',
          'gender': 'M',
          'issueDate': '01/01/2020',
          'issuingCountry': 'US',
          'lastName': 'Doe',
          'licenseNumber': 'D1234567',
          'middleName': 'M',
        };
        final license = DriverLicense.fromNative(data);
        expect(license.firstName, 'John');
        expect(license.lastName, 'Doe');
        expect(license.licenseNumber, 'D1234567');
        expect(license.issuingCountry, 'US');
        expect(license.addressStreet, '123 Main St');
        expect(license.addressCity, 'Anytown');
        expect(license.addressState, 'CA');
        expect(license.addressZip, '12345');
        expect(license.birthDate, '01/01/1990');
        expect(license.documentType, 'US');
        expect(license.expiryDate, '01/01/2030');
        expect(license.gender, 'M');
        expect(license.issueDate, '01/01/2020');
        expect(license.middleName, 'M');
      });
    });
  });
}
