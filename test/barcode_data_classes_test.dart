import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mobile_scanner/src/objects/barcode.dart';

void main() {
  group('Barcode', () {
    test('constructor sets all properties correctly', () {
      final barcode = Barcode(
        rawValue: 'test-value',
        format: BarcodeFormat.qrCode,
        type: BarcodeType.text,
        corners: const [
          Offset(0, 0),
          Offset(10, 0),
          Offset(10, 10),
          Offset(0, 10),
        ],
        size: const Size(10, 10),
      );

      expect(barcode.rawValue, 'test-value');
      expect(barcode.format, BarcodeFormat.qrCode);
      expect(barcode.type, BarcodeType.text);
      expect(barcode.corners.length, 4);
      expect(barcode.size, const Size(10, 10));
    });

    test('scaleCorners returns correctly scaled corners', () {
      final barcode = Barcode(
        rawValue: 'test',
        format: BarcodeFormat.code128,
        corners: const [
          Offset(0.25, 0.25),
          Offset(0.75, 0.25),
          Offset(0.75, 0.75),
          Offset(0.25, 0.75),
        ],
        size: const Size(1, 1),
      );

      final scaled = barcode.scaleCorners(const Size(200, 400));
      expect(scaled[0], const Offset(50, 100));
      expect(scaled[1], const Offset(150, 100));
      expect(scaled[2], const Offset(150, 300));
      expect(scaled[3], const Offset(50, 300));
    });

    test('scaleCorners handles zero size', () {
      final barcode = Barcode(
        rawValue: 'test',
        format: BarcodeFormat.aztec,
        corners: const [Offset(0.1, 0.1), Offset(0.9, 0.9)],
        size: Size.zero,
      );

      final scaled = barcode.scaleCorners(const Size(100, 100));
      expect(scaled[0], Offset.zero);
      expect(scaled[1], Offset.zero);
    });
  });

  group('BarcodeCapture', () {
    test('constructor sets barcodes correctly', () {
      const capture = BarcodeCapture(barcodes: []);
      expect(capture.barcodes, isEmpty);
    });

    test('equality works correctly', () {
      const capture1 = BarcodeCapture(barcodes: []);
      const capture2 = BarcodeCapture(barcodes: []);
      expect(capture1, equals(capture2));
    });
  });

  group('MobileScannerException', () {
    test('constructor sets properties correctly', () {
      const exception = MobileScannerException(
        errorCode: MobileScannerErrorCode.permissionDenied,
        errorDetails: MobileScannerErrorDetails(
          code: 'denied',
          message: 'Camera permission denied',
        ),
      );

      expect(exception.errorCode, MobileScannerErrorCode.permissionDenied);
      expect(exception.errorDetails!.code, 'denied');
      expect(exception.errorDetails!.message, 'Camera permission denied');
    });

    test('toString returns formatted string', () {
      const exception = MobileScannerException(
        errorCode: MobileScannerErrorCode.genericError,
      );
      expect(exception.toString(), contains('genericError'));
    });
  });

  group('MobileScannerErrorDetails', () {
    setUp(() {
      // No setup needed for data class tests
    });

    tearDown(() {
      // No teardown needed for data class tests
    });

    test('constructor sets properties correctly', () {
      const details = MobileScannerErrorDetails(
        code: 'TEST_ERROR',
        message: 'Test error message',
      );

      expect(details.code, 'TEST_ERROR');
      expect(details.message, 'Test error message');
      expect(details.details, isNull);
    });

    test('details property can be set', () {
      const details = MobileScannerErrorDetails(
        code: 'TEST_ERROR',
        message: 'Test error message',
        details: 'Additional error details',
      );

      expect(details.details, 'Additional error details');
    });

    test('details property is null by default', () {
      const details = MobileScannerErrorDetails(
        code: 'TEST_ERROR',
        message: 'Test error message',
      );

      expect(details.details, isNull);
    });
  });

  group('MobileScannerBarcodeException', () {
    test('constructor sets properties correctly', () {
      const exception = MobileScannerBarcodeException('Scan failed');
      expect(exception.message, 'Scan failed');
    });

    test('toString returns formatted string', () {
      const exception = MobileScannerBarcodeException('Scan failed');
      expect(exception.toString(), contains('Scan failed'));
    });

    test('toString returns default message when null', () {
      const exception = MobileScannerBarcodeException(null);
      expect(exception.toString(), contains('Could not detect'));
    });
  });

  group('MobileScannerState', () {
    test('uninitialized creates default state', () {
      final state = MobileScannerState.uninitialized();
      expect(state.availableCameras, isNull);
      expect(state.isInitialized, false);
      expect(state.isRunning, false);
      expect(state.isStarting, false);
      expect(state.error, isNull);
    });

    test('copyWith updates specified properties', () {
      final state = MobileScannerState.uninitialized();
      final updated = state.copyWith(
        availableCameras: 2,
        cameraDirection: CameraFacing.back,
        isInitialized: true,
        isRunning: true,
        isStarting: false,
        size: const Size(1920, 1080),
        torchState: TorchState.on,
        zoomScale: 0.5,
        deviceOrientation: DeviceOrientation.portraitUp,
      );

      expect(updated.availableCameras, 2);
      expect(updated.cameraDirection, CameraFacing.back);
      expect(updated.isInitialized, true);
      expect(updated.isRunning, true);
      expect(updated.size, const Size(1920, 1080));
      expect(updated.torchState, TorchState.on);
    });

    test('hasCameraPermission returns true when initialized', () {
      final state = MobileScannerState.uninitialized().copyWith(
        isInitialized: true,
        error: null,
      );
      expect(state.hasCameraPermission, true);
    });

    test('hasCameraPermission returns false when permission denied', () {
      final state = MobileScannerState.uninitialized().copyWith(
        isInitialized: true,
        error: const MobileScannerException(
          errorCode: MobileScannerErrorCode.permissionDenied,
        ),
      );
      expect(state.hasCameraPermission, false);
    });
  });

  // Barcode content data classes
  group('Address', () {
    setUp(() {
      // No setup needed for data class tests
    });

    tearDown(() {
      // No teardown needed for data class tests
    });

    test('constructor sets properties correctly', () {
      const address = Address(
        addressLines: ['123 Main St', 'Suite 100'],
        type: AddressType.work,
      );

      expect(address.type, AddressType.work);
      expect(address.addressLines, ['123 Main St', 'Suite 100']);
    });

    test('fromNative creates Address from map', () {
      final address = Address.fromNative({
        'addressLines': ['123 Main St', 'Suite 100'],
        'type': 1, // work
      });

      expect(address.addressLines, ['123 Main St', 'Suite 100']);
      expect(address.type, AddressType.work);
    });

    test('fromNative handles null addressLines', () {
      final address = Address.fromNative({
        'type': 0,
      });

      expect(address.addressLines, isEmpty);
      expect(address.type, AddressType.unknown);
    });

    test('fromNative handles null type', () {
      final address = Address.fromNative({
        'addressLines': ['123 Main St'],
      });

      expect(address.addressLines, ['123 Main St']);
      expect(address.type, AddressType.unknown);
    });
  });

  group('CalendarEvent', () {
    setUp(() {
      // No setup needed for data class tests
    });

    tearDown(() {
      // No teardown needed for data class tests
    });

    test('constructor sets properties correctly', () {
      final event = CalendarEvent(
        description: 'Meeting',
        location: 'Room 1',
        organizer: 'Alice',
        status: 'confirmed',
        summary: 'Team meeting',
      );

      expect(event.description, 'Meeting');
      expect(event.location, 'Room 1');
      expect(event.organizer, 'Alice');
      expect(event.status, 'confirmed');
      expect(event.summary, 'Team meeting');
    });

    test('fromNative creates CalendarEvent from map', () {
      final event = CalendarEvent.fromNative({
        'description': 'Team Meeting',
        'start': '2024-01-01T09:00:00',
        'end': '2024-01-01T10:00:00',
        'location': 'Room 101',
        'organizer': 'Bob',
        'status': 'confirmed',
        'summary': 'Sprint Planning',
      });

      expect(event.description, 'Team Meeting');
      expect(event.start, DateTime(2024, 1, 1, 9, 0, 0));
      expect(event.end, DateTime(2024, 1, 1, 10, 0, 0));
      expect(event.location, 'Room 101');
      expect(event.organizer, 'Bob');
      expect(event.status, 'confirmed');
      expect(event.summary, 'Sprint Planning');
    });

    test('fromNative handles null values', () {
      final event = CalendarEvent.fromNative({});

      expect(event.description, isNull);
      expect(event.start, isNull);
      expect(event.end, isNull);
      expect(event.location, isNull);
      expect(event.organizer, isNull);
      expect(event.status, isNull);
      expect(event.summary, isNull);
    });

    test('fromNative handles invalid date strings', () {
      final event = CalendarEvent.fromNative({
        'start': 'invalid-date',
        'end': 'not-a-date',
      });

      expect(event.start, isNull);
      expect(event.end, isNull);
    });
  });

  group('ContactInfo', () {
    setUp(() {
      // No setup needed for data class tests
    });

    tearDown(() {
      // No teardown needed for data class tests
    });

    test('constructor sets properties correctly', () {
      final contact = ContactInfo(
        name: PersonName(formattedName: 'John Doe'),
        phones: [Phone(number: '123-456-7890', type: PhoneType.mobile)],
        emails: [Email(address: 'john@example.com', type: EmailType.work)],
      );

      expect(contact.name?.formattedName, 'John Doe');
      expect(contact.phones.length, 1);
      expect(contact.emails.length, 1);
    });

    test('fromNative creates ContactInfo from map', () {
      final contact = ContactInfo.fromNative({
        'addresses': [
          {'addressLines': ['123 Main St'], 'type': 1},
        ],
        'emails': [
          {'address': 'john@example.com', 'body': 'Hello', 'subject': 'Hi', 'type': 2},
        ],
        'name': {
          'first': 'John',
          'last': 'Doe',
          'formattedName': 'John Doe',
        },
        'organization': 'Acme Inc',
        'phones': [
          {'number': '555-0100', 'type': 1},
        ],
        'title': 'Engineer',
        'urls': ['https://example.com'],
      });

      expect(contact.addresses.length, 1);
      expect(contact.addresses.first.addressLines, ['123 Main St']);
      expect(contact.emails.length, 1);
      expect(contact.emails.first.address, 'john@example.com');
      expect(contact.name?.first, 'John');
      expect(contact.organization, 'Acme Inc');
      expect(contact.phones.length, 1);
      expect(contact.phones.first.number, '555-0100');
      expect(contact.title, 'Engineer');
      expect(contact.urls, ['https://example.com']);
    });

    test('fromNative handles null values', () {
      final contact = ContactInfo.fromNative({});

      expect(contact.addresses, isEmpty);
      expect(contact.emails, isEmpty);
      expect(contact.name, isNull);
      expect(contact.organization, isNull);
      expect(contact.phones, isEmpty);
      expect(contact.title, isNull);
      expect(contact.urls, isEmpty);
    });
  });

  group('DriverLicense', () {
    setUp(() {
      // No setup needed for data class tests
    });

    tearDown(() {
      // No teardown needed for data class tests
    });

    test('constructor sets properties correctly', () {
      const license = DriverLicense(
        documentType: 'DL',
        firstName: 'John',
        lastName: 'Doe',
        middleName: 'M',
        gender: 'M',
        addressStreet: '123 Main St',
        addressCity: 'Anytown',
        addressState: 'CA',
        addressZip: '12345',
        birthDate: '01/01/1990',
        issueDate: '01/01/2020',
        expiryDate: '01/01/2025',
        issuingCountry: 'USA',
        licenseNumber: 'D1234567',
      );

      expect(license.firstName, 'John');
      expect(license.lastName, 'Doe');
      expect(license.licenseNumber, 'D1234567');
      expect(license.middleName, 'M');
      expect(license.gender, 'M');
      expect(license.addressStreet, '123 Main St');
      expect(license.addressCity, 'Anytown');
      expect(license.addressState, 'CA');
      expect(license.addressZip, '12345');
      expect(license.birthDate, '01/01/1990');
      expect(license.issueDate, '01/01/2020');
      expect(license.expiryDate, '01/01/2025');
      expect(license.issuingCountry, 'USA');
      expect(license.documentType, 'DL');
    });

    test('fromNative creates DriverLicense from map', () {
      final license = DriverLicense.fromNative({
        'addressCity': 'Anytown',
        'addressState': 'CA',
        'addressStreet': '123 Main St',
        'addressZip': '12345',
        'birthDate': '01/01/1990',
        'documentType': 'DL',
        'expiryDate': '01/01/2025',
        'firstName': 'John',
        'gender': '1',
        'issueDate': '01/01/2020',
        'issuingCountry': 'USA',
        'lastName': 'Doe',
        'licenseNumber': 'D1234567',
        'middleName': 'M',
      });

      expect(license.addressCity, 'Anytown');
      expect(license.addressState, 'CA');
      expect(license.addressStreet, '123 Main St');
      expect(license.addressZip, '12345');
      expect(license.birthDate, '01/01/1990');
      expect(license.documentType, 'DL');
      expect(license.expiryDate, '01/01/2025');
      expect(license.firstName, 'John');
      expect(license.gender, '1');
      expect(license.issueDate, '01/01/2020');
      expect(license.issuingCountry, 'USA');
      expect(license.lastName, 'Doe');
      expect(license.licenseNumber, 'D1234567');
      expect(license.middleName, 'M');
    });

    test('fromNative handles null values', () {
      final license = DriverLicense.fromNative({});

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
  });

  group('Email', () {
    setUp(() {
      // No setup needed for data class tests
    });

    tearDown(() {
      // No teardown needed for data class tests
    });

    test('constructor sets properties correctly', () {
      const email = Email(
        address: 'test@example.com',
        body: 'Hello',
        subject: 'Greetings',
        type: EmailType.home,
      );

      expect(email.address, 'test@example.com');
      expect(email.body, 'Hello');
      expect(email.subject, 'Greetings');
      expect(email.type, EmailType.home);
    });

    test('fromNative creates Email from map', () {
      final email = Email.fromNative({
        'address': 'test@example.com',
        'body': 'Hello World',
        'subject': 'Greetings',
        'type': 1, // work (not home)
      });

      expect(email.address, 'test@example.com');
      expect(email.body, 'Hello World');
      expect(email.subject, 'Greetings');
      expect(email.type, EmailType.work);
    });

    test('fromNative handles null values', () {
      final email = Email.fromNative({});

      expect(email.address, isNull);
      expect(email.body, isNull);
      expect(email.subject, isNull);
      expect(email.type, EmailType.unknown);
    });
  });

  group('GeoPoint', () {
    setUp(() {
      // No setup needed for data class tests
    });

    tearDown(() {
      // No teardown needed for data class tests
    });

    test('constructor sets properties correctly', () {
      const point = GeoPoint(latitude: 37.7749, longitude: -122.4194);
      expect(point.latitude, 37.7749);
      expect(point.longitude, -122.4194);
    });

    test('fromNative creates GeoPoint from map', () {
      final point = GeoPoint.fromNative({
        'latitude': 37.7749,
        'longitude': -122.4194,
      });

      expect(point.latitude, 37.7749);
      expect(point.longitude, -122.4194);
    });

    test('fromNative returns 0,0 when latitude is null', () {
      final point = GeoPoint.fromNative({
        'longitude': -122.4194,
      });

      expect(point.latitude, 0);
      expect(point.longitude, 0);
    });

    test('fromNative returns 0,0 when longitude is null', () {
      final point = GeoPoint.fromNative({
        'latitude': 37.7749,
      });

      expect(point.latitude, 0);
      expect(point.longitude, 0);
    });

    test('fromNative returns 0,0 when both are null', () {
      final point = GeoPoint.fromNative({});

      expect(point.latitude, 0);
      expect(point.longitude, 0);
    });
  });

  group('PersonName', () {
    setUp(() {
      // No setup needed for data class tests
    });

    tearDown(() {
      // No teardown needed for data class tests
    });

    test('constructor sets properties correctly', () {
      const name = PersonName(
        formattedName: 'John Doe',
        first: 'John',
        middle: 'M',
        last: 'Doe',
        prefix: 'Dr.',
        suffix: 'Jr.',
        pronunciation: 'jon',
      );

      expect(name.formattedName, 'John Doe');
      expect(name.first, 'John');
      expect(name.last, 'Doe');
      expect(name.prefix, 'Dr.');
      expect(name.suffix, 'Jr.');
      expect(name.middle, 'M');
      expect(name.pronunciation, 'jon');
    });

    test('fromNative creates PersonName from map', () {
      final name = PersonName.fromNative({
        'first': 'John',
        'middle': 'M',
        'last': 'Doe',
        'prefix': 'Dr.',
        'suffix': 'Jr.',
        'formattedName': 'John Doe',
        'pronunciation': 'jon',
      });

      expect(name.first, 'John');
      expect(name.middle, 'M');
      expect(name.last, 'Doe');
      expect(name.prefix, 'Dr.');
      expect(name.suffix, 'Jr.');
      expect(name.formattedName, 'John Doe');
      expect(name.pronunciation, 'jon');
    });

    test('fromNative handles null values', () {
      final name = PersonName.fromNative({});

      expect(name.first, isNull);
      expect(name.middle, isNull);
      expect(name.last, isNull);
      expect(name.prefix, isNull);
      expect(name.suffix, isNull);
      expect(name.formattedName, isNull);
      expect(name.pronunciation, isNull);
    });
  });

  group('Phone', () {
    setUp(() {
      // No setup needed for data class tests
    });

    tearDown(() {
      // No teardown needed for data class tests
    });

    test('constructor sets properties correctly', () {
      const phone = Phone(
        number: '555-1234',
        type: PhoneType.mobile,
      );

      expect(phone.number, '555-1234');
      expect(phone.type, PhoneType.mobile);
    });

    test('fromNative creates Phone from map', () {
      final phone = Phone.fromNative({
        'number': '555-1234',
        'type': 1, // work
      });

      expect(phone.number, '555-1234');
      expect(phone.type, PhoneType.work);
    });

    test('fromNative handles null values', () {
      final phone = Phone.fromNative({});

      expect(phone.number, isNull);
      expect(phone.type, PhoneType.unknown);
    });
  });

  group('SMS', () {
    setUp(() {
      // No setup needed for data class tests
    });

    tearDown(() {
      // No teardown needed for data class tests
    });

    test('constructor sets properties correctly', () {
      final sms = SMS(phoneNumber: '555-1234', message: 'Hello!');
      expect(sms.phoneNumber, '555-1234');
      expect(sms.message, 'Hello!');
    });

    test('fromNative creates SMS from map', () {
      final sms = SMS.fromNative({
        'phoneNumber': '555-1234',
        'message': 'Hello World',
      });

      expect(sms.phoneNumber, '555-1234');
      expect(sms.message, 'Hello World');
    });

    test('fromNative handles null phoneNumber', () {
      final sms = SMS.fromNative({
        'message': 'Hello',
      });

      expect(sms.phoneNumber, '');
      expect(sms.message, 'Hello');
    });

    test('fromNative handles null values', () {
      final sms = SMS.fromNative({});

      expect(sms.phoneNumber, '');
      expect(sms.message, isNull);
    });
  });

  group('UrlBookmark', () {
    setUp(() {
      // No setup needed for data class tests
    });

    tearDown(() {
      // No teardown needed for data class tests
    });

    test('constructor sets properties correctly', () {
      final bookmark = UrlBookmark(url: 'https://example.com', title: 'Example');
      expect(bookmark.title, 'Example');
      expect(bookmark.url, 'https://example.com');
    });

    test('fromNative creates UrlBookmark from map', () {
      final bookmark = UrlBookmark.fromNative({
        'url': 'https://example.com',
        'title': 'Example Site',
      });

      expect(bookmark.url, 'https://example.com');
      expect(bookmark.title, 'Example Site');
    });

    test('fromNative handles null url', () {
      final bookmark = UrlBookmark.fromNative({
        'title': 'Example',
      });

      expect(bookmark.url, '');
      expect(bookmark.title, 'Example');
    });

    test('fromNative handles null values', () {
      final bookmark = UrlBookmark.fromNative({});

      expect(bookmark.url, '');
      expect(bookmark.title, isNull);
    });
  });

  group('WiFi', () {
    setUp(() {
      // No setup needed for data class tests
    });

    tearDown(() {
      // No teardown needed for data class tests
    });

    test('constructor sets properties correctly', () {
      const wifi = WiFi(
        ssid: 'HomeNetwork',
        password: 'password123',
        encryptionType: EncryptionType.wpa,
      );

      expect(wifi.ssid, 'HomeNetwork');
      expect(wifi.password, 'password123');
      expect(wifi.encryptionType, EncryptionType.wpa);
    });

    test('fromNative creates WiFi from map', () {
      final wifi = WiFi.fromNative({
        'ssid': 'HomeNetwork',
        'password': 'password123',
        'encryptionType': 2, // wpa
      });

      expect(wifi.ssid, 'HomeNetwork');
      expect(wifi.password, 'password123');
      expect(wifi.encryptionType, EncryptionType.wpa);
    });

    test('fromNative handles null values', () {
      final wifi = WiFi.fromNative({});

      expect(wifi.ssid, isNull);
      expect(wifi.password, isNull);
      expect(wifi.encryptionType, EncryptionType.unknown);
    });
  });

  group('Barcode fromNative', () {
    test('fromNative creates Barcode with all fields from map', () {
      final barcode = Barcode.fromNative({
        'calendarEvent': {
          'description': 'Meeting',
          'start': '2024-01-01T09:00:00',
          'end': '2024-01-01T10:00:00',
          'location': 'Room 1',
          'organizer': 'Alice',
          'status': 'confirmed',
          'summary': 'Team meeting',
        },
        'contactInfo': {
          'name': {'formattedName': 'John Doe'},
          'organization': 'Acme Inc',
        },
        'corners': [
          {'x': 0.0, 'y': 0.0},
          {'x': 10.0, 'y': 0.0},
          {'x': 10.0, 'y': 10.0},
          {'x': 0.0, 'y': 10.0},
        ],
        'displayValue': 'Product: 12345',
        'driverLicense': {
          'firstName': 'John',
          'lastName': 'Doe',
          'documentType': 'DL',
        },
        'email': {
          'address': 'john@example.com',
          'subject': 'Hello',
          'type': 2,
        },
        'format': 256, // qrCode
        'geoPoint': {
          'latitude': 37.7749,
          'longitude': -122.4194,
        },
        'phone': {
          'number': '555-1234',
          'type': 1,
        },
        'rawBytes': Uint8List.fromList([0x48, 0x65, 0x6C, 0x6C, 0x6F]),
        'rawValue': 'Hello',
        'size': {
          'width': 200.0,
          'height': 100.0,
        },
        'sms': {
          'phoneNumber': '555-5678',
          'message': 'Hello SMS',
        },
        'type': 7, // text
        'url': {
          'url': 'https://example.com',
          'title': 'Example',
        },
        'wifi': {
          'ssid': 'HomeNetwork',
          'password': 'password123',
          'encryptionType': 2,
        },
      });

      expect(barcode.calendarEvent, isNotNull);
      expect(barcode.calendarEvent!.description, 'Meeting');
      expect(barcode.contactInfo, isNotNull);
      expect(barcode.corners.length, 4);
      expect(barcode.displayValue, 'Product: 12345');
      expect(barcode.driverLicense, isNotNull);
      expect(barcode.email, isNotNull);
      expect(barcode.format, BarcodeFormat.qrCode);
      expect(barcode.geoPoint, isNotNull);
      expect(barcode.phone, isNotNull);
      expect(barcode.rawBytes, isNotNull);
      expect(barcode.rawValue, 'Hello');
      expect(barcode.size, const Size(200, 100));
      expect(barcode.sms, isNotNull);
      expect(barcode.type, BarcodeType.text);
      expect(barcode.url, isNotNull);
      expect(barcode.wifi, isNotNull);
    });

    test('fromNative handles null values', () {
      final barcode = Barcode.fromNative({});

      expect(barcode.calendarEvent, isNull);
      expect(barcode.contactInfo, isNull);
      expect(barcode.corners, isEmpty);
      expect(barcode.displayValue, isNull);
      expect(barcode.driverLicense, isNull);
      expect(barcode.email, isNull);
      expect(barcode.format, BarcodeFormat.unknown);
      expect(barcode.geoPoint, isNull);
      expect(barcode.phone, isNull);
      expect(barcode.rawBytes, isNull);
      expect(barcode.rawValue, isNull);
      expect(barcode.size, Size.zero);
      expect(barcode.sms, isNull);
      expect(barcode.type, BarcodeType.unknown);
      expect(barcode.url, isNull);
      expect(barcode.wifi, isNull);
    });

    test('fromNative handles null size entries', () {
      final barcode = Barcode.fromNative({
        'size': {'width': null, 'height': null},
      });

      expect(barcode.size, Size.zero);
    });
  });

  group('MobileScannerState', () {
    setUp(() {
      // No setup needed for state tests
    });

    tearDown(() {
      // No teardown needed for state tests
    });

    test('constructor sets all properties correctly', () {
      const state = MobileScannerState(
        availableCameras: 2,
        cameraDirection: CameraFacing.back,
        isInitialized: true,
        isStarting: false,
        isRunning: true,
        size: Size(1920, 1080),
        torchState: TorchState.on,
        zoomScale: 0.5,
        deviceOrientation: DeviceOrientation.portraitUp,
      );

      expect(state.availableCameras, 2);
      expect(state.cameraDirection, CameraFacing.back);
      expect(state.isInitialized, true);
      expect(state.isStarting, false);
      expect(state.isRunning, true);
      expect(state.size, const Size(1920, 1080));
      expect(state.torchState, TorchState.on);
      expect(state.zoomScale, 0.5);
      expect(state.deviceOrientation, DeviceOrientation.portraitUp);
      expect(state.error, isNull);
    });

    test('copyWith updates all properties', () {
      final state = MobileScannerState.uninitialized();

      final updated = state.copyWith(
        availableCameras: 2,
        cameraDirection: CameraFacing.front,
        isInitialized: true,
        isStarting: true,
        isRunning: true,
        size: const Size(640, 480),
        torchState: TorchState.on,
        deviceOrientation: DeviceOrientation.landscapeLeft,
        zoomScale: 0.8,
        error: const MobileScannerException(
          errorCode: MobileScannerErrorCode.genericError,
        ),
      );

      expect(updated.availableCameras, 2);
      expect(updated.cameraDirection, CameraFacing.front);
      expect(updated.isInitialized, true);
      expect(updated.isStarting, true);
      expect(updated.isRunning, true);
      expect(updated.size, const Size(640, 480));
      expect(updated.torchState, TorchState.on);
      expect(updated.deviceOrientation, DeviceOrientation.landscapeLeft);
      expect(updated.zoomScale, 0.8);
      expect(updated.error, isNotNull);
    });
  });
}