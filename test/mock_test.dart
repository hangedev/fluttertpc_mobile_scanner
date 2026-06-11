import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mobile_scanner/src/mobile_scanner_platform_interface.dart';
import 'package:mobile_scanner/src/mobile_scanner_view_attributes.dart';
import 'package:mobile_scanner/src/objects/start_options.dart';
import 'package:mobile_scanner/src/enums/camera_facing.dart';
import 'package:mobile_scanner/src/enums/detection_speed.dart';
import 'package:mobile_scanner/src/enums/barcode_format.dart';

// Manual mock class for MobileScannerPlatform (mockito-compatible pattern)
class MockMobileScannerPlatform extends MobileScannerPlatform {
  bool startCalled = false;
  bool stopCalled = false;
  bool disposeCalled = false;
  bool toggleTorchCalled = false;
  bool analyzeImageCalled = false;
  bool setZoomScaleCalled = false;
  bool resetZoomScaleCalled = false;
  bool updateScanWindowCalled = false;
  double? lastZoomScale;
  String? lastAnalyzeImagePath;
  Rect? lastScanWindow;

  @override
  Future<MobileScannerViewAttributes> start(StartOptions options) async {
    startCalled = true;
    return const MobileScannerViewAttributes(
      currentTorchMode: TorchState.off,
      numberOfCameras: 2,
      size: Size(480, 640),
    );
  }

  @override
  Future<void> stop() async {
    stopCalled = true;
  }

  @override
  Future<void> dispose() async {
    disposeCalled = true;
  }

  @override
  Future<void> toggleTorch() async {
    toggleTorchCalled = true;
  }

  @override
  Future<BarcodeCapture?> analyzeImage(
    String path, {
    List<BarcodeFormat> formats = const <BarcodeFormat>[],
  }) async {
    analyzeImageCalled = true;
    lastAnalyzeImagePath = path;
    return null;
  }

  @override
  Future<void> setZoomScale(double zoomScale) async {
    setZoomScaleCalled = true;
    lastZoomScale = zoomScale;
  }

  @override
  Future<void> resetZoomScale() async {
    resetZoomScaleCalled = true;
  }

  @override
  Future<void> updateScanWindow(Rect? window) async {
    updateScanWindowCalled = true;
    lastScanWindow = window;
  }

  @override
  Stream<TorchState> get torchStateStream => const Stream<TorchState>.empty();

  @override
  Stream<double> get zoomScaleStateStream => const Stream<double>.empty();

  @override
  Stream<BarcodeCapture> get barcodesStream => const Stream<BarcodeCapture>.empty();
}

void main() {
  group('Mockito-compatible MobileScannerPlatform mock tests', () {
    late MockMobileScannerPlatform mockPlatform;

    setUp(() {
      mockPlatform = MockMobileScannerPlatform();
    });

    test('should call start() when start is invoked', () async {
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

      final result = await mockPlatform.start(options);

      expect(mockPlatform.startCalled, true);
      expect(result, isA<MobileScannerViewAttributes>());
    });

    test('should call stop() when stop is invoked', () async {
      await mockPlatform.stop();
      expect(mockPlatform.stopCalled, true);
    });

    test('should call dispose() when dispose is invoked', () async {
      await mockPlatform.dispose();
      expect(mockPlatform.disposeCalled, true);
    });

    test('should call toggleTorch() when toggleTorch is invoked', () async {
      await mockPlatform.toggleTorch();
      expect(mockPlatform.toggleTorchCalled, true);
    });

    test('should call analyzeImage() when analyzeImage is invoked', () async {
      await mockPlatform.analyzeImage('/test/path', formats: [BarcodeFormat.qrCode]);
      expect(mockPlatform.analyzeImageCalled, true);
      expect(mockPlatform.lastAnalyzeImagePath, '/test/path');
    });

    test('should call setZoomScale() when setZoomScale is invoked', () async {
      await mockPlatform.setZoomScale(0.5);
      expect(mockPlatform.setZoomScaleCalled, true);
      expect(mockPlatform.lastZoomScale, 0.5);
    });

    test('should call resetZoomScale() when resetZoomScale is invoked', () async {
      await mockPlatform.resetZoomScale();
      expect(mockPlatform.resetZoomScaleCalled, true);
    });

    test('should call updateScanWindow() when updateScanWindow is invoked', () async {
      final testRect = const Rect.fromLTRB(0.1, 0.1, 0.9, 0.9);
      await mockPlatform.updateScanWindow(testRect);
      expect(mockPlatform.updateScanWindowCalled, true);
      expect(mockPlatform.lastScanWindow, testRect);
    });

    test('should return torchState stream when torchStateStream is accessed', () {
      expect(mockPlatform.torchStateStream, isA<Stream<TorchState>>());
    });

    test('should return zoomScale stream when zoomScaleStateStream is accessed', () {
      expect(mockPlatform.zoomScaleStateStream, isA<Stream<double>>());
    });
  });
}