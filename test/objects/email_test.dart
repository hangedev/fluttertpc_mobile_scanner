import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/enums/email_type.dart';
import 'package:mobile_scanner/src/objects/email.dart';

void main() {
  group('Email', () {
    test('constructor creates with default values', () {
      const email = Email();
      expect(email.address, isNull);
      expect(email.body, isNull);
      expect(email.subject, isNull);
      expect(email.type, EmailType.unknown);
    });

    test('constructor creates with custom values', () {
      const email = Email(
        address: 'test@example.com',
        body: 'Hello world',
        subject: 'Greetings',
        type: EmailType.work,
      );
      expect(email.address, 'test@example.com');
      expect(email.body, 'Hello world');
      expect(email.subject, 'Greetings');
      expect(email.type, EmailType.work);
    });

    test('fromNative parses data correctly', () {
      final data = <Object?, Object?>{
        'address': 'john@example.com',
        'body': 'Meeting at 3pm',
        'subject': 'Reminder',
        'type': 1, // work
      };

      final email = Email.fromNative(data);
      expect(email.address, 'john@example.com');
      expect(email.body, 'Meeting at 3pm');
      expect(email.subject, 'Reminder');
      expect(email.type, EmailType.work);
    });

    test('fromNative handles missing fields', () {
      final data = <Object?, Object?>{};

      final email = Email.fromNative(data);
      expect(email.address, isNull);
      expect(email.body, isNull);
      expect(email.subject, isNull);
      expect(email.type, EmailType.unknown);
    });

    test('fromNative handles null type', () {
      final data = <Object?, Object?>{
        'address': 'test@example.com',
        'type': null,
      };

      final email = Email.fromNative(data);
      expect(email.address, 'test@example.com');
      expect(email.type, EmailType.unknown);
    });

    test('fromNative handles missing body and subject', () {
      final data = <Object?, Object?>{
        'address': 'quick@example.com',
      };

      final email = Email.fromNative(data);
      expect(email.address, 'quick@example.com');
      expect(email.body, isNull);
      expect(email.subject, isNull);
    });
  });
}