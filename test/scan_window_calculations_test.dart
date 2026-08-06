import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/scan_window_calculation.dart';
import 'package:mobile_scanner/src/overlay/barcode_painter.dart' as barcode_painter;

void main() {
  group('calculateScanWindowRelativeToTextureInPercentage', () {
    test('calculates correct percentages for small window', () {
      final result = calculateScanWindowRelativeToTextureInPercentage(
        BoxFit.contain,
        const Rect.fromLTWH(10, 10, 20, 20),
        textureSize: const Size(100, 100),
        widgetSize: const Size(100, 100),
      );
      expect(result, isNotNull);
      expect(result.left, closeTo(0.1, 0.001));
      expect(result.top, closeTo(0.1, 0.001));
      expect(result.right, closeTo(0.3, 0.001));
      expect(result.bottom, closeTo(0.3, 0.001));
    });

    test('calculates correct percentages for full window', () {
      final result = calculateScanWindowRelativeToTextureInPercentage(
        BoxFit.contain,
        const Rect.fromLTWH(0, 0, 100, 100),
        textureSize: const Size(100, 100),
        widgetSize: const Size(100, 100),
      );
      expect(result, isNotNull);
      expect(result.left, closeTo(0.0, 0.001));
      expect(result.top, closeTo(0.0, 0.001));
      expect(result.right, closeTo(1.0, 0.001));
      expect(result.bottom, closeTo(1.0, 0.001));
    });
  });

  group('calculateBoxFitRatio', () {
    test('returns correct ratio for contain fit', () {
      final ratio = barcode_painter.calculateBoxFitRatio(
        BoxFit.contain,
        const Size(1920, 1080),
        const Size(1080, 1920),
      );
      expect(ratio.widthRatio, greaterThan(0));
      expect(ratio.heightRatio, greaterThan(0));
    });

    test('returns ratio 1.0 for zero dimensions', () {
      final ratio = barcode_painter.calculateBoxFitRatio(
        BoxFit.contain,
        Size.zero,
        const Size(100, 100),
      );
      expect(ratio.widthRatio, 1.0);
      expect(ratio.heightRatio, 1.0);
    });
  });
}