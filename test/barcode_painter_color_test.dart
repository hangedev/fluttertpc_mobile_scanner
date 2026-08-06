import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

void main() {
  group('BarcodePainter extended', () {
    test('BarcodePainter equality works correctly', () {
      final textPainter = TextPainter(
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );

      final painter1 = BarcodePainter(
        barcodeCorners: const [],
        barcodeSize: Size.zero,
        barcodeValue: '',
        boxFit: BoxFit.contain,
        cameraPreviewSize: const Size(100, 100),
        color: Colors.green,
        style: PaintingStyle.fill,
        textPainter: textPainter,
        deviceOrientation: DeviceOrientation.portraitUp,
      );

      final painter2 = BarcodePainter(
        barcodeCorners: const [],
        barcodeSize: Size.zero,
        barcodeValue: '',
        boxFit: BoxFit.contain,
        cameraPreviewSize: const Size(100, 100),
        color: Colors.green,
        style: PaintingStyle.fill,
        textPainter: textPainter,
        deviceOrientation: DeviceOrientation.portraitUp,
      );

      final painter3 = BarcodePainter(
        barcodeCorners: const [Offset(0, 0)],
        barcodeSize: const Size(10, 10),
        barcodeValue: 'test',
        boxFit: BoxFit.cover,
        cameraPreviewSize: const Size(200, 200),
        color: Colors.red,
        style: PaintingStyle.stroke,
        textPainter: textPainter,
        deviceOrientation: DeviceOrientation.landscapeLeft,
      );

      expect(painter1.shouldRepaint(painter2), isFalse);
      expect(painter1.shouldRepaint(painter3), isTrue);
    });

    test('BarcodePainter handles empty barcodes gracefully', () {
      final textPainter = TextPainter(
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );

      final painter = BarcodePainter(
        barcodeCorners: const [],
        barcodeSize: Size.zero,
        barcodeValue: '',
        boxFit: BoxFit.contain,
        cameraPreviewSize: const Size(100, 100),
        color: Colors.green,
        style: PaintingStyle.fill,
        textPainter: textPainter,
        deviceOrientation: DeviceOrientation.portraitUp,
      );

      expect(painter.shouldRepaint(painter), isFalse);
    });
  });
}