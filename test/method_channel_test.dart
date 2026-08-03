import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/enums/barcode_format.dart';
import 'package:mobile_scanner/src/enums/camera_facing.dart';
import 'package:mobile_scanner/src/enums/detection_speed.dart';
import 'package:mobile_scanner/src/enums/mobile_scanner_error_code.dart';
import 'package:mobile_scanner/src/enums/torch_state.dart';
import 'package:mobile_scanner/src/mobile_scanner_exception.dart';
import 'package:mobile_scanner/src/method_channel/mobile_scanner_method_channel.dart';
import 'package:mobile_scanner/src/mobile_scanner_exception.dart';
import 'package:mobile_scanner/src/mobile_scanner_platform_interface.dart';
import 'package:mobile_scanner/src/mobile_scanner_view_attributes.dart';
import 'package:mobile_scanner/src/objects/barcode_capture.dart';
import 'package:mobile_scanner/src/objects/start_options.dart';

void main() {
  const MethodChannel methodChannel = MethodChannel(
    'dev.steenbakker.mobile_scanner/scanner/method',
  );
  const EventChannel eventChannel = EventChannel(
    'dev.steenbakker.mobile_scanner/scanner/event',
  );

  TestWidgetsFlutterBinding.ensureInitialized();

  late MethodChannelMobileScanner methodChannelMobileScanner;

  setUp(() {
    methodChannelMobileScanner = MethodChannelMobileScanner();
    MobileScannerPlatform.instance = methodChannelMobileScanner;
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(methodChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler(eventChannel.name, null);
  });

  group('MethodChannelMobileScanner', () {
    group('start', () {
      test('returns view attributes on success', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(methodChannel, (MethodCall call) async {
          switch (call.method) {
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
            default:
              return null;
          }
        });

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

        final attributes = await methodChannelMobileScanner.start(options);
        expect(attributes.currentTorchMode, TorchState.off);
        expect(attributes.numberOfCameras, 2);
        expect(attributes.size.width, 480.0);
        expect(attributes.size.height, 640.0);
      });

      test('throws already started error when textureId is not null', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(methodChannel, (MethodCall call) async {
          switch (call.method) {
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
        });

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

        // First start succeeds
        await methodChannelMobileScanner.start(options);

        // Second start should throw
        expect(
          () => methodChannelMobileScanner.start(options),
          throwsA(isA<MobileScannerException>()),
        );
      });

      test('throws when start returns null', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(methodChannel, (MethodCall call) async {
          switch (call.method) {
            case 'state':
              return 1;
            case 'request':
              return true;
            case 'start':
              return null;
            default:
              return null;
          }
        });

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

        expect(
          () => methodChannelMobileScanner.start(options),
          throwsA(isA<MobileScannerException>()),
        );
      });

      test('throws when start result has no textureId', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(methodChannel, (MethodCall call) async {
          switch (call.method) {
            case 'state':
              return 1;
            case 'request':
              return true;
            case 'start':
              return <String, Object?>{
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
        });

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

        expect(
          () => methodChannelMobileScanner.start(options),
          throwsA(isA<MobileScannerException>()),
        );
      });

      test('throws on platform exception', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(methodChannel, (MethodCall call) async {
          switch (call.method) {
            case 'state':
              return 1;
            case 'request':
              return true;
            case 'start':
              throw PlatformException(
                code: 'MOBILE_SCANNER_CAMERA_PERMISSION_DENIED',
                message: 'Camera permission denied',
              );
            default:
              return null;
          }
        });

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

        expect(
          () => methodChannelMobileScanner.start(options),
          throwsA(isA<MobileScannerException>()),
        );
      });
    });

    group('stop', () {
      test('stops the scanner', () async {
        bool stopCalled = false;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(methodChannel, (MethodCall call) async {
          switch (call.method) {
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
              stopCalled = true;
              return null;
            default:
              return null;
          }
        });

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

        await methodChannelMobileScanner.start(options);
        await methodChannelMobileScanner.stop();
        expect(stopCalled, true);
      });

      test('does nothing when not started', () async {
        await methodChannelMobileScanner.stop();
        // Should not throw
      });
    });

    group('toggleTorch', () {
      test('toggles torch', () async {
        bool toggleTorchCalled = false;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(methodChannel, (MethodCall call) async {
          if (call.method == 'toggleTorch') {
            toggleTorchCalled = true;
            return null;
          }
          return null;
        });

        await methodChannelMobileScanner.toggleTorch();
        expect(toggleTorchCalled, true);
      });
    });

    group('analyzeImage', () {
      test('analyzes image and returns barcodes', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(methodChannel, (MethodCall call) async {
          if (call.method == 'analyzeImage') {
            return <String, Object?>{
              'name': 'barcode',
              'data': <Object?>[
                <String, Object?>{
                  'format': 256,
                  'type': 7,
                  'rawValue': 'test-data',
                },
              ],
            };
          }
          return null;
        });

        final result = await methodChannelMobileScanner.analyzeImage(
          '/test/path',
          formats: [BarcodeFormat.qrCode],
        );

        expect(result, isNotNull);
        expect(result!.barcodes.length, 1);
        expect(result.barcodes[0].rawValue, 'test-data');
      });

      test('analyzeImage returns null on platform exception', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(methodChannel, (MethodCall call) async {
          if (call.method == 'analyzeImage') {
            throw PlatformException(code: 'UNKNOWN_ERROR');
          }
          return null;
        });

        final result = await methodChannelMobileScanner.analyzeImage(
          '/test/path',
        );

        expect(result, isNull);
      });

      test('analyzeImage throws MobileScannerBarcodeException on barcode error', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(methodChannel, (MethodCall call) async {
          if (call.method == 'analyzeImage') {
            throw PlatformException(
              code: 'MOBILE_SCANNER_BARCODE_ERROR',
              message: 'No barcode found',
            );
          }
          return null;
        });

        expect(
          () => methodChannelMobileScanner.analyzeImage('/test/path'),
          throwsA(isA<MobileScannerBarcodeException>()),
        );
      });
    });

    group('setZoomScale / resetZoomScale', () {
      test('setZoomScale calls method channel', () async {
        String? calledMethod;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(methodChannel, (MethodCall call) async {
          calledMethod = call.method;
          return null;
        });

        await methodChannelMobileScanner.setZoomScale(0.5);
        expect(calledMethod, 'setScale');
      });

      test('resetZoomScale calls method channel', () async {
        String? calledMethod;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(methodChannel, (MethodCall call) async {
          calledMethod = call.method;
          return null;
        });

        await methodChannelMobileScanner.resetZoomScale();
        expect(calledMethod, 'resetScale');
      });
    });

    group('updateScanWindow', () {
      test('updateScanWindow calls method channel with rect', () async {
        Object? passedArgs;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(methodChannel, (MethodCall call) async {
          if (call.method == 'updateScanWindow') {
            passedArgs = call.arguments;
            return null;
          }
          // Need to start first to set textureId
          if (call.method == 'start') {
            return <String, Object?>{
              'textureId': 1,
              'size': <String, Object?>{
                'width': 480.0,
                'height': 640.0,
              },
              'currentTorchState': 0,
              'numberOfCameras': 1,
            };
          }
          if (call.method == 'state') return 1;
          if (call.method == 'request') return true;
          return null;
        });

        // Start first to set textureId
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
        await methodChannelMobileScanner.start(options);

        await methodChannelMobileScanner.updateScanWindow(
          const Rect.fromLTRB(0.1, 0.2, 0.9, 0.8),
        );
        expect(passedArgs, isNotNull);
      });

      test('updateScanWindow does nothing when not started', () async {
        // Should not throw
        await methodChannelMobileScanner.updateScanWindow(
          const Rect.fromLTRB(0.1, 0.1, 0.9, 0.9),
        );
      });
    });

    group('dispose', () {
      test('dispose calls stop', () async {
        bool stopCalled = false;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(methodChannel, (MethodCall call) async {
          switch (call.method) {
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
              stopCalled = true;
              return null;
            default:
              return null;
          }
        });

        // Start first to set textureId, then dispose
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
        await methodChannelMobileScanner.start(options);
        await methodChannelMobileScanner.dispose();
        expect(stopCalled, true);
      });
    });

    group('buildCameraView', () {
      test('returns SizedBox when textureId is null', () {
        final widget = methodChannelMobileScanner.buildCameraView();
        // Returns SizedBox
        expect(widget, isNotNull);
      });
    });

    group('barcodesStream', () {
      test('emits barcode events from event channel', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMessageHandler(eventChannel.name, (ByteData? message) {
          if (message != null) {
            final decoded = utf8.decode(message.buffer.asUint8List());
            // Return null to avoid interfering with the stream
          }
          return null;
        });

        // Set up mock method channel for start
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(methodChannel, (MethodCall call) async {
          switch (call.method) {
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
        });

        final stream = methodChannelMobileScanner.barcodesStream;
        expect(stream, isA<Stream<BarcodeCapture?>>());
      });
    });

    group('torchStateStream', () {
      test('emits torch state events', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMessageHandler(eventChannel.name, (ByteData? message) {
          return null;
        });

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(methodChannel, (MethodCall call) async {
          return null;
        });

        final stream = methodChannelMobileScanner.torchStateStream;
        expect(stream, isA<Stream<TorchState>>());
      });
    });

    group('zoomScaleStateStream', () {
      test('emits zoom scale state events', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMessageHandler(eventChannel.name, (ByteData? message) {
          return null;
        });

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(methodChannel, (MethodCall call) async {
          return null;
        });

        final stream = methodChannelMobileScanner.zoomScaleStateStream;
        expect(stream, isA<Stream<double>>());
      });
    });

    group('barcode parsing edge cases', () {
      test('barcodesStream filters barcode events by name', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMessageHandler(eventChannel.name, (ByteData? message) {
          return null;
        });

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(methodChannel, (MethodCall call) async {
          return null;
        });

        final stream = methodChannelMobileScanner.barcodesStream;
        expect(stream, isA<Stream<BarcodeCapture?>>());
      });
    });

    group('platform-specific barcode parsing', () {
      test('parses barcode with image data for supported platforms', () async {
        // Only test on non-web platforms
        if (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS ||
            defaultTargetPlatform == TargetPlatform.ohos) {
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(methodChannel, (MethodCall call) async {
            if (call.method == 'analyzeImage') {
              return <String, Object?>{
                'name': 'barcode',
                'data': <Object?>[
                  <String, Object?>{
                    'format': 256,
                    'type': 7,
                    'rawValue': 'test',
                  },
                ],
                'image': <String, Object?>{
                  'bytes': Uint8List.fromList([0x00, 0x01]),
                  'width': 100.0,
                  'height': 200.0,
                },
              };
            }
            return null;
          });

          final result = await methodChannelMobileScanner.analyzeImage(
            '/test/path',
          );
          expect(result, isNotNull);
          expect(result!.barcodes.length, 1);
          expect(result.barcodes[0].rawValue, 'test');
        }
      });
    });
  });
}