import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/enums/torch_state.dart';
import 'package:mobile_scanner/src/mobile_scanner_view_attributes.dart';

void main() {
  group('MobileScannerViewAttributes', () {
    test('can be created with default values', () {
      const attrs = MobileScannerViewAttributes(
        currentTorchMode: TorchState.off,
        numberOfCameras: 0,
        size: Size.zero,
      );
      expect(attrs.currentTorchMode, TorchState.off);
      expect(attrs.numberOfCameras, 0);
      expect(attrs.size, Size.zero);
    });

    test('can be created with custom values', () {
      const attrs = MobileScannerViewAttributes(
        currentTorchMode: TorchState.on,
        numberOfCameras: 2,
        size: Size(1080, 1920),
      );
      expect(attrs.currentTorchMode, TorchState.on);
      expect(attrs.numberOfCameras, 2);
      expect(attrs.size.width, 1080);
      expect(attrs.size.height, 1920);
    });
  });
}