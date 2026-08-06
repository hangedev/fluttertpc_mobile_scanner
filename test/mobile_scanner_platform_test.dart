import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class TestMobileScannerPlatform extends MobileScannerPlatform {
  TestMobileScannerPlatform() : super();

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
  Widget buildCameraView() {
    return const SizedBox.shrink();
  }

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
  Future<void> setZoomScale(double zoomScale) async {
    throw UnimplementedError();
  }

  @override
  Future<MobileScannerViewAttributes> start(StartOptions startOptions) async {
    return const MobileScannerViewAttributes(
      cameraDirection: CameraFacing.back,
      currentTorchMode: TorchState.off,
      size: Size(1920, 1080),
      numberOfCameras: 1,
    );
  }

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MobileScannerPlatform', () {
    test('constructor creates instance', () {
      final platform = TestMobileScannerPlatform();
      expect(platform, isA<MobileScannerPlatform>());
    });

    test('instance can be set and retrieved', () {
      final platform = TestMobileScannerPlatform();
      MobileScannerPlatform.instance = platform;
      expect(MobileScannerPlatform.instance, equals(platform));
    });

    test('setBarcodeLibraryScriptUrl sets the script URL', () {
      final platform = TestMobileScannerPlatform();
      MobileScannerPlatform.instance = platform;
      platform.setBarcodeLibraryScriptUrl('https://example.com/script.js');
      // Should not throw
    });

    test('setZoomScale throws UnimplementedError', () async {
      final platform = TestMobileScannerPlatform();
      MobileScannerPlatform.instance = platform;

      expect(
        () => platform.setZoomScale(0.5),
        throwsUnimplementedError,
      );
    });

    test('start returns MobileScannerViewAttributes', () async {
      final platform = TestMobileScannerPlatform();
      MobileScannerPlatform.instance = platform;

      final options = StartOptions(
        cameraDirection: CameraFacing.back,
        cameraResolution: null,
        detectionSpeed: DetectionSpeed.normal,
        detectionTimeoutMs: 500,
        formats: const [],
        returnImage: false,
        torchEnabled: false,
        invertImage: false,
        autoZoom: false,
        initialZoom: null,
      );

      final attributes = await platform.start(options);
      expect(attributes.cameraDirection, CameraFacing.back);
      expect(attributes.currentTorchMode, TorchState.off);
      expect(attributes.size, const Size(1920, 1080));
      expect(attributes.numberOfCameras, 1);
    });

    test('stop completes without error', () async {
      final platform = TestMobileScannerPlatform();
      MobileScannerPlatform.instance = platform;
      await platform.stop();
    });

    test('pause completes without error', () async {
      final platform = TestMobileScannerPlatform();
      MobileScannerPlatform.instance = platform;
      await platform.pause();
    });

    test('toggleTorch completes without error', () async {
      final platform = TestMobileScannerPlatform();
      MobileScannerPlatform.instance = platform;
      await platform.toggleTorch();
    });

    test('dispose completes without error', () async {
      final platform = TestMobileScannerPlatform();
      MobileScannerPlatform.instance = platform;
      await platform.dispose();
    });

    test('resetZoomScale completes without error', () async {
      final platform = TestMobileScannerPlatform();
      MobileScannerPlatform.instance = platform;
      await platform.resetZoomScale();
    });

    test('analyzeImage returns null for empty result', () async {
      final platform = TestMobileScannerPlatform();
      MobileScannerPlatform.instance = platform;

      final result = await platform.analyzeImage('/test/path');
      expect(result, isNull);
    });

    test('barcodesStream returns stream', () async {
      final platform = TestMobileScannerPlatform();
      MobileScannerPlatform.instance = platform;

      expect(platform.barcodesStream, isA<Stream<BarcodeCapture?>>());
    });

    test('torchStateStream returns stream', () async {
      final platform = TestMobileScannerPlatform();
      MobileScannerPlatform.instance = platform;

      expect(platform.torchStateStream, isA<Stream<TorchState>>());
    });

    test('zoomScaleStateStream returns stream', () async {
      final platform = TestMobileScannerPlatform();
      MobileScannerPlatform.instance = platform;

      expect(platform.zoomScaleStateStream, isA<Stream<double>>());
    });

    test('setFocusPoint completes without error', () async {
      final platform = TestMobileScannerPlatform();
      MobileScannerPlatform.instance = platform;

      await platform.setFocusPoint(const Offset(0.5, 0.5));
    });

    test('updateScanWindow completes without error', () async {
      final platform = TestMobileScannerPlatform();
      MobileScannerPlatform.instance = platform;

      await platform.updateScanWindow(const Rect.fromLTWH(0, 0, 100, 100));
      // null window should also be accepted (reset to full screen)
      await platform.updateScanWindow(null);
    });
  });
}