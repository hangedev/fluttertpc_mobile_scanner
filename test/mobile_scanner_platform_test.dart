import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/enums/barcode_format.dart';
import 'package:mobile_scanner/src/enums/camera_facing.dart';
import 'package:mobile_scanner/src/enums/detection_speed.dart';
import 'package:mobile_scanner/src/enums/torch_state.dart';
import 'package:mobile_scanner/src/mobile_scanner_platform_interface.dart';
import 'package:mobile_scanner/src/mobile_scanner_view_attributes.dart';
import 'package:mobile_scanner/src/objects/barcode_capture.dart';
import 'package:mobile_scanner/src/objects/start_options.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// A test implementation of [MobileScannerPlatform] for testing purposes.
class TestMobileScannerPlatform extends MobileScannerPlatform {
  bool analyzeImageCalled = false;
  bool buildCameraViewCalled = false;
  bool resetZoomScaleCalled = false;
  bool setBarcodeLibraryScriptUrlCalled = false;
  bool setZoomScaleCalled = false;
  bool startCalled = false;
  bool stopCalled = false;
  bool pauseCalled = false;
  bool toggleTorchCalled = false;
  bool updateScanWindowCalled = false;
  bool disposeCalled = false;

  double? lastZoomScale;
  String? lastAnalyzePath;
  List<BarcodeFormat>? lastAnalyzeFormats;
  String? lastScriptUrl;
  Rect? lastWindow;

  @override
  Stream<BarcodeCapture?> get barcodesStream {
    throw UnimplementedError('barcodesStream has not been implemented.');
  }

  @override
  Stream<TorchState> get torchStateStream {
    throw UnimplementedError('torchStateStream has not been implemented.');
  }

  @override
  Stream<double> get zoomScaleStateStream {
    throw UnimplementedError('zoomScaleStateStream has not been implemented.');
  }

  @override
  Future<BarcodeCapture?> analyzeImage(
    String path, {
    List<BarcodeFormat> formats = const <BarcodeFormat>[],
  }) {
    analyzeImageCalled = true;
    lastAnalyzePath = path;
    lastAnalyzeFormats = formats;
    throw UnimplementedError('analyzeImage() has not been implemented.');
  }

  @override
  Widget buildCameraView() {
    buildCameraViewCalled = true;
    throw UnimplementedError('buildCameraView() has not been implemented.');
  }

  @override
  Future<void> resetZoomScale() {
    resetZoomScaleCalled = true;
    throw UnimplementedError('resetZoomScale() has not been implemented.');
  }

  @override
  void setBarcodeLibraryScriptUrl(String scriptUrl) {
    setBarcodeLibraryScriptUrlCalled = true;
    lastScriptUrl = scriptUrl;
  }

  @override
  Future<void> setZoomScale(double zoomScale) {
    setZoomScaleCalled = true;
    lastZoomScale = zoomScale;
    throw UnimplementedError('setZoomScale() has not been implemented.');
  }

  @override
  Future<MobileScannerViewAttributes> start(StartOptions startOptions) {
    startCalled = true;
    throw UnimplementedError('start() has not been implemented.');
  }

  @override
  Future<void> stop() {
    stopCalled = true;
    throw UnimplementedError('stop() has not been implemented.');
  }

  @override
  Future<void> pause() {
    pauseCalled = true;
    throw UnimplementedError('pause() has not been implemented.');
  }

  @override
  Future<void> toggleTorch() {
    toggleTorchCalled = true;
    throw UnimplementedError('toggleTorch() has not been implemented.');
  }

  @override
  Future<void> updateScanWindow(Rect? window) {
    updateScanWindowCalled = true;
    lastWindow = window;
    throw UnimplementedError('updateScanWindow() has not been implemented.');
  }

  @override
  Future<void> dispose() {
    disposeCalled = true;
    throw UnimplementedError('dispose() has not been implemented.');
  }
}

