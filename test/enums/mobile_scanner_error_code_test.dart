import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/enums/mobile_scanner_error_code.dart';

void main() {
  group('$MobileScannerErrorCode tests', () {
    test('can be created from platform exception', () {
      // Test each error code mapping
      final testCases = <String, MobileScannerErrorCode>{
        'MOBILE_SCANNER_ALREADY_STARTED_ERROR':
            MobileScannerErrorCode.controllerAlreadyInitialized,
        'MOBILE_SCANNER_NO_CAMERA_ERROR':
            MobileScannerErrorCode.unsupported,
        'MOBILE_SCANNER_CAMERA_PERMISSION_DENIED':
            MobileScannerErrorCode.permissionDenied,
        'UNKNOWN_ERROR_CODE':
            MobileScannerErrorCode.genericError,
      };

      for (final entry in testCases.entries) {
        final exception = PlatformException(code: entry.key, message: null);
        final result = MobileScannerErrorCode.fromPlatformException(exception);
        expect(result, entry.value,
            reason: 'Expected ${entry.value} for code ${entry.key}');
      }
    });

    test('has correct message for each error code', () {
      final testCases = <MobileScannerErrorCode, String>{
        MobileScannerErrorCode.controllerUninitialized:
            'The MobileScannerController has not been initialized. Call start() before using it.',
        MobileScannerErrorCode.permissionDenied:
            'Camera permission denied.',
        MobileScannerErrorCode.unsupported:
            'Scanning is not supported on this device.',
        MobileScannerErrorCode.controllerAlreadyInitialized:
            'The MobileScannerController is already running. Stop it before starting again.',
        MobileScannerErrorCode.controllerDisposed:
            'The MobileScannerController was used after it was disposed.',
        MobileScannerErrorCode.genericError:
            'An unexpected error occurred.',
      };

      for (final entry in testCases.entries) {
        expect(entry.key.message, entry.value,
            reason: 'Expected message for ${entry.key}');
      }
    });

    test('has all expected enum values', () {
      final values = MobileScannerErrorCode.values;
      expect(values.length, 6);
      expect(values, contains(MobileScannerErrorCode.controllerAlreadyInitialized));
      expect(values, contains(MobileScannerErrorCode.controllerDisposed));
      expect(values, contains(MobileScannerErrorCode.controllerUninitialized));
      expect(values, contains(MobileScannerErrorCode.genericError));
      expect(values, contains(MobileScannerErrorCode.permissionDenied));
      expect(values, contains(MobileScannerErrorCode.unsupported));
    });
  });
}