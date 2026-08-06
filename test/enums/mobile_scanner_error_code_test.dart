import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

void main() {
  group('MobileScannerErrorCode', () {
    test('values contain all expected error codes', () {
      expect(MobileScannerErrorCode.values.length, 8);
      expect(MobileScannerErrorCode.values, contains(MobileScannerErrorCode.controllerAlreadyInitialized));
      expect(MobileScannerErrorCode.values, contains(MobileScannerErrorCode.controllerDisposed));
      expect(MobileScannerErrorCode.values, contains(MobileScannerErrorCode.controllerUninitialized));
      expect(MobileScannerErrorCode.values, contains(MobileScannerErrorCode.genericError));
      expect(MobileScannerErrorCode.values, contains(MobileScannerErrorCode.permissionDenied));
      expect(MobileScannerErrorCode.values, contains(MobileScannerErrorCode.unsupported));
      expect(MobileScannerErrorCode.values, contains(MobileScannerErrorCode.controllerInitializing));
      expect(MobileScannerErrorCode.values, contains(MobileScannerErrorCode.controllerNotAttached));
    });

    test('name returns correct string', () {
      expect(MobileScannerErrorCode.controllerAlreadyInitialized.name, 'controllerAlreadyInitialized');
      expect(MobileScannerErrorCode.controllerDisposed.name, 'controllerDisposed');
      expect(MobileScannerErrorCode.controllerUninitialized.name, 'controllerUninitialized');
      expect(MobileScannerErrorCode.genericError.name, 'genericError');
      expect(MobileScannerErrorCode.permissionDenied.name, 'permissionDenied');
      expect(MobileScannerErrorCode.unsupported.name, 'unsupported');
      expect(MobileScannerErrorCode.controllerInitializing.name, 'controllerInitializing');
      expect(MobileScannerErrorCode.controllerNotAttached.name, 'controllerNotAttached');
    });

    test('message returns human-readable text', () {
      expect(MobileScannerErrorCode.genericError.message, contains('unexpected'));
      expect(MobileScannerErrorCode.permissionDenied.message, contains('permission'));
      expect(MobileScannerErrorCode.unsupported.message, contains('not supported'));
    });

    test('fromPlatformException returns correct error code', () {
      // controllerAlreadyInitialized
      final alreadyStarted = PlatformException(
        code: 'MOBILE_SCANNER_ALREADY_STARTED_ERROR',
      );
      expect(
        MobileScannerErrorCode.fromPlatformException(alreadyStarted),
        MobileScannerErrorCode.controllerAlreadyInitialized,
      );

      // unsupported (no camera)
      final noCamera = PlatformException(
        code: 'MOBILE_SCANNER_NO_CAMERA_ERROR',
      );
      expect(
        MobileScannerErrorCode.fromPlatformException(noCamera),
        MobileScannerErrorCode.unsupported,
      );

      // permissionDenied
      final permissionDenied = PlatformException(
        code: 'MOBILE_SCANNER_CAMERA_PERMISSION_DENIED',
      );
      expect(
        MobileScannerErrorCode.fromPlatformException(permissionDenied),
        MobileScannerErrorCode.permissionDenied,
      );

      // genericError (unknown code)
      final unknown = PlatformException(code: 'UNKNOWN_ERROR');
      expect(
        MobileScannerErrorCode.fromPlatformException(unknown),
        MobileScannerErrorCode.genericError,
      );
    });
  });
}