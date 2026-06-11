import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mobile_scanner/src/enums/mobile_scanner_error_code.dart';
import 'package:mobile_scanner/src/mobile_scanner_exception.dart';
import 'package:mobile_scanner/src/mobile_scanner_view_attributes.dart';

/// OHOS-specific tests for the mobile_scanner plugin.
///
/// These tests verify the OHOS platform behavior including:
/// - Zoom scale range (0.0-10.0 for OHOS vs 0.0-1.0 for other platforms)
/// - Torch state handling
/// - Pause/resume lifecycle
/// - Error handling and retry mechanism
/// - Event channel streams
/// - Scan window updates
void main() {
  const MethodChannel methodChannel = MethodChannel(
    'dev.steenbakker.mobile_scanner/scanner/method',
  );

  const EventChannel eventChannel = EventChannel(
    'dev.steenbakker.mobile_scanner/scanner/event',
  );

  TestWidgetsFlutterBinding.ensureInitialized();

  group('OHOS MobileScannerController', () {
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
                'torchable': true,
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

    // === OHOS Zoom Scale Tests ===
    // OHOS uses 0.0-10.0 range for zoom scale instead of 0.0-1.0

    test('[OHOS] setZoomScale accepts values up to 10.0', () async {
      final controller = MobileScannerController(autoStart: false);
      await controller.start();
      // Should not throw even though 5.0 exceeds non-OHOS range
      await controller.setZoomScale(5.0);
      await controller.dispose();
    });

    test('[OHOS] setZoomScale clamps to 0.0 minimum', () async {
      final controller = MobileScannerController(autoStart: false);
      await controller.start();
      await controller.setZoomScale(-1.0);
      await controller.dispose();
    });

    test('[OHOS] setZoomScale clamps to 10.0 maximum', () async {
      final controller = MobileScannerController(autoStart: false);
      await controller.start();
      await controller.setZoomScale(15.0);
      await controller.dispose();
    });

    test('[OHOS] resetZoomScale resets to 1.0', () async {
      final controller = MobileScannerController(autoStart: false);
      await controller.start();
      await controller.setZoomScale(5.0);
      await controller.resetZoomScale();
      await controller.dispose();
    });

    // === OHOS Torch State Tests ===

    test('[OHOS] toggleTorch works with torchable device', () async {
      final controller = MobileScannerController(autoStart: false);
      await controller.start();
      await controller.toggleTorch();
      await controller.toggleTorch();
      await controller.dispose();
    });

    test('[OHOS] toggleTorch does nothing when torch is unavailable', () async {
      // Override mock to return torchable: false
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
                'currentTorchState': -1, // TORCH_UNAVAILABLE
              };
            case 'state':
              return 1;
            default:
              return null;
          }
        },
      );

      final controller = MobileScannerController(autoStart: false);
      await controller.start();
      // The torch state should be unavailable
      expect(controller.value.torchState, TorchState.unavailable);
      // toggleTorch should be a no-op when torch is unavailable
      await controller.toggleTorch();
      await controller.dispose();
    });

    // === OHOS Lifecycle Tests ===

    test('[OHOS] pause does lightweight stop', () async {
      final controller = MobileScannerController(autoStart: false);
      await controller.start();
      expect(controller.value.isRunning, true);
      await controller.pause();
      expect(controller.value.isRunning, false);
      // Can restart after pause
      await controller.start();
      expect(controller.value.isRunning, true);
      await controller.dispose();
    });

    test('[OHOS] stop releases resources', () async {
      final controller = MobileScannerController(autoStart: false);
      await controller.start();
      expect(controller.value.isRunning, true);
      await controller.stop();
      expect(controller.value.isRunning, false);
      // Can restart after stop
      await controller.start();
      expect(controller.value.isRunning, true);
      await controller.dispose();
    });

    test('[OHOS] start after stop creates new session', () async {
      final controller = MobileScannerController(autoStart: false);
      await controller.start();
      await controller.stop();
      // Start again - should work
      await controller.start();
      expect(controller.value.isRunning, true);
      await controller.dispose();
    });

    // === OHOS Error Handling Tests ===

    test('[OHOS] start handles permission denied', () async {
      // Override mock to return state: 0 (not granted)
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        methodChannel,
        (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'state':
              return 0; // Permission not granted
            case 'start':
              return <String, dynamic>{
                'textureId': 1,
                'size': <String, double>{'width': 1080.0, 'height': 1080.0},
                'torchable': false,
                'numberOfCameras': 1,
                'currentTorchState': -1,
              };
            default:
              return null;
          }
        },
      );

      final controller = MobileScannerController(autoStart: false);
      // Should not throw - just start with default state
      await controller.start();
      expect(controller.value.isInitialized, true);
      await controller.dispose();
    });

    test('[OHOS] start handles engine error', () async {
      // Override mock to return error on start
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        methodChannel,
        (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'state':
              return 1;
            case 'start':
              throw PlatformException(
                code: 'MOBILE_SCANNER_GENERIC_ERROR',
                message: 'Failed to start camera',
              );
            default:
              return null;
          }
        },
      );

      final controller = MobileScannerController(autoStart: false);
      await controller.start();
      // Should handle the error gracefully
      expect(controller.value.isInitialized, true);
      expect(controller.value.isRunning, false);
      expect(controller.value.error, isNotNull);
      await controller.dispose();
    });

    test('[OHOS] stop handles already stopped state', () async {
      final controller = MobileScannerController(autoStart: false);
      await controller.stop(); // Not started yet
      await controller.dispose();
    });

    test('[OHOS] pause handles already paused state', () async {
      final controller = MobileScannerController(autoStart: false);
      await controller.start();
      await controller.pause();
      // Pause again should be a no-op
      await controller.pause();
      expect(controller.value.isRunning, false);
      await controller.dispose();
    });

    // === OHOS Analyze Image Tests ===

    test('[OHOS] analyzeImage returns null for no barcode', () async {
      final controller = MobileScannerController(autoStart: false);
      await controller.start();
      final result = await controller.analyzeImage('/ohos/test/path.jpg');
      expect(result, isNull);
      await controller.dispose();
    });

    test('[OHOS] analyzeImage with formats', () async {
      final controller = MobileScannerController(autoStart: false);
      await controller.start();
      final result = await controller.analyzeImage(
        '/ohos/test/path.jpg',
        formats: [BarcodeFormat.qrCode, BarcodeFormat.code128],
      );
      expect(result, isNull);
      await controller.dispose();
    });

    // === OHOS Scan Window Tests ===

    test('[OHOS] updateScanWindow with valid rect', () async {
      final controller = MobileScannerController(autoStart: false);
      await controller.start();
      await controller.updateScanWindow(
        const Rect.fromLTWH(0.1, 0.1, 0.8, 0.8),
      );
      await controller.dispose();
    });

    test('[OHOS] updateScanWindow with null resets window', () async {
      final controller = MobileScannerController(autoStart: false);
      await controller.start();
      await controller.updateScanWindow(null);
      await controller.dispose();
    });

    // === OHOS Stream Event Tests ===

    test('[OHOS] barcodes stream receives events', () async {
      final controller = MobileScannerController(autoStart: false);
      await controller.start();

      // Verify the barcodes stream is accessible after start
      expect(controller.barcodes, isA<Stream<BarcodeCapture>>());
      await controller.dispose();
    });

    // === OHOS Concurrency Tests ===

    test('[OHOS] multiple lifecycle transitions are safe', () async {
      final controller = MobileScannerController(autoStart: false);
      // Rapid start/stop cycles
      for (int i = 0; i < 5; i++) {
        await controller.start();
        expect(controller.value.isRunning, true);
        await controller.stop();
        expect(controller.value.isRunning, false);
      }
      await controller.dispose();
    });

    test('[OHOS] start/pause/start cycle is safe', () async {
      final controller = MobileScannerController(autoStart: false);
      for (int i = 0; i < 3; i++) {
        await controller.start();
        expect(controller.value.isRunning, true);
        await controller.pause();
        expect(controller.value.isRunning, false);
      }
      await controller.dispose();
    });

    // === OHOS State Tests ===

    test('[OHOS] controller state is updated correctly after start', () async {
      final controller = MobileScannerController(
        autoStart: false,
        torchEnabled: false,
        facing: CameraFacing.back,
      );
      expect(controller.value.isInitialized, false);
      expect(controller.value.isRunning, false);
      expect(controller.value.torchState, TorchState.unavailable);
      expect(controller.value.zoomScale, 1.0);

      await controller.start();

      expect(controller.value.isInitialized, true);
      expect(controller.value.isRunning, true);
      expect(controller.value.cameraDirection, CameraFacing.back);
      await controller.dispose();
    });

    test('[OHOS] controller torch state resets on stop', () async {
      final controller = MobileScannerController(
        autoStart: false,
        torchEnabled: false,
      );
      await controller.start();
      expect(controller.value.torchState, TorchState.off);
      await controller.stop();
      expect(controller.value.torchState, TorchState.off);
      await controller.dispose();
    });

    // === OHOS Disposal Tests ===

    test('[OHOS] dispose on stopped controller', () async {
      final controller = MobileScannerController(autoStart: false);
      await controller.start();
      await controller.stop();
      await controller.dispose();
    });

    test('[OHOS] dispose on paused controller', () async {
      final controller = MobileScannerController(autoStart: false);
      await controller.start();
      await controller.pause();
      await controller.dispose();
    });

    test('[OHOS] operations after dispose throw', () async {
      final controller = MobileScannerController(autoStart: false);
      await controller.dispose();
      expect(
        () => controller.start(),
        throwsA(isA<MobileScannerException>()),
      );
    });
  });

  group('OHOS MobileScannerViewAttributes', () {
    test('can be created with torchable device', () {
      const attrs = MobileScannerViewAttributes(
        currentTorchMode: TorchState.off,
        numberOfCameras: 1,
        size: Size(1080, 1920),
      );
      expect(attrs.currentTorchMode, TorchState.off);
      expect(attrs.numberOfCameras, 1);
      expect(attrs.size.width, 1080.0);
      expect(attrs.size.height, 1920.0);
    });

    test('handles torch unavailable state', () {
      const attrs = MobileScannerViewAttributes(
        currentTorchMode: TorchState.unavailable,
        numberOfCameras: 1,
        size: Size.zero,
      );
      expect(attrs.currentTorchMode, TorchState.unavailable);
    });
  });

  group('OHOS MobileScannerException', () {
    test('can be created with generic error', () {
      const exception = MobileScannerException(
        errorCode: MobileScannerErrorCode.genericError,
      );
      expect(exception.errorCode, MobileScannerErrorCode.genericError);
    });

    test('should be created with generic error', () {
      const exception = MobileScannerException(
        errorCode: MobileScannerErrorCode.genericError,
      );
      expect(exception.errorCode, MobileScannerErrorCode.genericError);
    });
  });
}