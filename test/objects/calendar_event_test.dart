import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/objects/calendar_event.dart';

void main() {
  group('CalendarEvent', () {
    test('constructor creates with default values', () {
      const event = CalendarEvent();
      expect(event.description, isNull);
      expect(event.start, isNull);
      expect(event.end, isNull);
      expect(event.location, isNull);
      expect(event.organizer, isNull);
      expect(event.status, isNull);
      expect(event.summary, isNull);
    });

    test('constructor creates with custom values', () {
      const event = CalendarEvent(
        description: 'Team meeting',
        location: 'Room 301',
        organizer: 'john@example.com',
        status: 'confirmed',
        summary: 'Weekly sync',
      );
      expect(event.description, 'Team meeting');
      expect(event.location, 'Room 301');
      expect(event.organizer, 'john@example.com');
      expect(event.status, 'confirmed');
      expect(event.summary, 'Weekly sync');
    });

    test('fromNative parses data correctly', () {
      final data = <Object?, Object?>{
        'description': 'Lunch meeting',
        'start': '2024-01-15T12:00:00',
        'end': '2024-01-15T13:00:00',
        'location': 'Cafe',
        'organizer': 'alice@example.com',
        'status': 'tentative',
        'summary': 'Lunch',
      };

      final event = CalendarEvent.fromNative(data);
      expect(event.description, 'Lunch meeting');
      expect(event.start, DateTime(2024, 1, 15, 12, 0, 0));
      expect(event.end, DateTime(2024, 1, 15, 13, 0, 0));
      expect(event.location, 'Cafe');
      expect(event.organizer, 'alice@example.com');
      expect(event.status, 'tentative');
      expect(event.summary, 'Lunch');
    });

    test('fromNative handles null start date', () {
      final data = <Object?, Object?>{
        'start': null,
      };

      final event = CalendarEvent.fromNative(data);
      expect(event.start, isNull);
    });

    test('fromNative handles invalid date string', () {
      final data = <Object?, Object?>{
        'start': 'not-a-date',
      };

      final event = CalendarEvent.fromNative(data);
      expect(event.start, isNull);
    });

    test('fromNative handles empty date string', () {
      final data = <Object?, Object?>{
        'start': '',
      };

      final event = CalendarEvent.fromNative(data);
      expect(event.start, isNull);
    });

    test('fromNative handles missing fields', () {
      final data = <Object?, Object?>{};

      final event = CalendarEvent.fromNative(data);
      expect(event.description, isNull);
      expect(event.start, isNull);
      expect(event.end, isNull);
      expect(event.location, isNull);
      expect(event.organizer, isNull);
      expect(event.status, isNull);
      expect(event.summary, isNull);
    });
  });
}