import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

void main() {
  group('StartOptions', () {
    group('constructor', () {
      test('creates with provided values', () {
        final options = StartOptions(
          cameraDirection: CameraFacing.back,
          cameraResolution: const Size(1920, 1080),
          detectionSpeed: DetectionSpeed.normal,
          detectionTimeoutMs: 500,
          formats: const [BarcodeFormat.qrCode],
          returnImage: true,
          torchEnabled: false,
          invertImage: true,
          autoZoom: false,
          initialZoom: 0.5,
        );

        expect(options.cameraDirection, CameraFacing.back);
        expect(options.cameraResolution, const Size(1920, 1080));
        expect(options.detectionSpeed, DetectionSpeed.normal);
        expect(options.detectionTimeoutMs, 500);
        expect(options.formats, [BarcodeFormat.qrCode]);
        expect(options.returnImage, true);
        expect(options.torchEnabled, false);
        expect(options.invertImage, true);
        expect(options.autoZoom, false);
        expect(options.initialZoom, 0.5);
      });
    });

    group('toMap', () {
      test('returns correct map with all values', () {
        final options = StartOptions(
          cameraDirection: CameraFacing.back,
          cameraResolution: const Size(1920, 1080),
          detectionSpeed: DetectionSpeed.normal,
          detectionTimeoutMs: 500,
          formats: const [BarcodeFormat.qrCode],
          returnImage: true,
          torchEnabled: false,
          invertImage: true,
          autoZoom: true,
          initialZoom: 0.5,
        );

        final map = options.toMap();
        expect(map['facing'], CameraFacing.back.rawValue);
        expect(map['cameraResolution'], [1920, 1080]);
        expect(map['speed'], DetectionSpeed.normal.rawValue);
        expect(map['timeout'], 500);
        expect(map['formats'], [BarcodeFormat.qrCode.rawValue]);
        expect(map['returnImage'], true);
        expect(map['torch'], false);
        expect(map['invertImage'], true);
        expect(map['autoZoom'], true);
        expect(map['initialZoom'], 0.5);
      });
    });
  });
}