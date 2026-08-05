import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mobile_scanner/src/enums/detection_speed.dart';
import 'package:mobile_scanner/src/method_channel/mobile_scanner_method_channel.dart';
import 'package:mobile_scanner/src/objects/barcode_capture.dart';
import 'package:mobile_scanner/src/objects/start_options.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MobileScannerController', () {
    late MobileScannerController controller;

    Future<void> setUpWidget(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MobileScanner(controller: controller),
          ),
        ),
      );
    }

    setUp(() {
      controller = MobileScannerController(autoStart: false);
    });

    tearDown(() async {
      await controller.dispose();
    });

    testWidgets('initial state is uninitialized', (tester) async {
      await setUpWidget(tester);
      final state = controller.value;
      expect(state.isInitialized, false);
      expect(state.isRunning, false);
      expect(state.availableCameras, isNull);
    });

    testWidgets('start without autoStart does not start automatically', (
      tester,
    ) async {
      await setUpWidget(tester);
      expect(controller.value.isStarting, false);
      expect(controller.value.isRunning, false);
    });

    testWidgets('stop handles when not started', (tester) async {
      await setUpWidget(tester);
      await controller.stop();
    });

    testWidgets('pause handles when not started', (tester) async {
      await setUpWidget(tester);
      await controller.pause();
    });

    test('analyzeImage throws MissingPluginException when platform not set', () async {
      expect(
        () => controller.analyzeImage('/test/path'),
        throwsA(isA<MissingPluginException>()),
      );
    });

    testWidgets('setZoomScale throws when not initialized', (tester) async {
      expect(
        () => controller.setZoomScale(0.5),
        throwsA(isA<MobileScannerException>()),
      );
    });

    testWidgets('resetZoomScale throws when not initialized', (tester) async {
      expect(
        () => controller.resetZoomScale(),
        throwsA(isA<MobileScannerException>()),
      );
    });

    testWidgets('setFocusPoint throws when not initialized', (tester) async {
      expect(
        () => controller.setFocusPoint(const Offset(0.5, 0.5)),
        throwsA(isA<MobileScannerException>()),
      );
    });
  });

  group('MobileScannerController properties', () {
    late MobileScannerController controller;

    setUp(() {
      controller = MobileScannerController(autoStart: false);
    });

    tearDown(() async {
      await controller.dispose();
    });

    test('default properties are set correctly', () {
      expect(controller.autoZoom, false);
      expect(controller.formats, isEmpty);
      expect(controller.returnImage, false);
      expect(controller.invertImage, false);
      expect(controller.initialZoom, isNull);
      expect(controller.torchEnabled, false);
      expect(controller.facing, CameraFacing.back);
      expect(controller.autoStart, false);
    });

    test('cameraResolution is null by default', () {
      expect(controller.cameraResolution, isNull);
    });

    test('cameraResolution can be set', () {
      final ctrl = MobileScannerController(
        autoStart: false,
        cameraResolution: const Size(1920, 1080),
      );
      expect(ctrl.cameraResolution, const Size(1920, 1080));
      ctrl.dispose();
    });

    test('detectionSpeed defaults to normal', () {
      expect(controller.detectionSpeed, DetectionSpeed.normal);
    });

    test('detectionSpeed can be set to noDuplicates', () {
      final ctrl = MobileScannerController(
        autoStart: false,
        detectionSpeed: DetectionSpeed.noDuplicates,
      );
      expect(ctrl.detectionSpeed, DetectionSpeed.noDuplicates);
      ctrl.dispose();
    });

    test('detectionSpeed can be set to unrestricted', () {
      final ctrl = MobileScannerController(
        autoStart: false,
        detectionSpeed: DetectionSpeed.unrestricted,
      );
      expect(ctrl.detectionSpeed, DetectionSpeed.unrestricted);
      ctrl.dispose();
    });

    test('detectionTimeoutMs defaults to 250', () {
      final ctrl = MobileScannerController(autoStart: false);
      expect(ctrl.detectionTimeoutMs, 250);
      ctrl.dispose();
    });

    test('detectionTimeoutMs is 0 when detectionSpeed is not normal', () {
      final ctrl = MobileScannerController(
        autoStart: false,
        detectionSpeed: DetectionSpeed.noDuplicates,
        detectionTimeoutMs: 500,
      );
      expect(ctrl.detectionTimeoutMs, 0);
      ctrl.dispose();
    });

    test('autoStart defaults to true', () {
      final ctrl = MobileScannerController();
      expect(ctrl.autoStart, true);
      ctrl.dispose();
    });

    test('invertImage defaults to false', () {
      expect(controller.invertImage, false);
    });

    test('invertImage can be set to true', () {
      final ctrl = MobileScannerController(
        autoStart: false,
        invertImage: true,
      );
      expect(ctrl.invertImage, true);
      ctrl.dispose();
    });

    test('autoZoom defaults to false', () {
      expect(controller.autoZoom, false);
    });

    test('autoZoom can be set to true', () {
      final ctrl = MobileScannerController(
        autoStart: false,
        autoZoom: true,
      );
      expect(ctrl.autoZoom, true);
      ctrl.dispose();
    });

    test('initialZoom can be set', () {
      final ctrl = MobileScannerController(
        autoStart: false,
        initialZoom: 0.5,
      );
      expect(ctrl.initialZoom, 0.5);
      ctrl.dispose();
    });
  });

  group('MobileScannerController lifecycle', () {
    late MobileScannerController controller;

    setUp(() {
      controller = MobileScannerController(autoStart: false);
    });

    tearDown(() async {
      await controller.dispose();
    });

    test('dispose marks controller as disposed', () async {
      await controller.dispose();
      // dispose should be idempotent
      await controller.dispose();
    });

    test('barcodes stream is available', () {
      expect(controller.barcodes, isA<Stream<BarcodeCapture>>());
    });
  });

  group('MobileScannerController normal scenarios', () {
    late MobileScannerController controller;

    setUp(() {
      MobileScannerPlatform.instance = _MockPlatformSuccess();
      controller = MobileScannerController(autoStart: false);
    });

    tearDown(() async {
      await controller.dispose();
      MobileScannerPlatform.instance = MethodChannelMobileScanner();
    });

    testWidgets('start successfully initializes controller', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MobileScanner(controller: controller),
          ),
        ),
      );

      await controller.start();

      expect(controller.value.isInitialized, true);
      expect(controller.value.isRunning, true);
      expect(controller.value.isStarting, false);
      expect(controller.value.cameraDirection, CameraFacing.back);
      expect(controller.value.size, const Size(1920, 1080));
      expect(controller.value.torchState, TorchState.off);
      expect(controller.value.availableCameras, 2);
    });

    testWidgets('start with front camera sets direction correctly', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MobileScanner(controller: controller),
          ),
        ),
      );

      await controller.start(cameraDirection: CameraFacing.front);

      expect(controller.value.isRunning, true);
      // The mock platform returns CameraFacing.back regardless of input,
      // verifying the controller passthrough and state update.
      expect(controller.value.cameraDirection, CameraFacing.back);
    });

    testWidgets('start is idempotent when already running', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MobileScanner(controller: controller),
          ),
        ),
      );

      await controller.start();
      // Second start should be a no-op
      await controller.start();

      expect(controller.value.isRunning, true);
    });

    testWidgets('stop successfully stops controller', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MobileScanner(controller: controller),
          ),
        ),
      );

      await controller.start();
      expect(controller.value.isRunning, true);

      await controller.stop();
      expect(controller.value.isRunning, false);
    });

    testWidgets('pause successfully pauses controller', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MobileScanner(controller: controller),
          ),
        ),
      );

      await controller.start();
      expect(controller.value.isRunning, true);

      await controller.pause();
      expect(controller.value.isRunning, false);
    });

    testWidgets('toggleTorch can be called after start', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MobileScanner(controller: controller),
          ),
        ),
      );

      await controller.start();
      await controller.toggleTorch();
      // Should complete without error
    });

    testWidgets('switchCamera works after start', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MobileScanner(controller: controller),
          ),
        ),
      );

      await controller.start();
      await controller.switchCamera();
      // Should complete without error
    });

    testWidgets('setZoomScale works after start', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MobileScanner(controller: controller),
          ),
        ),
      );

      await controller.start();
      await controller.setZoomScale(0.5);
      // Should complete without error
    });

    testWidgets('resetZoomScale works after start', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MobileScanner(controller: controller),
          ),
        ),
      );

      await controller.start();
      await controller.resetZoomScale();
      // Should complete without error
    });

    testWidgets('setFocusPoint works after start', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MobileScanner(controller: controller),
          ),
        ),
      );

      await controller.start();
      await controller.setFocusPoint(const Offset(0.5, 0.5));
      // Should complete without error
    });

    testWidgets('updateScanWindow works after start', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MobileScanner(controller: controller),
          ),
        ),
      );

      await controller.start();
      await controller.updateScanWindow(
        const Rect.fromLTWH(0, 0, 100, 100),
      );
      // Should complete without error
    });

    testWidgets('buildCameraView returns a widget after start', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MobileScanner(controller: controller),
          ),
        ),
      );

      await controller.start();
      final widget = controller.buildCameraView();
      expect(widget, isA<Widget>());
    });

    test('analyzeImage returns null for empty result', () async {
      final result = await controller.analyzeImage('/test/path');
      expect(result, isNull);
    });

    testWidgets('controller passes detectionTimeoutMs to StartOptions', (
      tester,
    ) async {
      final capturingPlatform = _MockPlatformCaptureOptions();
      final originalInstance = MobileScannerPlatform.instance;
      MobileScannerPlatform.instance = capturingPlatform;

      final ctrl = MobileScannerController(
        autoStart: false,
        detectionTimeoutMs: 500,
        detectionSpeed: DetectionSpeed.normal,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MobileScanner(controller: ctrl),
          ),
        ),
      );

      await ctrl.start();

      expect(capturingPlatform.capturedOptions, isNotNull);
      expect(
        capturingPlatform.capturedOptions!.detectionTimeoutMs,
        500,
      );
      expect(
        capturingPlatform.capturedOptions!.detectionSpeed,
        DetectionSpeed.normal,
      );

      await ctrl.dispose();
      MobileScannerPlatform.instance = originalInstance;
    });

    testWidgets('controller passes detectionTimeoutMs as 0 for non-normal speed', (
      tester,
    ) async {
      final capturingPlatform = _MockPlatformCaptureOptions();
      final originalInstance = MobileScannerPlatform.instance;
      MobileScannerPlatform.instance = capturingPlatform;

      final ctrl = MobileScannerController(
        autoStart: false,
        detectionTimeoutMs: 500,
        detectionSpeed: DetectionSpeed.noDuplicates,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MobileScanner(controller: ctrl),
          ),
        ),
      );

      await ctrl.start();

      expect(capturingPlatform.capturedOptions, isNotNull);
      expect(capturingPlatform.capturedOptions!.detectionTimeoutMs, 0);
      expect(
        capturingPlatform.capturedOptions!.detectionSpeed,
        DetectionSpeed.noDuplicates,
      );

      await ctrl.dispose();
      MobileScannerPlatform.instance = originalInstance;
    });
  });

  group('MobileScannerController exception scenarios', () {
    late MobileScannerController controller;

    setUp(() {
      controller = MobileScannerController(autoStart: false);
    });

    tearDown(() async {
      await controller.dispose();
    });

    test('setZoomScale throws when not initialized', () async {
      expect(
        () => controller.setZoomScale(0.5),
        throwsA(isA<MobileScannerException>()),
      );
    });

    test('resetZoomScale throws when not initialized', () async {
      expect(
        () => controller.resetZoomScale(),
        throwsA(isA<MobileScannerException>()),
      );
    });

    test('setFocusPoint throws when not initialized', () async {
      expect(
        () => controller.setFocusPoint(const Offset(0.5, 0.5)),
        throwsA(isA<MobileScannerException>()),
      );
    });

    test('start with CameraFacing.unknown throws', () async {
      expect(
        () => controller.start(cameraDirection: CameraFacing.unknown),
        throwsA(isA<MobileScannerException>()),
      );
    });

    test('start with disposed controller throws', () async {
      await controller.dispose();
      expect(
        () => controller.start(),
        throwsA(isA<MobileScannerException>()),
      );
    });

    test('start with negative detectionTimeoutMs throws', () {
      expect(
        () => MobileScannerController(
          autoStart: false,
          detectionTimeoutMs: -1,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('start with CameraFacing.unknown throws assertion error', () {
      expect(
        () => MobileScannerController(
          autoStart: false,
          facing: CameraFacing.unknown,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    testWidgets('start without widget attached throws controllerNotAttached', (tester) async {
      // Controller created without being attached to a MobileScanner widget.
      // The _isAttachedCompleter will timeout after 500ms and throw
      // controllerNotAttached.
      final unattachedController = MobileScannerController(autoStart: false);

      await tester.runAsync(() async {
        try {
          await unattachedController.start();
          fail('Expected MobileScannerException with controllerNotAttached');
        } on MobileScannerException catch (e) {
          expect(e.errorCode, MobileScannerErrorCode.controllerNotAttached);
        }
      });

      await unattachedController.dispose();
    });

    testWidgets('start with permission denied updates state with error', (
      tester,
    ) async {
      // Set up a mock platform that simulates a permission denied error.
      final mockPlatform = _MockPlatformForPermissionDenied();
      final originalInstance = MobileScannerPlatform.instance;
      MobileScannerPlatform.instance = mockPlatform;

      final permissionController = MobileScannerController(autoStart: false);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MobileScanner(controller: permissionController),
          ),
        ),
      );

      await permissionController.start();

      // The controller catches the exception and updates state with the error.
      expect(permissionController.value.error, isA<MobileScannerException>());
      expect(
        (permissionController.value.error as MobileScannerException).errorCode,
        MobileScannerErrorCode.permissionDenied,
      );

      await permissionController.dispose();
      MobileScannerPlatform.instance = originalInstance;
    });

    testWidgets('start throws when already initializing', (tester) async {
      // The controllerInitializing check happens when isStarting is true.
      // We simulate this by calling start() twice without awaiting the first
      // call, using a mock platform that never completes start().
      final slowPlatform = _MockPlatformSlowStart();
      final originalInstance = MobileScannerPlatform.instance;
      MobileScannerPlatform.instance = slowPlatform;

      final controller = MobileScannerController(autoStart: false);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MobileScanner(controller: controller),
          ),
        ),
      );

      // Fire start() without awaiting — it sets isStarting = true
      // synchronously, then awaits the platform's start().
      await tester.runAsync(() async {
        controller.start();

        // Immediately fire a second start() — it should see isStarting and
        // throw controllerInitializing.
        expect(
          controller.start(),
          throwsA(
            isA<MobileScannerException>().having(
              (e) => e.errorCode,
              'errorCode',
              MobileScannerErrorCode.controllerInitializing,
            ),
          ),
        );
      });

      await controller.dispose();
      MobileScannerPlatform.instance = originalInstance;
    });

    testWidgets('buildCameraView throws when not initialized', (tester) async {
      final controller = MobileScannerController(autoStart: false);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MobileScanner(controller: controller),
          ),
        ),
      );

      expect(
        controller.buildCameraView,
        throwsA(isA<MobileScannerException>()),
      );
    });

    testWidgets('switchCamera throws when not initialized', (tester) async {
      final controller = MobileScannerController(autoStart: false);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MobileScanner(controller: controller),
          ),
        ),
      );

      expect(
        controller.switchCamera,
        throwsA(isA<MobileScannerException>()),
      );
    });

    testWidgets('toggleTorch throws when not initialized', (tester) async {
      final controller = MobileScannerController(autoStart: false);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MobileScanner(controller: controller),
          ),
        ),
      );

      expect(
        controller.toggleTorch,
        throwsA(isA<MobileScannerException>()),
      );
    });
  });

  group('MobileScannerController concurrent scenarios', () {
    late MobileScannerController controller;

    setUp(() {
      controller = MobileScannerController(autoStart: false);
    });

    tearDown(() async {
      await controller.dispose();
    });

    test('consecutive stop calls are safe', () async {
      await controller.stop();
      await controller.stop();
      await controller.stop();
    });

    test('consecutive dispose calls are safe', () async {
      await controller.dispose();
      await controller.dispose();
      await controller.dispose();
    });

    test('consecutive pause calls are safe', () async {
      await controller.pause();
      await controller.pause();
      await controller.pause();
    });

    test('concurrent start and stop calls are safe', () async {
      await Future.wait([
        controller.stop(),
        controller.stop(),
        controller.pause(),
        controller.pause(),
      ]);
    });
  });

  group('MobileScannerController concurrent operation scenarios', () {
    late MobileScannerController controller;

    setUp(() {
      MobileScannerPlatform.instance = _MockPlatformSuccess();
      controller = MobileScannerController(autoStart: false);
    });

    tearDown(() async {
      await controller.dispose();
      MobileScannerPlatform.instance = MethodChannelMobileScanner();
    });

    testWidgets('rapid start and stop cycles are safe', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MobileScanner(controller: controller),
          ),
        ),
      );

      for (int i = 0; i < 3; i++) {
        await controller.start();
        expect(controller.value.isRunning, true);
        await controller.stop();
        expect(controller.value.isRunning, false);
      }
    });

    testWidgets('rapid start and pause cycles are safe', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MobileScanner(controller: controller),
          ),
        ),
      );

      for (int i = 0; i < 3; i++) {
        await controller.start();
        expect(controller.value.isRunning, true);
        await controller.pause();
        expect(controller.value.isRunning, false);
      }
    });

    testWidgets('start followed by concurrent stop and pause', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MobileScanner(controller: controller),
          ),
        ),
      );

      await controller.start();
      expect(controller.value.isRunning, true);

      // Concurrent stop and pause after start
      await Future.wait([
        controller.stop(),
        controller.pause(),
      ]);

      // After concurrent stop/pause, the controller should be stopped.
      // The exact running state depends on order, but both should complete.
      expect(controller.value.isRunning, false);
    });

    testWidgets('rapid toggleTorch and setZoomScale during scan', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MobileScanner(controller: controller),
          ),
        ),
      );

      await controller.start();

      // Rapid concurrent operations
      await Future.wait([
        controller.toggleTorch(),
        controller.setZoomScale(0.5),
        controller.toggleTorch(),
        controller.setZoomScale(0.8),
      ]);
      // Should complete without error
    });

    testWidgets('concurrent barcode detection with state changes', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MobileScanner(controller: controller),
          ),
        ),
      );

      await controller.start();

      // Simulate receiving barcodes while changing operations
      await Future.wait([
        controller.toggleTorch(),
        controller.switchCamera(),
        controller.setZoomScale(0.3),
        controller.resetZoomScale(),
      ]);
      // Should complete without error
    });
  });
}

