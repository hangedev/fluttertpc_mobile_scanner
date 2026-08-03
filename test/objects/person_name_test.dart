import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/objects/person_name.dart';

void main() {
  group('PersonName', () {
    test('constructor creates with default values', () {
      const name = PersonName();
      expect(name.first, isNull);
      expect(name.middle, isNull);
      expect(name.last, isNull);
      expect(name.prefix, isNull);
      expect(name.suffix, isNull);
      expect(name.formattedName, isNull);
      expect(name.pronunciation, isNull);
    });

    test('constructor creates with custom values', () {
      const name = PersonName(
        first: 'John',
        last: 'Doe',
        prefix: 'Dr.',
        suffix: 'PhD',
      );
      expect(name.first, 'John');
      expect(name.last, 'Doe');
      expect(name.prefix, 'Dr.');
      expect(name.suffix, 'PhD');
    });

    test('fromNative parses all fields correctly', () {
      final data = <Object?, Object?>{
        'first': 'Jane',
        'middle': 'Marie',
        'last': 'Smith',
        'prefix': 'Ms.',
        'suffix': 'Jr.',
        'formattedName': 'Smith, Jane Marie',
        'pronunciation': 'Jane Smith',
      };

      final name = PersonName.fromNative(data);
      expect(name.first, 'Jane');
      expect(name.middle, 'Marie');
      expect(name.last, 'Smith');
      expect(name.prefix, 'Ms.');
      expect(name.suffix, 'Jr.');
      expect(name.formattedName, 'Smith, Jane Marie');
      expect(name.pronunciation, 'Jane Smith');
    });

    test('fromNative handles missing fields', () {
      final data = <Object?, Object?>{};

      final name = PersonName.fromNative(data);
      expect(name.first, isNull);
      expect(name.middle, isNull);
      expect(name.last, isNull);
      expect(name.prefix, isNull);
      expect(name.suffix, isNull);
      expect(name.formattedName, isNull);
      expect(name.pronunciation, isNull);
    });

    test('fromNative handles partial fields', () {
      final data = <Object?, Object?>{
        'first': 'Bob',
        'last': 'Johnson',
      };

      final name = PersonName.fromNative(data);
      expect(name.first, 'Bob');
      expect(name.last, 'Johnson');
      expect(name.middle, isNull);
      expect(name.prefix, isNull);
    });

    test('fromNative handles formatted name with pronunciation', () {
      final data = <Object?, Object?>{
        'first': 'Taro',
        'last': 'Yamada',
        'formattedName': 'Yamada Taro',
        'pronunciation': 'タロウ ヤマダ',
      };

      final name = PersonName.fromNative(data);
      expect(name.first, 'Taro');
      expect(name.last, 'Yamada');
      expect(name.formattedName, 'Yamada Taro');
      expect(name.pronunciation, 'タロウ ヤマダ');
    });
  });
}