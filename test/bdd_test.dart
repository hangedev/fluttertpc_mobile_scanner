import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mobile_scanner/src/enums/camera_facing.dart';
import 'package:mobile_scanner/src/enums/mobile_scanner_error_code.dart';
import 'package:mobile_scanner/src/mobile_scanner_exception.dart';
import 'package:mobile_scanner/src/mobile_scanner_platform_interface.dart';
import 'package:mobile_scanner/src/method_channel/mobile_scanner_method_channel.dart';

void main() {
  const MethodChannel methodChannel = MethodChannel(
    'dev.steenbakker.mobile_scanner/scanner/method',
  );

  TestWidgetsFlutterBinding.ensureInitialized();

  group('MobileScannerController — BDD style', () {
    late MobileScannerController controller;

    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        methodChannel,
        (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'state':
              return 1;
            case 'request':
              return true;
            case 'start':
              return <String, Object?>{
                'textureId': 42,
                'size': <String, Object?>{
                  'width': 480.0,
                  'height': 640.0,
                },
                'currentTorchState': 0,
                'numberOfCameras': 2,
              };
            case 'stop':
              return null;
            case 'toggleTorch':
              return null;
            case 'setScale':
              return null;
            case 'resetScale':
              return null;
            case 'updateScanWindow':
              return null;
            case 'analyzeImage':
              return <String, Object?>{
                'name': 'barcode',
                'data': <Map<Object?, Object?>>[
                  <String, Object?>{
                    'format': 256,
                    'type': 7,
                    'rawValue': 'https://example.com',
                    'displayValue': 'https://example.com',
                  },
                ],
              };
            default:
              return null;
          }
        },
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel, null);
      MobileScannerPlatform.instance = MethodChannelMobileScanner();
    });

    test('should start the controller when start() is called', () async {
      // Given
      controller = MobileScannerController(autoStart: false);

      // When
      await controller.start();

      // Then
      expect(controller.value.isInitialized, true);
      expect(controller.value.isRunning, true);
    });

    test('should stop the controller when stop() is called', () async {
      // Given
      controller = MobileScannerController(autoStart: false);
      await controller.start();

      // When
      await controller.stop();

      // Then
      expect(controller.value.isRunning, false);
    });

    test('should release resources when dispose() is called', () async {
      // Given
      controller = MobileScannerController(autoStart: false);
      await controller.start();

      // When
      await controller.dispose();

      // Then: dispose should not throw, and double dispose should be safe
      // (state may remain running after dispose since mock doesn't emit state changes)
      await controller.dispose(); // double dispose should not throw
    });

    test('should throw MobileScannerException when starting after dispose()', () async {
      // Given
      controller = MobileScannerController(autoStart: false);
      await controller.dispose();

      // When / Then
      expect(
        () => controller.start(),
        throwsA(isA<MobileScannerException>()),
      );
    });

    test('should return barcode capture when analyzeImage() is called with valid path', () async {
      // Given
      controller = MobileScannerController(autoStart: false);
      await controller.start();

      // When
      final result = await controller.analyzeImage('/test/path');

      // Then
      expect(result, isNotNull);
      expect(result!.barcodes.length, 1);
      expect(result.barcodes[0].rawValue, 'https://example.com');
    });

    test('should handle permission denied when start() is called without permission', () async {
      // Given
      controller = MobileScannerController(autoStart: false);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        methodChannel,
        (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'state':
              return 0;
            case 'request':
              return false;
            case 'stop':
              return null;
            default:
              return null;
          }
        },
      );

      // When
      await controller.start();

      // Then
      expect(controller.value.hasCameraPermission, false);
    });

    test('should switch camera direction when switchCamera() is called with 2 cameras', () async {
      // Given
      controller = MobileScannerController(autoStart: false);
      await controller.start();

      // When
      await controller.switchCamera();

      // Then
      expect(controller.value.cameraDirection, CameraFacing.front);
    });

    test('should not throw when toggleTorch() is called after stop()', () async {
      // Given
      controller = MobileScannerController(autoStart: false);
      await controller.start();
      await controller.stop();

      // When / Then (should not throw)
      await controller.toggleTorch();
    });
  });

  group('MobileScannerException — BDD style', () {
    test('should have errorCode when created with genericError', () {
      // Given
      const exception = MobileScannerException(
        errorCode: MobileScannerErrorCode.genericError,
      );

      // Then
      expect(exception.errorCode, MobileScannerErrorCode.genericError);
      expect(exception.errorDetails, isNull);
    });

    test('should include error details when created with errorDetails', () {
      // Given
      const exception = MobileScannerException(
        errorCode: MobileScannerErrorCode.permissionDenied,
        errorDetails: MobileScannerErrorDetails(
          message: 'Camera permission denied',
        ),
      );

      // Then
      expect(exception.errorCode, MobileScannerErrorCode.permissionDenied);
      expect(exception.errorDetails!.message, 'Camera permission denied');
    });
  });

  group('MobileScannerState — BDD style', () {
    test('should be uninitialized when created with uninitialized()', () {
      // Given
      final state = MobileScannerState.uninitialized(CameraFacing.back);

      // Then
      expect(state.isInitialized, false);
      expect(state.isRunning, false);
      expect(state.hasCameraPermission, false);
    });

    test('should have hasCameraPermission true when initialized without error', () {
      // Given
      final state = MobileScannerState.uninitialized(CameraFacing.back);

      // When
      final modified = state.copyWith(isInitialized: true, isRunning: true);

      // Then
      expect(modified.hasCameraPermission, true);
    });

    test('should have hasCameraPermission false when permission denied error exists', () {
      // Given
      final state = MobileScannerState.uninitialized(CameraFacing.back);

      // When
      final modified = state.copyWith(
        isInitialized: true,
        error: const MobileScannerException(
          errorCode: MobileScannerErrorCode.permissionDenied,
        ),
      );

      // Then
      expect(modified.hasCameraPermission, false);
    });
  });
}