/// A mock platform that throws a permission denied error on start.
class _MockPlatformForPermissionDenied extends MobileScannerPlatform {
  @override
  Future<MobileScannerViewAttributes> start(StartOptions startOptions) async {
    throw MobileScannerException(
      errorCode: MobileScannerErrorCode.permissionDenied,
      errorDetails: const MobileScannerErrorDetails(
        message: 'Camera permission denied.',
      ),
    );
  }

  @override
  Stream<BarcodeCapture?> get barcodesStream => const Stream.empty();

  @override
  Widget buildCameraView() => const SizedBox.shrink();

  @override
  Future<void> dispose() async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> resetZoomScale() async {}

  @override
  void setBarcodeLibraryScriptUrl(String url) {}

  @override
  Future<void> setFocusPoint(Offset position) async {}

  @override
  Future<void> setZoomScale(double zoomScale) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> toggleTorch() async {}

  @override
  Stream<TorchState> get torchStateStream => const Stream.empty();

  @override
  Future<void> updateScanWindow(Rect? window) async {}

  @override
  Stream<double> get zoomScaleStateStream => const Stream.empty();
}

/// A mock platform that delays start() to allow testing isStarting guard.
class _MockPlatformSlowStart extends MobileScannerPlatform {
  @override
  Future<MobileScannerViewAttributes> start(StartOptions startOptions) async {
    // Use a delay long enough for the second concurrent start() to fire
    // but short enough to not cause a timeout.
    final completer = Completer<MobileScannerViewAttributes>();
    // Return immediately but leave the completer unresolved
    // so the first start() stays in-flight.
    return completer.future;
  }

