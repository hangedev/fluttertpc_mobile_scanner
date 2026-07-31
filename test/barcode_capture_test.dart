import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/enums/barcode_format.dart';
import 'package:mobile_scanner/src/enums/barcode_type.dart';
import 'package:mobile_scanner/src/objects/barcode.dart';
import 'package:mobile_scanner/src/objects/barcode_capture.dart';

void main() {
  group('BarcodeCapture', () {
    test('can be created with empty barcodes list', () {
      final capture = BarcodeCapture(
        barcodes: [],
        image: null,
        size: Size.zero,
      );
      expect(capture.barcodes, isEmpty);
      expect(capture.image, isNull);
      expect(capture.size, Size.zero);
    });

    test('can be created with barcodes', () {
      const barcode = Barcode(
        displayValue: 'test',
        rawValue: 'test-raw',
        format: BarcodeFormat.qrCode,
        type: BarcodeType.text,
      );
      final capture = BarcodeCapture(
        barcodes: [barcode],
        image: Uint8List.fromList([1, 2, 3]),
        size: const Size(100.0, 100.0),
      );
      expect(capture.barcodes.length, 1);
      expect(capture.barcodes[0].displayValue, 'test');
      expect(capture.image, isNotNull);
      expect(capture.size.width, 100.0);
    });

    test('raw contains the original event data', () {
      final rawData = <Object?, Object?>{
        'name': 'barcode',
        'data': <Object?>[],
      };
      const barcode = Barcode();
      final capture = BarcodeCapture(
        raw: rawData,
        barcodes: [barcode],
        image: null,
        size: Size.zero,
      );
      expect(capture.raw, rawData);
      expect((capture.raw as Map<Object?, Object?>)['name'], 'barcode');
    });
  });
}