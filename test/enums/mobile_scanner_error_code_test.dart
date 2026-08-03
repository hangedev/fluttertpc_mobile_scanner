import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/enums/mobile_scanner_error_code.dart';

void main() {
  group('$MobileScannerErrorCode tests', () {
    test('can be created from platform exception - ALREADY_STARTED', () {
      final exception = PlatformException(
        code: 'MOBILE_SCANNER_ALREADY_STARTED_ERROR',
      );

      final result = MobileScannerErrorCode.fromPlatformException(exception);

      expect(result, MobileScannerErrorCode.controllerAlreadyInitialized);
    });

    test('can be created from platform exception - NO_CAMERA', () {
      final exception = PlatformException(
        code: 'MOBILE_SCANNER_NO_CAMERA_ERROR',
      );

      final result = MobileScannerErrorCode.fromPlatformException(exception);

      expect(result, MobileScannerErrorCode.unsupported);
    });

    test('can be created from platform exception - PERMISSION_DENIED', () {
      final exception = PlatformException(
        code: 'MOBILE_SCANNER_CAMERA_PERMISSION_DENIED',
      );

      final result = MobileScannerErrorCode.fromPlatformException(exception);

      expect(result, MobileScannerErrorCode.permissionDenied);
    });

    test('unknown code returns genericError', () {
      final exception = PlatformException(code: 'UNKNOWN_ERROR_CODE');

      final result = MobileScannerErrorCode.fromPlatformException(exception);

      expect(result, MobileScannerErrorCode.genericError);
    });

    test('all error codes are defined', () {
      // Verify all enum values exist
      expect(MobileScannerErrorCode.values.length, 6);
      expect(MobileScannerErrorCode.values, containsAll([
        MobileScannerErrorCode.controllerAlreadyInitialized,
        MobileScannerErrorCode.controllerDisposed,
        MobileScannerErrorCode.controllerUninitialized,
        MobileScannerErrorCode.genericError,
        MobileScannerErrorCode.permissionDenied,
        MobileScannerErrorCode.unsupported,
      ]));
    });

    test('fromPlatformException handles edge case - empty code', () {
      final exception = PlatformException(code: '');

      final result = MobileScannerErrorCode.fromPlatformException(exception);

      expect(result, MobileScannerErrorCode.genericError);
    });

    test('fromPlatformException handles edge case - null message', () {
      final exception = PlatformException(
        code: 'MOBILE_SCANNER_CAMERA_PERMISSION_DENIED',
        message: null,
      );

      final result = MobileScannerErrorCode.fromPlatformException(exception);

      expect(result, MobileScannerErrorCode.permissionDenied);
    });
  });
}