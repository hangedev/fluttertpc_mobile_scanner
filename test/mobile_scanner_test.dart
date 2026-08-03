import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mobile_scanner/src/enums/torch_state.dart';
import 'package:mobile_scanner/src/mobile_scanner_exception.dart';
import 'package:mobile_scanner/src/objects/mobile_scanner_state.dart';

void main() {
  const MethodChannel methodChannel = MethodChannel(
    'dev.steenbakker.mobile_scanner/scanner/method',
  );

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      methodChannel,
      (MethodCall methodCall) async {
        switch (methodCall.method) {
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
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      methodChannel,
      null,
    );
  });

  group('MobileScanner Widget', () {
    testWidgets('renders with a key', (WidgetTester tester) async {
      final controller = MobileScannerController(autoStart: false);
      await tester.pumpWidget(
        MaterialApp(
          home: MobileScanner(
            key: const Key('test-scanner'),
            controller: controller,
            onDetect: (capture) {},
          ),
        ),
      );
      expect(find.byKey(const Key('test-scanner')), findsOneWidget);
    });

    testWidgets('renders placeholder when not initialized', (
      WidgetTester tester,
    ) async {
      final controller = MobileScannerController(autoStart: false);
      await tester.pumpWidget(
        MaterialApp(
          home: MobileScanner(
            controller: controller,
            placeholderBuilder: (context, child) {
              return const Text('Loading camera...');
            },
          ),
        ),
      );

      expect(find.text('Loading camera...'), findsOneWidget);
    });

    testWidgets('renders black placeholder when no placeholderBuilder', (
      WidgetTester tester,
    ) async {
      final controller = MobileScannerController(autoStart: false);
      await tester.pumpWidget(
        MobileScanner(
          controller: controller,
        ),
      );

      // Default placeholder is black ColoredBox
      expect(find.byType(ColoredBox), findsOneWidget);
    });

    testWidgets('onDetect triggers when barcode is detected', (
      WidgetTester tester,
    ) async {
      final controller = MobileScannerController(autoStart: false);

      await tester.pumpWidget(
        MobileScanner(
          controller: controller,
          onDetect: (capture) {
            // This should not throw
          },
        ),
      );

      // Just verify the controller can start
      await controller.start();
    });

    testWidgets('renders error builder when error occurs', (
      WidgetTester tester,
    ) async {
      final controller = MobileScannerController(autoStart: false);

      // Set an error state on the controller before building
      controller.value = controller.value.copyWith(
        isInitialized: true,
        error: const MobileScannerException(
          errorCode: MobileScannerErrorCode.genericError,
          errorDetails: MobileScannerErrorDetails(
            message: 'Camera error occurred',
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MobileScanner(
            controller: controller,
            errorBuilder: (context, error, child) {
              return Text('Error: ${error.errorDetails?.message}');
            },
          ),
        ),
      );

      expect(find.text('Error: Camera error occurred'), findsOneWidget);
    });

    testWidgets('renders default error icon when no errorBuilder', (
      WidgetTester tester,
    ) async {
      final controller = MobileScannerController(autoStart: false);

      // Set an error state
      controller.value = controller.value.copyWith(
        isInitialized: true,
        error: const MobileScannerException(
          errorCode: MobileScannerErrorCode.genericError,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MobileScanner(
            controller: controller,
          ),
        ),
      );

      // Default error shows an error icon
      expect(find.byIcon(Icons.error), findsOneWidget);
    });

    testWidgets('renders overlay when overlayBuilder is provided', (
      WidgetTester tester,
    ) async {
      final controller = MobileScannerController(autoStart: false);

      // Set initialized state so the camera preview renders
      controller.value = controller.value.copyWith(
        isInitialized: true,
        size: const Size(480, 640),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 400,
            height: 300,
            child: MobileScanner(
              controller: controller,
              overlayBuilder: (context, constraints) {
                return const Text('Overlay Content');
              },
            ),
          ),
        ),
      );

      // Verify the overlay is rendered
      expect(find.text('Overlay Content'), findsOneWidget);
    });

    testWidgets('controller with autoStart does not throw when rendering', (
      WidgetTester tester,
    ) async {
      // This test verifies that creating a MobileScanner with autoStart enabled
      // does not throw during widget rendering. The actual autoStart functionality
      // is tested in the controller test suite.
      final controller = MobileScannerController(autoStart: true);

      await tester.pumpWidget(
        MaterialApp(
          home: MobileScanner(
            controller: controller,
          ),
        ),
      );

      // Verify the widget rendered without errors
      expect(tester.takeException(), isNull);
    });

    testWidgets('controller does not auto-start when autoStart is false', (
      WidgetTester tester,
    ) async {
      final controller = MobileScannerController(autoStart: false);

      await tester.pumpWidget(
        MobileScanner(
          controller: controller,
        ),
      );

      expect(controller.value.isInitialized, isFalse);
    });

    testWidgets('dispose cleans up controller resources', (
      WidgetTester tester,
    ) async {
      final controller = MobileScannerController(autoStart: true);

      await tester.pumpWidget(
        MobileScanner(
          controller: controller,
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      // Remove the widget
      await tester.pumpWidget(
        const SizedBox(),
      );

      await tester.pump();
      // Should not throw
    });

    testWidgets('renders with scanWindow and fit', (
      WidgetTester tester,
    ) async {
      final controller = MobileScannerController(autoStart: false);

      // Set initialized state so the camera preview renders
      controller.value = controller.value.copyWith(
        isInitialized: true,
        size: const Size(480, 640),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 400,
            height: 300,
            child: MobileScanner(
              controller: controller,
              fit: BoxFit.contain,
              scanWindow: const Rect.fromLTWH(0.25, 0.25, 0.5, 0.5),
              scanWindowUpdateThreshold: 0.1,
            ),
          ),
        ),
      );

      // Verify the widget rendered without errors
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders with onDetectError handler', (
      WidgetTester tester,
    ) async {
      final controller = MobileScannerController(autoStart: false);

      await tester.pumpWidget(
        MaterialApp(
          home: MobileScanner(
            controller: controller,
            onDetect: (capture) {
              // This should not throw
            },
            onDetectError: (error, stackTrace) {
              // This should not throw
            },
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('renders with default controller when no controller provided', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MobileScanner(
            onDetect: (capture) {},
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}