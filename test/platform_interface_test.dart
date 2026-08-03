import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/enums/barcode_format.dart';
import 'package:mobile_scanner/src/enums/camera_facing.dart';
import 'package:mobile_scanner/src/enums/detection_speed.dart';
import 'package:mobile_scanner/src/enums/mobile_scanner_error_code.dart';
import 'package:mobile_scanner/src/enums/torch_state.dart';
import 'package:mobile_scanner/src/method_channel/mobile_scanner_method_channel.dart';
import 'package:mobile_scanner/src/mobile_scanner_exception.dart';
import 'package:mobile_scanner/src/mobile_scanner_platform_interface.dart';
import 'package:mobile_scanner/src/mobile_scanner_view_attributes.dart';
import 'package:mobile_scanner/src/objects/barcode.dart';
import 'package:mobile_scanner/src/objects/barcode_capture.dart';
import 'package:mobile_scanner/src/objects/start_options.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MobileScannerPlatform', () {
    test('instance getter returns MethodChannelMobileScanner by default', () {
      final instance = MobileScannerPlatform.instance;
      expect(instance, isNotNull);
      expect(instance, isA<MethodChannelMobileScanner>());
    });

    test('instance setter allows setting a custom implementation', () {
      final custom = _TestMobileScannerPlatform();
      MobileScannerPlatform.instance = custom;
      expect(MobileScannerPlatform.instance, custom);
    });

    test('instance setter rejects non-verified implementations', () {
      // Setting a non-verified instance should throw
      // because the PlatformInterface.verifyToken check fails
      expect(
        () {
          MobileScannerPlatform.instance =
              _InvalidMobileScannerPlatform();
        },
        throwsA(isA<AssertionError>()),
      );
    });

    test('barcodesStream throws UnimplementedError by default', () {
      final platform = _TestMobileScannerPlatform();
      expect(
        () => platform.barcodesStream,
        throwsUnimplementedError,
      );
    });

    test('torchStateStream throws UnimplementedError by default', () {
      final platform = _TestMobileScannerPlatform();
      expect(
        () => platform.torchStateStream,
        throwsUnimplementedError,
      );
    });

    test('zoomScaleStateStream throws UnimplementedError by default', () {
      final platform = _TestMobileScannerPlatform();
      expect(
        () => platform.zoomScaleStateStream,
        throwsUnimplementedError,
      );
    });

    test('analyzeImage throws UnimplementedError by default', () {
      final platform = _TestMobileScannerPlatform();
      expect(
        () => platform.analyzeImage('/test/path'),
        throwsUnimplementedError,
      );
    });

    test('buildCameraView throws UnimplementedError by default', () {
      final platform = _TestMobileScannerPlatform();
      expect(
        () => platform.buildCameraView(),
        throwsUnimplementedError,
      );
    });

    test('resetZoomScale throws UnimplementedError by default', () {
      final platform = _TestMobileScannerPlatform();
      expect(
        () => platform.resetZoomScale(),
        throwsUnimplementedError,
      );
    });

    test('setZoomScale throws UnimplementedError by default', () {
      final platform = _TestMobileScannerPlatform();
      expect(
        () => platform.setZoomScale(0.5),
        throwsUnimplementedError,
      );
    });

    test('start throws UnimplementedError by default', () {
      final platform = _TestMobileScannerPlatform();
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
        () => platform.start(options),
        throwsUnimplementedError,
      );
    });

    test('stop throws UnimplementedError by default', () {
      final platform = _TestMobileScannerPlatform();
      expect(
        () => platform.stop(),
        throwsUnimplementedError,
      );
    });

    test('toggleTorch throws UnimplementedError by default', () {
      final platform = _TestMobileScannerPlatform();
      expect(
        () => platform.toggleTorch(),
        throwsUnimplementedError,
      );
    });

    test('updateScanWindow throws UnimplementedError by default', () {
      final platform = _TestMobileScannerPlatform();
      expect(
        () => platform.updateScanWindow(null),
        throwsUnimplementedError,
      );
    });

    test('dispose throws UnimplementedError by default', () {
      final platform = _TestMobileScannerPlatform();
      expect(
        () => platform.dispose(),
        throwsUnimplementedError,
      );
    });

    test('setBarcodeLibraryScriptUrl does nothing by default', () {
      final platform = _TestMobileScannerPlatform();
      // Should not throw
      platform.setBarcodeLibraryScriptUrl('https://example.com/script.js');
    });
  });

  group('BarcodeCapture', () {
    test('corners getter returns null', () {
      const capture = BarcodeCapture();
      expect(capture.corners, isNull);
    });

    test('constructor creates with barcodes', () {
      const capture = BarcodeCapture(
        barcodes: <Barcode>[
          Barcode(rawValue: 'test'),
        ],
      );
      expect(capture.barcodes.length, 1);
      expect(capture.barcodes[0].rawValue, 'test');
    });

    test('constructor creates with raw data', () {
      const capture = BarcodeCapture(
        raw: <String, String>{'key': 'value'},
      );
      expect(capture.raw, {'key': 'value'});
    });
  });

  group('MobileScannerException.toString', () {
    test('toString without errorDetails', () {
      const exception = MobileScannerException(
        errorCode: MobileScannerErrorCode.genericError,
      );
      final str = exception.toString();
      expect(str, 'MobileScannerException(genericError)');
    });

    test('toString with errorDetails and message', () {
      const exception = MobileScannerException(
        errorCode: MobileScannerErrorCode.permissionDenied,
        errorDetails: MobileScannerErrorDetails(
          message: 'Permission denied',
        ),
      );
      final str = exception.toString();
      expect(str, contains('MobileScannerException'));
      expect(str, contains('permissionDenied'));
      expect(str, contains('Permission denied'));
    });

    test('toString with errorDetails but no message', () {
      const exception = MobileScannerException(
        errorCode: MobileScannerErrorCode.genericError,
        errorDetails: MobileScannerErrorDetails(
          code: 'ERROR_CODE',
        ),
      );
      final str = exception.toString();
      expect(str, 'MobileScannerException(genericError)');
    });
  });

  group('MobileScannerViewAttributes', () {
    test('creates with all fields', () {
      final attrs = MobileScannerViewAttributes(
        currentTorchMode: TorchState.on,
        numberOfCameras: 2,
        size: const Size(480, 640),
      );
      expect(attrs.currentTorchMode, TorchState.on);
      expect(attrs.numberOfCameras, 2);
      expect(attrs.size.width, 480);
      expect(attrs.size.height, 640);
    });
  });
}

/// A concrete implementation of [MobileScannerPlatform] for testing.
class _TestMobileScannerPlatform extends MobileScannerPlatform {
  _TestMobileScannerPlatform() : super();
}

/// An invalid implementation that does not extend MobileScannerPlatform.
class _InvalidMobileScannerPlatform implements MobileScannerPlatform {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}