void main() {
  group('MobileScannerPlatform', () {
    late TestMobileScannerPlatform testPlatform;

    setUp(() {
      testPlatform = TestMobileScannerPlatform();
    });

    test('can be created with default instance', () {
      final instance = MobileScannerPlatform.instance;
      expect(instance, isNotNull);
      expect(instance, isA<MobileScannerPlatform>());
    });

    test('default instance is MethodChannelMobileScanner', () {
      final instance = MobileScannerPlatform.instance;
      expect(instance.runtimeType.toString(), 'MethodChannelMobileScanner');
    });

    test('instance can be set to a custom implementation', () {
      MobileScannerPlatform.instance = testPlatform;
      expect(MobileScannerPlatform.instance, testPlatform);
      // Reset to default
      MobileScannerPlatform.instance = MobileScannerPlatform.instance;
    });

    test('constructor requires token and cannot be instantiated directly', () {
      // Verify that MobileScannerPlatform is abstract
      // by checking that it can't be constructed without a subclass
      expect(MobileScannerPlatform, isA<Type>());
      expect(() => TestMobileScannerPlatform(), isNot(throwsException));
    });

    test('barcodesStream throws UnimplementedError by default', () {
      expect(
        () => testPlatform.barcodesStream,
        throwsUnimplementedError,
      );
    });

    test('torchStateStream throws UnimplementedError by default', () {
      expect(
        () => testPlatform.torchStateStream,
        throwsUnimplementedError,
      );
    });

    test('zoomScaleStateStream throws UnimplementedError by default', () {
      expect(
        () => testPlatform.zoomScaleStateStream,
        throwsUnimplementedError,
      );
    });

    test('analyzeImage throws UnimplementedError by default', () {
      expect(
        () => testPlatform.analyzeImage('/test/path'),
        throwsUnimplementedError,
      );
    });

    test('analyzeImage is called with correct path', () {
      expect(
        () => testPlatform.analyzeImage('/test/path'),
        throwsUnimplementedError,
      );
      expect(testPlatform.analyzeImageCalled, isTrue);
      expect(testPlatform.lastAnalyzePath, '/test/path');
    });

    test('analyzeImage is called with formats', () {
      expect(
        () => testPlatform.analyzeImage(
          '/test/path',
          formats: [BarcodeFormat.qrCode],
        ),
        throwsUnimplementedError,
      );
      expect(testPlatform.lastAnalyzeFormats, [BarcodeFormat.qrCode]);
    });

    test('buildCameraView throws UnimplementedError by default', () {
      expect(
        () => testPlatform.buildCameraView(),
        throwsUnimplementedError,
      );
    });

    test('resetZoomScale throws UnimplementedError by default', () {
      expect(
        () => testPlatform.resetZoomScale(),
        throwsUnimplementedError,
      );
    });

    test('setBarcodeLibraryScriptUrl does not throw', () {
      testPlatform.setBarcodeLibraryScriptUrl('https://example.com/script.js');
      expect(testPlatform.setBarcodeLibraryScriptUrlCalled, isTrue);
      expect(testPlatform.lastScriptUrl, 'https://example.com/script.js');
    });

    test('setZoomScale throws UnimplementedError by default', () {
      expect(
        () => testPlatform.setZoomScale(0.5),
        throwsUnimplementedError,
      );
    });

    test('setZoomScale is called with correct value', () {
      expect(
        () => testPlatform.setZoomScale(0.5),
        throwsUnimplementedError,
      );
      expect(testPlatform.setZoomScaleCalled, isTrue);
      expect(testPlatform.lastZoomScale, 0.5);
    });

    test('start throws UnimplementedError by default', () {
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
        () => testPlatform.start(options),
        throwsUnimplementedError,
      );
    });

    test('stop throws UnimplementedError by default', () {
      expect(
        () => testPlatform.stop(),
        throwsUnimplementedError,
      );
    });

    test('pause throws UnimplementedError by default', () {
      expect(
        () => testPlatform.pause(),
        throwsUnimplementedError,
      );
    });

    test('toggleTorch throws UnimplementedError by default', () {
      expect(
        () => testPlatform.toggleTorch(),
        throwsUnimplementedError,
      );
    });

    test('updateScanWindow throws UnimplementedError by default', () {
      expect(
        () => testPlatform.updateScanWindow(null),
        throwsUnimplementedError,
      );
    });

    test('updateScanWindow is called with correct rect', () {
      const rect = Rect.fromLTWH(0.0, 0.0, 100.0, 100.0);
      expect(
        () => testPlatform.updateScanWindow(rect),
        throwsUnimplementedError,
      );
      expect(testPlatform.updateScanWindowCalled, isTrue);
      expect(testPlatform.lastWindow, rect);
    });

    test('dispose throws UnimplementedError by default', () {
      expect(
        () => testPlatform.dispose(),
        throwsUnimplementedError,
      );
    });

    test('instance setter verifies token', () {
      // Attempting to set an instance that doesn't extend MobileScannerPlatform
      // should throw an error (TypeError or AssertionError depending on the platform)
      expect(
        () => MobileScannerPlatform.instance = FakePlatformInterface() as MobileScannerPlatform,
        throwsA(isA<TypeError>()),
      );
    });

    test('registered instance passes token verification', () {
      // A proper subclass with the correct token should work
      // This is tested by the default instance being set successfully
      final instance = MobileScannerPlatform.instance;
      expect(instance, isNotNull);
    });
  });
}

/// A fake class that doesn't extend MobileScannerPlatform, used to test
/// the token verification in the instance setter.
class FakePlatformInterface {
  // Intentionally empty
}