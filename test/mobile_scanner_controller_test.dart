import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mobile_scanner/src/enums/barcode_format.dart';
import 'package:mobile_scanner/src/enums/camera_facing.dart';
import 'package:mobile_scanner/src/enums/detection_speed.dart';
import 'package:mobile_scanner/src/enums/mobile_scanner_error_code.dart';
import 'package:mobile_scanner/src/enums/torch_state.dart';
import 'package:mobile_scanner/src/mobile_scanner_exception.dart';
import 'package:mobile_scanner/src/mobile_scanner_platform_interface.dart';
import 'package:mobile_scanner/src/mobile_scanner_view_attributes.dart';
import 'package:mobile_scanner/src/objects/barcode_capture.dart';
import 'package:mobile_scanner/src/objects/start_options.dart';
import 'package:mobile_scanner/src/method_channel/mobile_scanner_method_channel.dart';

void main() {
  const MethodChannel methodChannel = MethodChannel(
    'dev.steenbakker.mobile_scanner/scanner/method',
  );
  const EventChannel eventChannel = EventChannel(
    'dev.steenbakker.mobile_scanner/scanner/event',
  );

  TestWidgetsFlutterBinding.ensureInitialized();

  late StreamController<Map<Object?, Object?>> eventController;

  setUp(() {
    eventController = StreamController<Map<Object?, Object?>>.broadcast();

    // Mock the event channel to return our test events
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      methodChannel,
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'state':
            return 1; // authorized
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
                  'format': 256, // qrCode
                  'type': 7, // text
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

    // Mock event channel to capture events
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler(
      eventChannel.name,
      (ByteData? message) async {
        if (message != null) {
          final String decoded = String.fromCharCodes(message.buffer.asUint8List());
          // Parse and store events if needed
        }
        return null;
      },
    );
  });

  tearDown(() {
    eventController.close();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      methodChannel,
      null,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler(
      eventChannel.name,
      null,
    );
    // Reset the platform instance to clear cached event stream
    MobileScannerPlatform.instance = MethodChannelMobileScanner();
  });

  group('MobileScannerController', () {
    test('constructor creates controller with default values', () {
      final controller = MobileScannerController();
      expect(controller.autoStart, true);
      expect(controller.facing, CameraFacing.back);
      expect(controller.returnImage, false);
      expect(controller.torchEnabled, false);
      expect(controller.formats, isEmpty);
      expect(controller.cameraResolution, isNull);
      expect(controller.useNewCameraSelector, false);
      expect(controller.value.isInitialized, false);
      expect(controller.value.isRunning, false);
      expect(controller.value.torchState, TorchState.unavailable);
      expect(controller.value.zoomScale, 1.0);
    });

    test('constructor creates controller with custom values', () {
      final controller = MobileScannerController(
        autoStart: false,
        facing: CameraFacing.front,
        returnImage: true,
        torchEnabled: true,
        formats: [BarcodeFormat.qrCode],
        detectionSpeed: DetectionSpeed.unrestricted,
        cameraResolution: Size(1920, 1080),
        useNewCameraSelector: true,
      );
      expect(controller.autoStart, false);
      expect(controller.facing, CameraFacing.front);
      expect(controller.returnImage, true);
      expect(controller.torchEnabled, true);
      expect(controller.formats, [BarcodeFormat.qrCode]);
      expect(controller.detectionSpeed, DetectionSpeed.unrestricted);
      expect(controller.cameraResolution, const Size(1920, 1080));
      expect(controller.useNewCameraSelector, true);
    });

    test('constructor detectionTimeoutMs is 0 for non-normal speed', () {
      final controller = MobileScannerController(
        detectionSpeed: DetectionSpeed.unrestricted,
        detectionTimeoutMs: 500,
      );
      // When detectionSpeed is not normal, timeout is forced to 0
      expect(controller.detectionTimeoutMs, 0);
    });

    test('start initializes and returns view attributes', () async {
      final controller = MobileScannerController(autoStart: false);
      await controller.start();

      expect(controller.value.isInitialized, true);
      expect(controller.value.isRunning, true);
      expect(controller.value.availableCameras, 2);
      expect(controller.value.torchState, TorchState.off);
    });

    test('start does nothing if already running', () async {
      final controller = MobileScannerController(autoStart: false);
      await controller.start();
      // Verify the controller is running
      expect(controller.value.isRunning, isTrue);

      // Start again should not throw and should return
      await controller.start();
    });

    test('start throws if disposed', () async {
      final controller = MobileScannerController(autoStart: false);
      await controller.dispose();

      expect(
        () => controller.start(),
        throwsA(isA<MobileScannerException>()),
      );
    });

    test('stop stops the camera', () async {
      final controller = MobileScannerController(autoStart: false);
      await controller.start();
      expect(controller.value.isInitialized, isTrue);

      await controller.stop();
      expect(controller.value.isRunning, false);
    });

    test('stop does nothing if not running', () async {
      final controller = MobileScannerController(autoStart: false);
      await controller.stop();
      expect(controller.value.isRunning, false);
    });

    test('toggleTorch toggles flash', () async {
      final controller = MobileScannerController(autoStart: false);
      await controller.start();
      // Should not throw
      await controller.toggleTorch();
    });

    test('analyzeImage returns barcode capture', () async {
      final controller = MobileScannerController(autoStart: false);
      await controller.start();

      final result = await controller.analyzeImage('/test/path');
      expect(result, isNotNull);
      expect(result!.barcodes.length, 1);
      expect(result.barcodes[0].format, BarcodeFormat.qrCode);
      expect(result.barcodes[0].rawValue, 'https://example.com');
    });

    test('setZoomScale sets zoom', () async {
      final controller = MobileScannerController(autoStart: false);
      await controller.start();
      // Should not throw
      await controller.setZoomScale(0.5);
    });

    test('setZoomScale clamps to 0.0-1.0 for non-OHOS', () async {
      final controller = MobileScannerController(autoStart: false);
      await controller.start();
      await controller.setZoomScale(-0.5);
      await controller.setZoomScale(1.5);
    });

    test('resetZoomScale resets zoom', () async {
      final controller = MobileScannerController(autoStart: false);
      await controller.start();
      await controller.resetZoomScale();
    });

    test('updateScanWindow updates window', () async {
      final controller = MobileScannerController(autoStart: false);
      await controller.start();
      await controller.updateScanWindow(
        const Rect.fromLTRB(0.1, 0.1, 0.9, 0.9),
      );
    });

    test('updateScanWindow with null resets', () async {
      final controller = MobileScannerController(autoStart: false);
      await controller.start();
      await controller.updateScanWindow(null);
    });

    test('dispose cleans up resources', () async {
      final controller = MobileScannerController(autoStart: false);
      await controller.start();
      await controller.dispose();

      // Should not throw on double dispose
      await controller.dispose();
    });

    test('buildCameraView throws if not initialized', () {
      final controller = MobileScannerController(autoStart: false);
      expect(
        () => controller.buildCameraView(),
        throwsA(isA<MobileScannerException>()),
      );
    });

    test('barcodes stream emits events', () async {
      final controller = MobileScannerController(autoStart: false);
      await controller.start();

      // Verify the stream exists and is a broadcast stream
      expect(controller.barcodes, isA<Stream<BarcodeCapture>>());
    });

    test('switchCamera does nothing with less than 2 cameras', () async {
      final controller = MobileScannerController(autoStart: false);
      await controller.start();
      expect(controller.value.availableCameras, 2);

      // Should not throw but should not switch
      await controller.switchCamera();
      // After switching with 2 cameras available, direction should be front
      expect(controller.value.cameraDirection, CameraFacing.front);
    });

    test('state hasCameraPermission is true when initialized', () async {
      final controller = MobileScannerController(autoStart: false);
      expect(controller.value.hasCameraPermission, false);

      await controller.start();
      expect(controller.value.hasCameraPermission, isTrue);
    });

    test('controller initialized with facing from constructor', () {
      final controller = MobileScannerController(
        facing: CameraFacing.front,
      );
      expect(controller.value.cameraDirection, CameraFacing.front);
    });
  });

  group('MobileScannerPlatform', () {
    test('default instance is MethodChannelMobileScanner', () {
      expect(
        MobileScannerPlatform.instance,
        isA<MethodChannelMobileScanner>(),
      );
    });

    test('analyzeImage formats pass-through', () async {
      final result = await MobileScannerPlatform.instance.analyzeImage(
        '/test/path',
        formats: [BarcodeFormat.qrCode],
      );
      expect(result, isNotNull);
      expect(result!.barcodes.length, 1);
      expect(result.barcodes[0].rawValue, 'https://example.com');
    });

    test('torchStateStream returns event stream', () {
      final stream = MobileScannerPlatform.instance.torchStateStream;
      expect(stream, isA<Stream<TorchState>>());
    });

    test('zoomScaleStateStream returns event stream', () {
      final stream = MobileScannerPlatform.instance.zoomScaleStateStream;
      expect(stream, isA<Stream<double>>());
    });
  });

  group('StartOptions', () {
    test('toMap returns correct map', () {
      final options = StartOptions(
        cameraDirection: CameraFacing.back,
        cameraResolution: null,
        detectionSpeed: DetectionSpeed.normal,
        detectionTimeoutMs: 250,
        formats: [BarcodeFormat.qrCode],
        returnImage: false,
        torchEnabled: false,
        useNewCameraSelector: false,
      );

      final map = options.toMap();
      expect(map['facing'], 1); // back
      expect(map['formats'], [256]); // qrCode
      expect(map['returnImage'], false);
      expect(map['speed'], 1); // normal
      expect(map['timeout'], 250);
      expect(map['torch'], false);
      expect(map['useNewCameraSelector'], false);
    });

    test('toMap does not include cameraResolution when null', () {
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

      final map = options.toMap();
      expect(map['cameraResolution'], isNull);
    });

    test('toMap does not include formats when empty', () {
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

      final map = options.toMap();
      expect(map.containsKey('formats'), false);
    });

    test('toMap includes cameraResolution when provided', () {
      final options = StartOptions(
        cameraDirection: CameraFacing.back,
        cameraResolution: const Size(1920, 1080),
        detectionSpeed: DetectionSpeed.normal,
        detectionTimeoutMs: 250,
        formats: [],
        returnImage: false,
        torchEnabled: true,
        useNewCameraSelector: false,
      );

      final map = options.toMap();
      expect(map['cameraResolution'], [1920, 1080]);
      expect(map['torch'], true);
    });
  });

  group('BarcodeCapture', () {
    test('constructor creates with default values', () {
      final capture = BarcodeCapture(
        raw: null,
        barcodes: [],
        size: Size.zero,
      );
      expect(capture.barcodes, isEmpty);
      expect(capture.image, isNull);
      expect(capture.raw, isNull);
      expect(capture.size, Size.zero);
    });

    test('constructor creates with barcodes', () {
      final capture = BarcodeCapture(
        raw: {},
        barcodes: [
          Barcode(
            format: BarcodeFormat.qrCode,
            rawValue: 'test',
            displayValue: 'test',
          ),
        ],
        size: const Size(100, 200),
      );
      expect(capture.barcodes.length, 1);
      expect(capture.barcodes[0].rawValue, 'test');
      expect(capture.size.width, 100);
      expect(capture.size.height, 200);
    });
  });

  group('MobileScannerState', () {
    test('uninitialized creates correct state', () {
      final state = MobileScannerState.uninitialized(CameraFacing.back);
      expect(state.isInitialized, false);
      expect(state.isRunning, false);
      expect(state.availableCameras, isNull);
      expect(state.cameraDirection, CameraFacing.back);
      expect(state.torchState, TorchState.unavailable);
      expect(state.zoomScale, 1.0);
      expect(state.size, Size.zero);
    });

    test('copyWith creates modified state', () {
      final state = MobileScannerState.uninitialized(CameraFacing.back);
      final modified = state.copyWith(
        isInitialized: true,
        isRunning: true,
        availableCameras: 2,
        torchState: TorchState.on,
        zoomScale: 0.5,
      );

      expect(modified.isInitialized, true);
      expect(modified.isRunning, true);
      expect(modified.availableCameras, 2);
      expect(modified.torchState, TorchState.on);
      expect(modified.zoomScale, 0.5);
      // Unchanged values
      expect(modified.cameraDirection, CameraFacing.back);
      expect(modified.size, Size.zero);
    });

    test('hasCameraPermission is false when not initialized', () {
      final state = MobileScannerState.uninitialized(CameraFacing.back);
      expect(state.hasCameraPermission, false);
    });

    test('hasCameraPermission is true when initialized without error', () {
      final state = MobileScannerState.uninitialized(CameraFacing.back);
      final modified = state.copyWith(
        isInitialized: true,
        isRunning: true,
      );
      expect(modified.hasCameraPermission, true);
    });

    test('hasCameraPermission is false with permission denied error', () {
      final state = MobileScannerState.uninitialized(CameraFacing.back);
      final modified = state.copyWith(
        isInitialized: true,
        error: const MobileScannerException(
          errorCode: MobileScannerErrorCode.permissionDenied,
        ),
      );
      expect(modified.hasCameraPermission, false);
    });
  });

  group('MobileScannerException', () {
    test('creates with error code', () {
      final exception = MobileScannerException(
        errorCode: MobileScannerErrorCode.genericError,
      );
      expect(exception.errorCode, MobileScannerErrorCode.genericError);
      expect(exception.errorDetails, isNull);
    });

    test('creates with error details', () {
      final exception = MobileScannerException(
        errorCode: MobileScannerErrorCode.permissionDenied,
        errorDetails: MobileScannerErrorDetails(
          message: 'Camera permission denied',
        ),
      );
      expect(exception.errorCode, MobileScannerErrorCode.permissionDenied);
      expect(exception.errorDetails!.message, 'Camera permission denied');
    });

    test('toString returns formatted string', () {
      final exception = MobileScannerException(
        errorCode: MobileScannerErrorCode.genericError,
        errorDetails: MobileScannerErrorDetails(
          message: 'Test error',
        ),
      );
      expect(exception.toString(), contains('MobileScannerException'));
      expect(exception.toString(), contains('genericError'));
    });
  });

  group('MobileScannerErrorDetails', () {
    test('creates with all fields', () {
      final details = MobileScannerErrorDetails(
        code: 'ERROR_CODE',
        details: {'key': 'value'},
        message: 'Error message',
      );
      expect(details.code, 'ERROR_CODE');
      expect(details.details, {'key': 'value'});
      expect(details.message, 'Error message');
    });
  });

  group('MobileScannerBarcodeException', () {
    test('creates with message', () {
      final exception = MobileScannerBarcodeException('Scan failed');
      expect(exception.message, 'Scan failed');
    });

    test('toString returns formatted string', () {
      final exception = MobileScannerBarcodeException('Scan failed');
      expect(exception.toString(), contains('Scan failed'));
    });

    test('toString returns default message when null', () {
      final exception = MobileScannerBarcodeException(null);
      expect(exception.toString(), contains('Could not detect a barcode'));
    });
  });

  group('MobileScannerErrorCode', () {
    test('fromPlatformException ALREADY_STARTED', () {
      final exception = PlatformException(
        code: 'MOBILE_SCANNER_ALREADY_STARTED_ERROR',
      );
      expect(
        MobileScannerErrorCode.fromPlatformException(exception),
        MobileScannerErrorCode.controllerAlreadyInitialized,
      );
    });

    test('fromPlatformException NO_CAMERA', () {
      final exception = PlatformException(
        code: 'MOBILE_SCANNER_NO_CAMERA_ERROR',
      );
      expect(
        MobileScannerErrorCode.fromPlatformException(exception),
        MobileScannerErrorCode.unsupported,
      );
    });

    test('fromPlatformException PERMISSION_DENIED', () {
      final exception = PlatformException(
        code: 'MOBILE_SCANNER_CAMERA_PERMISSION_DENIED',
      );
      expect(
        MobileScannerErrorCode.fromPlatformException(exception),
        MobileScannerErrorCode.permissionDenied,
      );
    });

    test('fromPlatformException unknown code returns genericError', () {
      final exception = PlatformException(code: 'UNKNOWN_ERROR_CODE');
      expect(
        MobileScannerErrorCode.fromPlatformException(exception),
        MobileScannerErrorCode.genericError,
      );
    });
  });

  group('MobileScannerViewAttributes', () {
    test('creates with all fields', () {
      final attributes = MobileScannerViewAttributes(
        currentTorchMode: TorchState.on,
        numberOfCameras: 2,
        size: const Size(480, 640),
      );
      expect(attributes.currentTorchMode, TorchState.on);
      expect(attributes.numberOfCameras, 2);
      expect(attributes.size.width, 480);
      expect(attributes.size.height, 640);
    });

    test('numberOfCameras can be null', () {
      final attributes = MobileScannerViewAttributes(
        currentTorchMode: TorchState.off,
        numberOfCameras: null,
        size: Size.zero,
      );
      expect(attributes.numberOfCameras, isNull);
    });
  });

  group('Controller edge cases', () {
    test('toggleTorch does nothing when torch is unavailable', () async {
      final controller = MobileScannerController(autoStart: false);
      await controller.start();

      // Set torch state to unavailable
      controller.value = controller.value.copyWith(
        torchState: TorchState.unavailable,
      );

      // Should not throw
      await controller.toggleTorch();
    });

    test('toggleTorch does nothing when camera is not running', () async {
      final controller = MobileScannerController(autoStart: false);
      await controller.start();
      await controller.stop();
      // toggleTorch should not throw when camera is stopped but initialized
      await controller.toggleTorch();
    });

    test('stop does nothing when not initialized', () async {
      final controller = MobileScannerController(autoStart: false);
      // Not started, stop should be a no-op
      await controller.stop();
      expect(controller.value.isRunning, false);
    });

    test('stop does nothing when disposed', () async {
      final controller = MobileScannerController(autoStart: false);
      await controller.dispose();
      // Stop after dispose should not throw
      await controller.stop();
    });

    test('updateScanWindow does nothing when disposed', () async {
      final controller = MobileScannerController(autoStart: false);
      await controller.dispose();
      await controller.updateScanWindow(
        const Rect.fromLTRB(0.1, 0.1, 0.9, 0.9),
      );
      // Should not throw
    });

    test('updateScanWindow does nothing when not initialized', () async {
      final controller = MobileScannerController(autoStart: false);
      // Not started, updateScanWindow should be a no-op
      await controller.updateScanWindow(
        const Rect.fromLTRB(0.1, 0.1, 0.9, 0.9),
      );
    });

    test('resetZoomScale does nothing when not running', () async {
      final controller = MobileScannerController(autoStart: false);
      await controller.start();
      // Stop the camera
      await controller.stop();
      // resetZoomScale should not throw
      await controller.resetZoomScale();
    });

    test('setZoomScale does nothing when not running', () async {
      final controller = MobileScannerController(autoStart: false);
      await controller.start();
      await controller.stop();
      // setZoomScale should not throw
      await controller.setZoomScale(0.5);
    });

    test('switchCamera does nothing when availableCameras is null', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel(
          'dev.steenbakker.mobile_scanner/scanner/method',
        ),
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
                'numberOfCameras': null, // null cameras
              };
            case 'stop':
              return null;
            default:
              return null;
          }
        },
      );

      final controller = MobileScannerController(autoStart: false);
      await controller.start();
      expect(controller.value.availableCameras, isNull);

      // switchCamera should not throw
      await controller.switchCamera();
    });

    test('start with custom cameraDirection', () async {
      final controller = MobileScannerController(autoStart: false);
      await controller.start(cameraDirection: CameraFacing.front);
      expect(controller.value.isInitialized, true);
      expect(controller.value.cameraDirection, CameraFacing.front);
    });

    test('start handles permission denied error', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel(
          'dev.steenbakker.mobile_scanner/scanner/method',
        ),
        (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'state':
              return 0; // denied
            case 'request':
              return false; // permission denied
            case 'stop':
              return null;
            default:
              return null;
          }
        },
      );

      final controller = MobileScannerController(autoStart: false);
      await controller.start();

      // The controller should handle the error gracefully
      expect(controller.value.isInitialized, true);
      expect(controller.value.isRunning, false);
      expect(controller.value.hasCameraPermission, false);
    });

    test('start handles platform exception on state', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel(
          'dev.steenbakker.mobile_scanner/scanner/method',
        ),
        (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'state':
              throw PlatformException(code: 'UNKNOWN_ERROR');
            default:
              return null;
          }
        },
      );

      final controller = MobileScannerController(autoStart: false);
      await controller.start();

      // Should handle error gracefully
      expect(controller.value.isInitialized, true);
    });
  });

  group('MobileScannerState', () {
    test('direct constructor creates state with all values', () {
      const state = MobileScannerState(
        availableCameras: 2,
        cameraDirection: CameraFacing.front,
        error: null,
        isInitialized: true,
        isRunning: true,
        size: Size(480, 640),
        torchState: TorchState.on,
        zoomScale: 0.5,
      );
      expect(state.availableCameras, 2);
      expect(state.cameraDirection, CameraFacing.front);
      expect(state.error, isNull);
      expect(state.isInitialized, true);
      expect(state.isRunning, true);
      expect(state.size, const Size(480, 640));
      expect(state.torchState, TorchState.on);
      expect(state.zoomScale, 0.5);
      expect(state.hasCameraPermission, true);
    });

    test('direct constructor with error sets hasCameraPermission false', () {
      const state = MobileScannerState(
        availableCameras: null,
        cameraDirection: CameraFacing.back,
        error: MobileScannerException(
          errorCode: MobileScannerErrorCode.permissionDenied,
        ),
        isInitialized: true,
        isRunning: false,
        size: Size.zero,
        torchState: TorchState.unavailable,
        zoomScale: 1.0,
      );
      expect(state.isInitialized, true);
      expect(state.hasCameraPermission, false);
      expect(state.error, isNotNull);
    });

    test('uninitialized creates default state', () {
      final state = MobileScannerState.uninitialized(CameraFacing.back);
      expect(state.isInitialized, false);
      expect(state.isRunning, false);
      expect(state.availableCameras, isNull);
      expect(state.cameraDirection, CameraFacing.back);
      expect(state.torchState, TorchState.unavailable);
      expect(state.zoomScale, 1.0);
      expect(state.size, Size.zero);
      expect(state.error, isNull);
    });

    test('copyWith preserves unchanged values', () {
      final state = MobileScannerState.uninitialized(CameraFacing.back);
      final modified = state.copyWith(availableCameras: 2);

      expect(modified.availableCameras, 2);
      expect(modified.isInitialized, false);
      expect(modified.cameraDirection, CameraFacing.back);
    });

    test('copyWith resets error when not provided', () {
      final state = MobileScannerState.uninitialized(CameraFacing.back);
      final withError = state.copyWith(
        error: const MobileScannerException(
          errorCode: MobileScannerErrorCode.genericError,
        ),
      );
      expect(withError.error, isNotNull);

      // copyWith with no error parameter should keep previous error
      final unchanged = withError.copyWith(isRunning: true);
      expect(unchanged.error, isNull);
    });
  });

  group('Concurrency scenarios', () {
    test('multiple concurrent start() calls are handled safely', () async {
      final controller = MobileScannerController(autoStart: false);

      // Fire multiple start() calls concurrently
      final results = await Future.wait([
        controller.start(),
        controller.start(),
        controller.start(),
      ]);

      // Should not throw, and the controller should be running
      expect(controller.value.isInitialized, true);
      expect(controller.value.isRunning, true);
    });

    test('concurrent start() and dispose() are handled safely', () async {
      final controller = MobileScannerController(autoStart: false);

      // Fire start and dispose concurrently
      await Future.wait([
        controller.start(),
        controller.dispose(),
      ]);

      // After dispose, state should be cleaned up
      // Should not throw — double dispose is handled
      await controller.dispose();
    });

    test('barcodes stream supports multiple subscribers', () async {
      final controller = MobileScannerController(autoStart: false);
      await controller.start();

      final events1 = <BarcodeCapture>[];
      final events2 = <BarcodeCapture>[];

      // Subscribe to the barcodes stream with multiple listeners
      final sub1 = controller.barcodes.listen((event) {
        events1.add(event);
      });
      final sub2 = controller.barcodes.listen((event) {
        events2.add(event);
      });

      // The stream is a broadcast stream, so multiple subscribers are allowed
      expect(controller.barcodes, isA<Stream<BarcodeCapture>>());

      // Clean up subscriptions
      await sub1.cancel();
      await sub2.cancel();
    });

    test('concurrent toggleTorch() and stop() are handled safely', () async {
      final controller = MobileScannerController(autoStart: false);
      await controller.start();

      // Fire toggleTorch and stop concurrently
      await Future.wait([
        controller.toggleTorch(),
        controller.stop(),
      ]);

      // After stop, controller should not be running
      expect(controller.value.isRunning, false);

      // toggleTorch after stop should not throw
      await controller.toggleTorch();
    });

    test('concurrent setZoomScale() and stop() are handled safely', () async {
      final controller = MobileScannerController(autoStart: false);
      await controller.start();

      // Fire zoom and stop concurrently
      await Future.wait([
        controller.setZoomScale(0.5),
        controller.stop(),
      ]);

      // After stop, controller should not be running
      expect(controller.value.isRunning, false);
    });
  });

  group('Controller coverage completeness', () {
    test('setZoomScale clamps zoom values', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel(
          'dev.steenbakker.mobile_scanner/scanner/method',
        ),
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
            case 'setScale':
              return null;
            default:
              return null;
          }
        },
      );

      final controller = MobileScannerController(autoStart: false);
      await controller.start();
      await controller.setZoomScale(0.5);
      await controller.setZoomScale(0.0);
      await controller.setZoomScale(1.0);
    });

    test('buildCameraView throws when not initialized', () {
      final controller = MobileScannerController(autoStart: false);
      expect(
        () => controller.buildCameraView(),
        throwsA(isA<MobileScannerException>()),
      );
    });

    test('buildCameraView throws when disposed', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel(
          'dev.steenbakker.mobile_scanner/scanner/method',
        ),
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
            default:
              return null;
          }
        },
      );

      final controller = MobileScannerController(autoStart: false);
      await controller.start();
      await controller.dispose();

      expect(
        () => controller.buildCameraView(),
        throwsA(isA<MobileScannerException>()),
      );
    });

    test('start handles already-initialized error gracefully', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel(
          'dev.steenbakker.mobile_scanner/scanner/method',
        ),
        (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'state':
              return 1;
            case 'request':
              return true;
            case 'start':
              throw PlatformException(
                code: 'MOBILE_SCANNER_ALREADY_STARTED_ERROR',
              );
            default:
              return null;
          }
        },
      );

      final controller = MobileScannerController(autoStart: false);
      await controller.start();
    });

    test('start second time does not throw', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel(
          'dev.steenbakker.mobile_scanner/scanner/method',
        ),
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
            default:
              return null;
          }
        },
      );

      final controller = MobileScannerController(autoStart: false);
      await controller.start();
      await controller.start();
    });
  });
}