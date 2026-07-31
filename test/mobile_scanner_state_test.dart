import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/enums/camera_facing.dart';
import 'package:mobile_scanner/src/enums/mobile_scanner_error_code.dart';
import 'package:mobile_scanner/src/enums/torch_state.dart';
import 'package:mobile_scanner/src/mobile_scanner_exception.dart';
import 'package:mobile_scanner/src/objects/mobile_scanner_state.dart';

void main() {
  group('MobileScannerState', () {
    test('uninitialized creates valid state', () {
      final state = const MobileScannerState.uninitialized(CameraFacing.back);
      expect(state.availableCameras, isNull);
      expect(state.cameraDirection, CameraFacing.back);
      expect(state.error, isNull);
      expect(state.isInitialized, false);
      expect(state.isRunning, false);
      expect(state.size, Size.zero);
      expect(state.torchState, TorchState.unavailable);
      expect(state.hasCameraPermission, false);
      expect(state.zoomScale, 1.0);
    });

    test('hasCameraPermission returns true when initialized with no error', () {
      final state = const MobileScannerState(
        availableCameras: 1,
        cameraDirection: CameraFacing.back,
        isInitialized: true,
        isRunning: true,
        size: const Size(1080.0, 720.0),
        torchState: TorchState.off,
        zoomScale: 1.0,
      );
      expect(state.hasCameraPermission, true);
    });

    test('hasCameraPermission returns false when permission denied', () {
      final state = MobileScannerState(
        availableCameras: 1,
        cameraDirection: CameraFacing.back,
        isInitialized: true,
        isRunning: false,
        size: const Size(1080.0, 720.0),
        torchState: TorchState.off,
        zoomScale: 1.0,
        error: const MobileScannerException(
          errorCode: MobileScannerErrorCode.permissionDenied,
        ),
      );
      expect(state.hasCameraPermission, false);
    });

    test('hasCameraPermission returns true when other error occurs', () {
      final state = MobileScannerState(
        availableCameras: 1,
        cameraDirection: CameraFacing.back,
        isInitialized: true,
        isRunning: false,
        size: const Size(1080.0, 720.0),
        torchState: TorchState.off,
        zoomScale: 1.0,
        error: const MobileScannerException(
          errorCode: MobileScannerErrorCode.genericError,
        ),
      );
      expect(state.hasCameraPermission, true);
    });

    test('copyWith can modify state', () {
      final state = MobileScannerState.uninitialized(CameraFacing.back);
      final modified = state.copyWith(
        availableCameras: 2,
        cameraDirection: CameraFacing.front,
        isInitialized: true,
        isRunning: true,
        size: const Size(1080.0, 1080.0),
        torchState: TorchState.on,
        zoomScale: 2.0,
      );
      expect(modified.availableCameras, 2);
      expect(modified.cameraDirection, CameraFacing.front);
      expect(modified.isInitialized, true);
      expect(modified.isRunning, true);
      expect(modified.size.width, 1080.0);
      expect(modified.torchState, TorchState.on);
      expect(modified.zoomScale, 2.0);
    });

    test('copyWith preserves unmodified values', () {
      final state = MobileScannerState.uninitialized(CameraFacing.back);
      final modified = state.copyWith(isRunning: true);
      expect(modified.cameraDirection, CameraFacing.back);
      expect(modified.availableCameras, isNull);
      expect(modified.isInitialized, false);
      expect(modified.isRunning, true);
      expect(modified.zoomScale, 1.0);
    });

    test('toString returns expected format', () {
      final state = MobileScannerState.uninitialized(CameraFacing.back);
      final str = state.toString();
      expect(str, contains('MobileScannerState'));
    });
  });
}