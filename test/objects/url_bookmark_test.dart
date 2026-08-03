import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/objects/url_bookmark.dart';

void main() {
  group('UrlBookmark', () {
    test('constructor creates with url', () {
      const bookmark = UrlBookmark(url: 'https://example.com');
      expect(bookmark.url, 'https://example.com');
      expect(bookmark.title, isNull);
    });

    test('constructor creates with title and url', () {
      const bookmark = UrlBookmark(
        title: 'Example',
        url: 'https://example.com',
      );
      expect(bookmark.title, 'Example');
      expect(bookmark.url, 'https://example.com');
    });

    test('fromNative parses data correctly', () {
      final data = <Object?, Object?>{
        'title': 'Google',
        'url': 'https://www.google.com',
      };

      final bookmark = UrlBookmark.fromNative(data);
      expect(bookmark.title, 'Google');
      expect(bookmark.url, 'https://www.google.com');
    });

    test('fromNative handles missing url', () {
      final data = <Object?, Object?>{
        'title': 'No URL',
      };

      final bookmark = UrlBookmark.fromNative(data);
      expect(bookmark.title, 'No URL');
      expect(bookmark.url, '');
    });

    test('fromNative handles null url', () {
      final data = <Object?, Object?>{
        'url': null,
      };

      final bookmark = UrlBookmark.fromNative(data);
      expect(bookmark.url, '');
    });

    test('fromNative handles missing title', () {
      final data = <Object?, Object?>{
        'url': 'https://example.com',
      };

      final bookmark = UrlBookmark.fromNative(data);
      expect(bookmark.title, isNull);
      expect(bookmark.url, 'https://example.com');
    });

    test('fromNative handles empty data', () {
      final data = <Object?, Object?>{};

      final bookmark = UrlBookmark.fromNative(data);
      expect(bookmark.title, isNull);
      expect(bookmark.url, '');
    });
  });
}