import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

void main() {
  group('MobileScannerViewAttributes', () {
    test('constructor sets all properties correctly', () {
      const attributes = MobileScannerViewAttributes(
        cameraDirection: CameraFacing.back,
        currentTorchMode: TorchState.on,
        size: Size(1920, 1080),
        numberOfCameras: 2,
        initialDeviceOrientation: DeviceOrientation.portraitUp,
      );

      expect(attributes.cameraDirection, CameraFacing.back);
      expect(attributes.currentTorchMode, TorchState.on);
      expect(attributes.size, const Size(1920, 1080));
      expect(attributes.numberOfCameras, 2);
      expect(attributes.initialDeviceOrientation, DeviceOrientation.portraitUp);
    });

    test('equality works correctly', () {
      const attributes1 = MobileScannerViewAttributes(
        cameraDirection: CameraFacing.back,
        currentTorchMode: TorchState.on,
        size: Size(1920, 1080),
        numberOfCameras: 2,
        initialDeviceOrientation: DeviceOrientation.portraitUp,
      );

      const attributes2 = MobileScannerViewAttributes(
        cameraDirection: CameraFacing.back,
        currentTorchMode: TorchState.on,
        size: Size(1920, 1080),
        numberOfCameras: 2,
        initialDeviceOrientation: DeviceOrientation.portraitUp,
      );

      const attributes3 = MobileScannerViewAttributes(
        cameraDirection: CameraFacing.front,
        currentTorchMode: TorchState.off,
        size: Size(1080, 1920),
        numberOfCameras: 1,
        initialDeviceOrientation: DeviceOrientation.portraitDown,
      );

      expect(attributes1, equals(attributes2));
      expect(attributes1, isNot(equals(attributes3)));
    });
  });
}