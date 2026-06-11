import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mobile_scanner/src/enums/mobile_scanner_error_code.dart';
import 'package:mobile_scanner/src/mobile_scanner_exception.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MobileScanner Widget', () {
    test('can be created with default parameters', () {
      const scanner = MobileScanner();
      expect(scanner, isNotNull);
      expect(scanner.controller, isNull);
      expect(scanner.fit, BoxFit.cover);
      expect(scanner.scanWindow, isNull);
      expect(scanner.scanWindowUpdateThreshold, 0.0);
      expect(scanner.onDetect, isNull);
      expect(scanner.errorBuilder, isNull);
      expect(scanner.overlayBuilder, isNull);
      expect(scanner.placeholderBuilder, isNull);
    });

    test('can be created with controller', () {
      final controller = MobileScannerController(autoStart: false);
      final scanner = MobileScanner(controller: controller);
      expect(scanner, isNotNull);
      expect(scanner.controller, controller);
      controller.dispose();
    });

    test('can be created with onDetect callback', () {
      bool called = false;
      final controller = MobileScannerController(autoStart: false);
      final scanner = MobileScanner(
        controller: controller,
        onDetect: (capture) {
          called = true;
        },
      );
      expect(scanner, isNotNull);
      expect(scanner.onDetect, isNotNull);
      controller.dispose();
    });

    test('can be created with onDetectError callback', () {
      final controller = MobileScannerController(autoStart: false);
      final scanner = MobileScanner(
        controller: controller,
        onDetect: (capture) {},
        onDetectError: (Object error, StackTrace stack) {},
      );
      expect(scanner, isNotNull);
      expect(scanner.onDetectError, isNotNull);
      controller.dispose();
    });

    test('can be created with errorBuilder', () {
      final controller = MobileScannerController(autoStart: false);
      final scanner = MobileScanner(
        controller: controller,
        errorBuilder: (BuildContext context, MobileScannerException error, Widget? child) {
          return const Text('Custom error');
        },
      );
      expect(scanner, isNotNull);
      expect(scanner.errorBuilder, isNotNull);
      controller.dispose();
    });

    test('can be created with overlayBuilder', () {
      final controller = MobileScannerController(autoStart: false);
      final scanner = MobileScanner(
        controller: controller,
        overlayBuilder: (BuildContext context, BoxConstraints constraints) {
          return const Text('Overlay');
        },
      );
      expect(scanner, isNotNull);
      expect(scanner.overlayBuilder, isNotNull);
      controller.dispose();
    });

    test('can be created with placeholderBuilder', () {
      final controller = MobileScannerController(autoStart: false);
      final scanner = MobileScanner(
        controller: controller,
        placeholderBuilder: (BuildContext context, Widget? child) {
          return const Text('Loading...');
        },
      );
      expect(scanner, isNotNull);
      expect(scanner.placeholderBuilder, isNotNull);
      controller.dispose();
    });

    test('can be created with scanWindow', () {
      final controller = MobileScannerController(autoStart: false);
      const scanWindow = Rect.fromLTWH(0.0, 0.0, 100.0, 100.0);
      final scanner = MobileScanner(
        controller: controller,
        scanWindow: scanWindow,
      );
      expect(scanner, isNotNull);
      expect(scanner.scanWindow, scanWindow);
      controller.dispose();
    });

    test('can be created with scanWindowUpdateThreshold', () {
      final controller = MobileScannerController(autoStart: false);
      final scanner = MobileScanner(
        controller: controller,
        scanWindowUpdateThreshold: 10.0,
      );
      expect(scanner, isNotNull);
      expect(scanner.scanWindowUpdateThreshold, 10.0);
      controller.dispose();
    });

    test('can be created with all custom parameters', () {
      final controller = MobileScannerController(autoStart: false);
      final scanner = MobileScanner(
        controller: controller,
        onDetect: (capture) {},
        onDetectError: (Object error, StackTrace stack) {},
        fit: BoxFit.contain,
        errorBuilder: (BuildContext context, MobileScannerException error, Widget? child) {
          return const Text('Custom error');
        },
        overlayBuilder: (BuildContext context, BoxConstraints constraints) {
          return const Text('Overlay');
        },
        placeholderBuilder: (BuildContext context, Widget? child) {
          return const Text('Loading...');
        },
        scanWindow: Rect.fromLTWH(0.0, 0.0, 100.0, 100.0),
        scanWindowUpdateThreshold: 5.0,
      );
      expect(scanner, isNotNull);
      expect(scanner.controller, controller);
      expect(scanner.fit, BoxFit.contain);
      expect(scanner.scanWindow, isNotNull);
      expect(scanner.scanWindowUpdateThreshold, 5.0);
      controller.dispose();
    });
  });

  group('MobileScanner lifecycle', () {
    test('controller creates widget without error', () {
      final controller = MobileScannerController(autoStart: false);
      expect(() => MobileScanner(controller: controller), isNot(throwsException));
      controller.dispose();
    });

    test('default onDetectError is a no-op', () {
      const scanner = MobileScanner();
      // Verify the default error handler exists and is a static function
      expect(scanner.onDetectError, isNotNull);
    });

    test('MobileScannerErrorBuilder typedef is valid', () {
      // Verify the typedef can be used
      final MobileScannerErrorBuilder builder = (
        BuildContext context,
        MobileScannerException error,
        Widget? child,
      ) {
        return const SizedBox();
      };
      expect(builder, isNotNull);
    });
  });
}