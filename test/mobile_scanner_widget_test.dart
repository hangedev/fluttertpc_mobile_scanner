import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MobileScanner Widget Extended', () {
    late MobileScannerController controller;

    setUp(() {
      controller = MobileScannerController(autoStart: false);
    });

    tearDown(() async {
      await controller.dispose();
    });

    testWidgets('displays placeholder when controller is not initialized', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MobileScanner(controller: controller),
          ),
        ),
      );

      expect(controller.value.isInitialized, false);
    });

    testWidgets('can be created with onDetectError callback', (tester) async {
      Object? capturedError;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MobileScanner(
              controller: controller,
              onDetectError: (error, stackTrace) {
                capturedError = error;
              },
            ),
          ),
        ),
      );

      expect(capturedError, isNull);
    });

    testWidgets('can be created with fit property', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MobileScanner(
              controller: controller,
              fit: BoxFit.cover,
            ),
          ),
        ),
      );

      expect(find.byType(MobileScanner), findsOneWidget);
    });

    testWidgets('can be created with scanWindow', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MobileScanner(
              controller: controller,
              scanWindow: const Rect.fromLTWH(0.1, 0.1, 0.8, 0.8),
            ),
          ),
        ),
      );

      expect(find.byType(MobileScanner), findsOneWidget);
    });

    testWidgets('can be created with placeholderBuilder', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MobileScanner(
              controller: controller,
              placeholderBuilder: (context) =>
                  const Text('Custom Placeholder'),
            ),
          ),
        ),
      );

      expect(find.text('Custom Placeholder'), findsOneWidget);
    });

    testWidgets('can be created with overlayBuilder', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MobileScanner(
              controller: controller,
              overlayBuilder: (context, constraints) =>
                  const Text('Overlay Content'),
            ),
          ),
        ),
      );

      // Overlay is only visible when camera is initialized
      expect(controller.value.isInitialized, false);
    });

    testWidgets('can be created with scanWindowUpdateThreshold', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MobileScanner(
              controller: controller,
              scanWindow: const Rect.fromLTWH(0.1, 0.1, 0.8, 0.8),
              scanWindowUpdateThreshold: 5.0,
            ),
          ),
        ),
      );

      expect(find.byType(MobileScanner), findsOneWidget);
    });

    testWidgets('can be created with useAppLifecycleState false', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MobileScanner(
              controller: controller,
              useAppLifecycleState: false,
            ),
          ),
        ),
      );

      expect(find.byType(MobileScanner), findsOneWidget);
    });

    testWidgets('can be created with onDetect callback', (tester) async {
      BarcodeCapture? capturedBarcode;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MobileScanner(
              controller: controller,
              onDetect: (barcode) {
                capturedBarcode = barcode;
              },
            ),
          ),
        ),
      );

      expect(find.byType(MobileScanner), findsOneWidget);
    });

    testWidgets('can be created with errorBuilder', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MobileScanner(
              controller: controller,
              errorBuilder: (context, error) =>
                  const Text('Custom Error Widget'),
            ),
          ),
        ),
      );

      expect(find.byType(MobileScanner), findsOneWidget);
    });

    testWidgets('can be created with tapToFocus enabled', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MobileScanner(
              controller: controller,
              tapToFocus: true,
            ),
          ),
        ),
      );

      expect(find.byType(MobileScanner), findsOneWidget);
    });

    testWidgets('can be created without controller', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MobileScanner(),
          ),
        ),
      );

      expect(find.byType(MobileScanner), findsOneWidget);
    });
  });
}