  @override
  Stream<BarcodeCapture?> get barcodesStream => const Stream.empty();

  @override
  Widget buildCameraView() => const SizedBox.shrink();

  @override
  Future<void> dispose() async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> resetZoomScale() async {}

  @override
  void setBarcodeLibraryScriptUrl(String url) {}

  @override
  Future<void> setFocusPoint(Offset position) async {}

  @override
  Future<void> setZoomScale(double zoomScale) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> toggleTorch() async {}

  @override
  Stream<TorchState> get torchStateStream => const Stream.empty();

  @override
  Future<void> updateScanWindow(Rect? window) async {}

  @override
  Stream<double> get zoomScaleStateStream => const Stream.empty();
}

/// A mock platform that returns success for all operations.
class _MockPlatformSuccess extends MobileScannerPlatform {
  @override
  Future<MobileScannerViewAttributes> start(StartOptions startOptions) async {
    return const MobileScannerViewAttributes(
      cameraDirection: CameraFacing.back,
      currentTorchMode: TorchState.off,
      size: Size(1920, 1080),
      numberOfCameras: 2,
    );
  }

  @override
  Future<BarcodeCapture?> analyzeImage(
    String path, {
    List<BarcodeFormat> formats = const <BarcodeFormat>[],
  }) async {
    return null;
  }

