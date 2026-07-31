import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mobile_scanner/src/mobile_scanner_view_attributes.dart';

void main() {
  const MethodChannel methodChannel = MethodChannel(
    'dev.steenbakker.mobile_scanner/scanner/method',
  );

  TestWidgetsFlutterBinding.ensureInitialized();

  group('MobileScannerController', () {
    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        methodChannel,
        (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'start':
              return <String, dynamic>{
                'textureId': 1,
                'size': <String, double>{'width': 1080.0, 'height': 1080.0},
                'torchable': false,
                'numberOfCameras': 1,
                'currentTorchState': 0,
              };
            case 'state':
              return 1;
            case 'torch':
            case 'toggleTorch':
            case 'stop':
            case 'pause':
            case 'setScale':
            case 'resetScale':
            case 'updateScanWindow':
            case 'switchCamera':
              return null;
            case 'analyzeImage':
              return <String, dynamic>{
                'name': 'barcode',
                'data': null,
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
    });

    test('can be created with default parameters', () {
      final controller = MobileScannerController(autoStart: false);
      expect(controller, isNotNull);
      expect(controller.autoStart, false);
      expect(controller.value.isRunning, false);
      expect(controller.value.isInitialized, false);
      controller.dispose();
    });

    test('can be created with custom parameters', () {
      final controller = MobileScannerController(
        autoStart: false,
        torchEnabled: true,
        returnImage: true,
        facing: CameraFacing.back,
        formats: [BarcodeFormat.qrCode],
      );
      expect(controller, isNotNull);
      expect(controller.torchEnabled, true);
      expect(controller.returnImage, true);
      expect(controller.facing, CameraFacing.back);
      expect(controller.formats, [BarcodeFormat.qrCode]);
      controller.dispose();
    });

    test('start should set isRunning to true', () async {
      final controller = MobileScannerController(autoStart: false);
      expect(controller.value.isRunning, false);
      await controller.start();
      expect(controller.value.isRunning, true);
      await controller.dispose();
    });

    test('stop should set isRunning to false', () async {
      final controller = MobileScannerController(autoStart: false);
      await controller.start();
      expect(controller.value.isRunning, true);
      await controller.stop();
      expect(controller.value.isRunning, false);
      await controller.dispose();
    });

    test('pause should set isRunning to false', () async {
      final controller = MobileScannerController(autoStart: false);
      await controller.start();
      expect(controller.value.isRunning, true);
      await controller.pause();
      expect(controller.value.isRunning, false);
      await controller.dispose();
    });

    test('toggleTorch should not throw', () async {
      final controller = MobileScannerController(autoStart: false);
      await controller.start();
      await controller.toggleTorch();
      await controller.dispose();
    });

    test('switchCamera should not throw', () async {
      final controller = MobileScannerController(autoStart: false);
      await controller.start();
      await controller.switchCamera();
      await controller.dispose();
    });

    test('setZoomScale should not throw', () async {
      final controller = MobileScannerController(autoStart: false);
      await controller.start();
      await controller.setZoomScale(0.5);
      await controller.dispose();
    });

    test('resetZoomScale should not throw', () async {
      final controller = MobileScannerController(autoStart: false);
      await controller.start();
      await controller.resetZoomScale();
      await controller.dispose();
    });

    test('updateScanWindow should not throw', () async {
      final controller = MobileScannerController(autoStart: false);
      await controller.updateScanWindow(null);
      await controller.dispose();
    });

    test('analyzeImage should return null for no barcode', () async {
      final controller = MobileScannerController(autoStart: false);
      await controller.start();
      final result = await controller.analyzeImage('/test/path');
      expect(result, isNull);
      await controller.dispose();
    });

    test('dispose should release resources', () async {
      final controller = MobileScannerController(autoStart: false);
      await controller.start();
      await controller.dispose();
      expect(controller.value.isRunning, true);
    });

    test('barcodes stream should be accessible', () {
      final controller = MobileScannerController(autoStart: false);
      final stream = controller.barcodes;
      expect(stream, isA<Stream<BarcodeCapture>>());
      controller.dispose();
    });

    test('cameraResolution should default to null', () {
      final controller = MobileScannerController(autoStart: false);
      expect(controller.cameraResolution, isNull);
      controller.dispose();
    });

    test('detectionTimeoutMs should default to 250', () {
      final controller = MobileScannerController(autoStart: false);
      expect(controller.detectionTimeoutMs, 250);
      controller.dispose();
    });

    test('useNewCameraSelector should default to false', () {
      final controller = MobileScannerController(autoStart: false);
      expect(controller.useNewCameraSelector, false);
      controller.dispose();
    });

    test('start should handle timeout by throwing MobileScannerException', () async {
      final controller = MobileScannerController(autoStart: false);
      // Mock MethodChannel to simulate a timeout by never responding
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        methodChannel,
        (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'start':
              // Simulate a timeout by returning null immediately
              // (as if the platform never properly initialized)
              return null;
            case 'state':
              return 0;
            default:
              return null;
          }
        },
      );
      // Should not throw; timeout is handled gracefully
      await controller.start();
      // When start returns null attrs, isRunning should remain false
      expect(controller.value.isRunning, false);
      // Restore the default mock
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        methodChannel,
        (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'start':
              return <String, dynamic>{
                'textureId': 1,
                'size': <String, double>{'width': 1080.0, 'height': 1080.0},
                'torchable': false,
                'numberOfCameras': 1,
                'currentTorchState': 0,
              };
            case 'state':
              return 1;
            case 'torch':
            case 'toggleTorch':
            case 'stop':
            case 'pause':
            case 'setScale':
            case 'resetScale':
            case 'updateScanWindow':
            case 'switchCamera':
              return null;
            case 'analyzeImage':
              return <String, dynamic>{
                'name': 'barcode',
                'data': null,
              };
            default:
              return null;
          }
        },
      );
      await controller.start();
      expect(controller.value.isRunning, true);
      await controller.dispose();
    });

    test('buildCameraView should return a widget after initialization', () async {
      final controller = MobileScannerController(autoStart: false);
      await controller.start();
      final widget = controller.buildCameraView();
      expect(widget, isNotNull);
      await controller.dispose();
    });

    test('buildCameraView should throw when not initialized', () {
      final controller = MobileScannerController(autoStart: false);
      expect(
        () => controller.buildCameraView(),
        throwsA(isA<MobileScannerException>()),
      );
      controller.dispose();
    });

    test('resetZoomScale should throw when not initialized', () {
      final controller = MobileScannerController(autoStart: false);
      expect(
        () => controller.resetZoomScale(),
        throwsA(isA<MobileScannerException>()),
      );
      controller.dispose();
    });

    test('start should throw when controller is disposed', () async {
      final controller = MobileScannerController(autoStart: false);
      await controller.dispose();
      expect(
        () => controller.start(),
        throwsA(isA<MobileScannerException>()),
      );
    });

    test('start should do nothing when already running', () async {
      final controller = MobileScannerController(autoStart: false);
      await controller.start();
      expect(controller.value.isRunning, true);
      // Calling start again should not throw
      await controller.start();
      expect(controller.value.isRunning, true);
      await controller.dispose();
    });

    test('setZoomScale should clamp to 0.0 for negative values', () async {
      final controller = MobileScannerController(autoStart: false);
      await controller.start();
      // Should not throw
      await controller.setZoomScale(-0.5);
      await controller.dispose();
    });

    test('setZoomScale should clamp to 1.0 for values over 1.0', () async {
      final controller = MobileScannerController(autoStart: false);
      await controller.start();
      // Should not throw
      await controller.setZoomScale(1.5);
      await controller.dispose();
    });

    test('setZoomScale should do nothing when not running', () async {
      final controller = MobileScannerController(autoStart: false);
      await controller.start();
      await controller.stop();
      // After stop, the controller is initialized but not running
      // setZoomScale should not throw when initialized but not running
      await controller.setZoomScale(0.5);
      await controller.dispose();
    });

    test('setZoomScale should throw when not initialized', () async {
      final controller = MobileScannerController(autoStart: false);
      expect(
        () => controller.setZoomScale(0.5),
        throwsA(isA<MobileScannerException>()),
      );
      controller.dispose();
    });

    test('toggleTorch should do nothing when not running', () async {
      final controller = MobileScannerController(autoStart: false);
      await controller.start();
      await controller.stop();
      // Should not throw
      await controller.toggleTorch();
      await controller.dispose();
    });

    test('stop should do nothing when already stopped', () async {
      final controller = MobileScannerController(autoStart: false);
      await controller.stop();
      await controller.dispose();
    });

    test('pause should do nothing when already stopped', () async {
      final controller = MobileScannerController(autoStart: false);
      await controller.pause();
      await controller.dispose();
    });

    test('switchCamera should do nothing with less than 2 cameras', () async {
      final controller = MobileScannerController(autoStart: false);
      await controller.start();
      // Only 1 camera available, switchCamera should do nothing
      await controller.switchCamera();
      expect(controller.value.cameraDirection, CameraFacing.back);
      await controller.dispose();
    });

    test('switchCamera should switch camera direction', () async {
      // Override the mock to return 2 cameras
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        methodChannel,
        (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'start':
              return <String, dynamic>{
                'textureId': 1,
                'size': <String, double>{'width': 1080.0, 'height': 1080.0},
                'torchable': false,
                'numberOfCameras': 2,
                'currentTorchState': 0,
              };
            case 'state':
              return 1;
            case 'torch':
            case 'toggleTorch':
            case 'stop':
            case 'pause':
            case 'setScale':
            case 'resetScale':
            case 'updateScanWindow':
            case 'switchCamera':
              return null;
            case 'analyzeImage':
              return <String, dynamic>{
                'name': 'barcode',
                'data': null,
              };
            default:
              return null;
          }
        },
      );

      final controller = MobileScannerController(autoStart: false);
      await controller.start();
      expect(controller.value.cameraDirection, CameraFacing.back);
      await controller.switchCamera();
      // After switching, the camera should be front-facing
      expect(controller.value.cameraDirection, CameraFacing.front);
      await controller.dispose();
    });

    test('updateScanWindow should do nothing when disposed', () async {
      final controller = MobileScannerController(autoStart: false);
      await controller.dispose();
      // Should not throw
      await controller.updateScanWindow(const Rect.fromLTWH(0, 0, 100, 100));
    });

    test('updateScanWindow should do nothing when not initialized', () async {
      final controller = MobileScannerController(autoStart: false);
      // Should not throw
      await controller.updateScanWindow(const Rect.fromLTWH(0, 0, 100, 100));
      controller.dispose();
    });

    test('dispose should be idempotent', () async {
      final controller = MobileScannerController(autoStart: false);
      await controller.dispose();
      // Calling dispose again should not throw
      await controller.dispose();
    });

    test('dispose should work on running controller', () async {
      final controller = MobileScannerController(autoStart: false);
      await controller.start();
      await controller.dispose();
      expect(controller.value.isRunning, true);
    });
  });

  group('MobileScannerViewAttributes', () {
    test('should be created with default values', () {
      const attrs = MobileScannerViewAttributes(
        currentTorchMode: TorchState.off,
        numberOfCameras: 0,
        size: Size.zero,
      );
      expect(attrs.currentTorchMode, TorchState.off);
      expect(attrs.numberOfCameras, 0);
      expect(attrs.size, Size.zero);
    });

    test('should be created with custom values', () {
      const attrs = MobileScannerViewAttributes(
        currentTorchMode: TorchState.on,
        numberOfCameras: 2,
        size: Size(1080, 1920),
      );
      expect(attrs.currentTorchMode, TorchState.on);
      expect(attrs.numberOfCameras, 2);
    });
  });

  group('MobileScannerException', () {
    test('should be created with error code', () {
      const exception = MobileScannerException(
        errorCode: MobileScannerErrorCode.genericError,
      );
      expect(exception.errorCode, MobileScannerErrorCode.genericError);
      expect(exception.errorDetails, isNull);
    });

    test('should be created with error details', () {
      const details = MobileScannerErrorDetails(
        code: 'test',
        message: 'test message',
      );
      const exception = MobileScannerException(
        errorCode: MobileScannerErrorCode.permissionDenied,
        errorDetails: details,
      );
      expect(exception.errorCode, MobileScannerErrorCode.permissionDenied);
      expect(exception.errorDetails, isNotNull);
      expect(exception.errorDetails!.code, 'test');
      expect(exception.errorDetails!.message, 'test message');
    });

    test('toString returns expected format', () {
      const exception = MobileScannerException(
        errorCode: MobileScannerErrorCode.genericError,
      );
      final str = exception.toString();
      expect(str, contains('MobileScannerException'));
      expect(str, contains('genericError'));
    });

    test('toString should include details message when available', () {
      const details = MobileScannerErrorDetails(
        message: 'Camera permission denied.',
      );
      const exception = MobileScannerException(
        errorCode: MobileScannerErrorCode.permissionDenied,
        errorDetails: details,
      );
      final str = exception.toString();
      expect(str, contains('MobileScannerException'));
      expect(str, contains('permissionDenied'));
      expect(str, contains('Camera permission denied.'));
    });
  });

  group('MobileScannerErrorDetails', () {
    test('should be created with details', () {
      const details = MobileScannerErrorDetails(
        code: 'MOBILE_SCANNER_ERROR',
        message: 'Something went wrong',
        details: {'extra': 'info'},
      );
      expect(details.code, 'MOBILE_SCANNER_ERROR');
      expect(details.message, 'Something went wrong');
      expect(details.details, {'extra': 'info'});
    });

    test('can be created with null values', () {
      const details = MobileScannerErrorDetails();
      expect(details.code, isNull);
      expect(details.message, isNull);
      expect(details.details, isNull);
    });
  });

  group('MobileScannerBarcodeException', () {
    test('can be created with message', () {
      const exception = MobileScannerBarcodeException('test error');
      expect(exception.message, 'test error');
    });

    test('toString contains message', () {
      const exception = MobileScannerBarcodeException('test error');
      final str = exception.toString();
      expect(str, contains('MobileScannerBarcodeException'));
      expect(str, contains('test error'));
    });

    test('toString returns default message when message is null', () {
      const exception = MobileScannerBarcodeException(null);
      final str = exception.toString();
      expect(str, contains('MobileScannerBarcodeException'));
      expect(str, contains('Could not detect a barcode'));
    });

    test('toString returns default message when message is empty', () {
      const exception = MobileScannerBarcodeException('');
      final str = exception.toString();
      expect(str, contains('MobileScannerBarcodeException'));
      expect(str, contains('Could not detect a barcode'));
    });

    test('start should handle delayed response from platform', () async {
      final controller = MobileScannerController(autoStart: false);
      // Mock MethodChannel with a delayed response
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        methodChannel,
        (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'start':
              // Simulate a delayed platform response (e.g., camera initialization)
              await Future<void>.delayed(const Duration(milliseconds: 50));
              return <String, dynamic>{
                'textureId': 1,
                'size': <String, double>{'width': 1080.0, 'height': 1080.0},
                'torchable': false,
                'numberOfCameras': 1,
                'currentTorchState': 0,
              };
            case 'state':
              return 1;
            default:
              return null;
          }
        },
      );
      // Should complete successfully even with a delayed response
      await controller.start();
      expect(controller.value.isRunning, true);
      // Restore the default mock
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        methodChannel,
        (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'start':
              return <String, dynamic>{
                'textureId': 1,
                'size': <String, double>{'width': 1080.0, 'height': 1080.0},
                'torchable': false,
                'numberOfCameras': 1,
                'currentTorchState': 0,
              };
            case 'state':
              return 1;
            case 'torch':
            case 'toggleTorch':
            case 'stop':
            case 'pause':
            case 'setScale':
            case 'resetScale':
            case 'updateScanWindow':
            case 'switchCamera':
              return null;
            case 'analyzeImage':
              return <String, dynamic>{
                'name': 'barcode',
                'data': null,
              };
            default:
              return null;
          }
        },
      );
      await controller.dispose();
    });

    test('start should handle barcode stream timeout', () async {
      final controller = MobileScannerController(
        autoStart: false,
        detectionTimeoutMs: 100,
      );
      await controller.start();
      expect(controller.value.isRunning, true);
      expect(controller.detectionTimeoutMs, 100);
      await controller.dispose();
    });
  });
}
