import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/enums/barcode_format.dart';
import 'package:mobile_scanner/src/enums/camera_facing.dart';
import 'package:mobile_scanner/src/enums/detection_speed.dart';
import 'package:mobile_scanner/src/objects/start_options.dart';

void main() {
  group('StartOptions', () {
    test('can be created with values', () {
      final options = StartOptions(
        cameraDirection: CameraFacing.back,
        cameraResolution: null,
        detectionSpeed: DetectionSpeed.normal,
        detectionTimeoutMs: 250,
        formats: [],
        returnImage: false,
        torchEnabled: false,
        useNewCameraSelector: false,
      );
      expect(options.cameraDirection, CameraFacing.back);
      expect(options.cameraResolution, isNull);
      expect(options.detectionSpeed, DetectionSpeed.normal);
      expect(options.detectionTimeoutMs, 250);
      expect(options.formats, isEmpty);
      expect(options.returnImage, false);
      expect(options.torchEnabled, false);
      expect(options.useNewCameraSelector, false);
    });

    test('can be created with custom values', () {
      final options = StartOptions(
        cameraDirection: CameraFacing.front,
        cameraResolution: const Size(1920, 1080),
        detectionSpeed: DetectionSpeed.noDuplicates,
        detectionTimeoutMs: 500,
        formats: [BarcodeFormat.qrCode],
        returnImage: true,
        torchEnabled: true,
        useNewCameraSelector: true,
      );
      expect(options.cameraDirection, CameraFacing.front);
      expect(options.cameraResolution!.width, 1920);
      expect(options.cameraResolution!.height, 1080);
      expect(options.detectionSpeed, DetectionSpeed.noDuplicates);
      expect(options.detectionTimeoutMs, 500);
      expect(options.formats, [BarcodeFormat.qrCode]);
      expect(options.returnImage, true);
      expect(options.torchEnabled, true);
      expect(options.useNewCameraSelector, true);
    });

    test('toMap returns correct structure', () {
      final options = StartOptions(
        cameraDirection: CameraFacing.back,
        cameraResolution: null,
        detectionSpeed: DetectionSpeed.normal,
        detectionTimeoutMs: 250,
        formats: [BarcodeFormat.qrCode, BarcodeFormat.code128],
        returnImage: true,
        torchEnabled: false,
        useNewCameraSelector: false,
      );
      final map = options.toMap();
      expect(map['torch'], false);
      expect(map['facing'], 1);
      expect(map['formats'], [256, 1]);
      expect(map['returnImage'], true);
      expect(map['speed'], DetectionSpeed.normal.rawValue);
      expect(map['timeout'], 250);
    });
  });
}