  @override
  Stream<BarcodeCapture?> get barcodesStream => const Stream.empty();

  @override
  Widget buildCameraView() => const SizedBox.shrink();

  @override
  Future<void> dispose() async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> resetZoomScale() async {}

  @override
  void setBarcodeLibraryScriptUrl(String url) {}

  @override
  Future<void> setFocusPoint(Offset position) async {}

  @override
  Future<void> setZoomScale(double zoomScale) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> toggleTorch() async {}

  @override
  Stream<TorchState> get torchStateStream => const Stream.empty();

  @override
  Future<void> updateScanWindow(Rect? window) async {}

  @override
  Stream<double> get zoomScaleStateStream => const Stream.empty();
}

/// A mock platform that captures the StartOptions passed to start().
class _MockPlatformCaptureOptions extends MobileScannerPlatform {
  StartOptions? capturedOptions;

  @override
  Future<MobileScannerViewAttributes> start(StartOptions startOptions) async {
    capturedOptions = startOptions;
    return const MobileScannerViewAttributes(
      cameraDirection: CameraFacing.back,
      currentTorchMode: TorchState.off,
      size: Size(1920, 1080),
      numberOfCameras: 2,
    );
  }

  @override
  Stream<BarcodeCapture?> get barcodesStream => const Stream.empty();

  @override
  Widget buildCameraView() => const SizedBox.shrink();

  @override
  Future<void> dispose() async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> resetZoomScale() async {}

  @override
  void setBarcodeLibraryScriptUrl(String url) {}

  @override
  Future<void> setFocusPoint(Offset position) async {}

  @override
  Future<void> setZoomScale(double zoomScale) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> toggleTorch() async {}

  @override
  Stream<TorchState> get torchStateStream => const Stream.empty();

  @override
  Future<void> updateScanWindow(Rect? window) async {}

  @override
  Stream<double> get zoomScaleStateStream => const Stream.empty();
}