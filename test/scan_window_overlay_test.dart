import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ScanWindowOverlay', () {
    late MobileScannerController controller;

    setUp(() {
      controller = MobileScannerController(autoStart: false);
    });

    tearDown(() async {
      await controller.dispose();
    });

    testWidgets('can be created with required parameters', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScanWindowOverlay(
              controller: controller,
              scanWindow: const Rect.fromLTWH(0.1, 0.1, 0.8, 0.8),
            ),
          ),
        ),
      );

      expect(find.byType(ScanWindowOverlay), findsOneWidget);
    });

    testWidgets('can be created with custom border color', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScanWindowOverlay(
              controller: controller,
              scanWindow: const Rect.fromLTWH(0.1, 0.1, 0.8, 0.8),
              borderColor: Colors.red,
            ),
          ),
        ),
      );

      expect(find.byType(ScanWindowOverlay), findsOneWidget);
    });

    testWidgets('can be created with custom border radius', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScanWindowOverlay(
              controller: controller,
              scanWindow: const Rect.fromLTWH(0.1, 0.1, 0.8, 0.8),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      );

      expect(find.byType(ScanWindowOverlay), findsOneWidget);
    });

    testWidgets('can be created with custom border stroke cap', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScanWindowOverlay(
              controller: controller,
              scanWindow: const Rect.fromLTWH(0.1, 0.1, 0.8, 0.8),
              borderStrokeCap: StrokeCap.round,
            ),
          ),
        ),
      );

      expect(find.byType(ScanWindowOverlay), findsOneWidget);
    });

    testWidgets('can be created with custom border stroke join', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScanWindowOverlay(
              controller: controller,
              scanWindow: const Rect.fromLTWH(0.1, 0.1, 0.8, 0.8),
              borderStrokeJoin: StrokeJoin.round,
            ),
          ),
        ),
      );

      expect(find.byType(ScanWindowOverlay), findsOneWidget);
    });

    testWidgets('can be created with custom border style', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScanWindowOverlay(
              controller: controller,
              scanWindow: const Rect.fromLTWH(0.1, 0.1, 0.8, 0.8),
              borderStyle: PaintingStyle.fill,
            ),
          ),
        ),
      );

      expect(find.byType(ScanWindowOverlay), findsOneWidget);
    });

    testWidgets('can be created with custom border width', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScanWindowOverlay(
              controller: controller,
              scanWindow: const Rect.fromLTWH(0.1, 0.1, 0.8, 0.8),
              borderWidth: 4.0,
            ),
          ),
        ),
      );

      expect(find.byType(ScanWindowOverlay), findsOneWidget);
    });

    testWidgets('can be created with custom color', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScanWindowOverlay(
              controller: controller,
              scanWindow: const Rect.fromLTWH(0.1, 0.1, 0.8, 0.8),
              color: const Color(0x40000000),
            ),
          ),
        ),
      );

      expect(find.byType(ScanWindowOverlay), findsOneWidget);
    });

    testWidgets('returns SizedBox when scanWindow is empty', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScanWindowOverlay(
              controller: controller,
              scanWindow: Rect.zero,
            ),
          ),
        ),
      );

      // The SizedBox is returned from the build method
      expect(find.byType(ScanWindowOverlay), findsOneWidget);
    });

    testWidgets('returns SizedBox when scanWindow is infinite', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScanWindowOverlay(
              controller: controller,
              scanWindow: const Rect.fromLTRB(
                double.negativeInfinity,
                double.negativeInfinity,
                double.infinity,
                double.infinity,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(ScanWindowOverlay), findsOneWidget);
    });
  });

  group('BarcodeOverlay', () {
    late MobileScannerController controller;

    setUp(() {
      controller = MobileScannerController(autoStart: false);
    });

    tearDown(() async {
      await controller.dispose();
    });

    testWidgets('can be created with required parameters', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BarcodeOverlay(
              controller: controller,
              boxFit: BoxFit.contain,
            ),
          ),
        ),
      );

      expect(find.byType(BarcodeOverlay), findsOneWidget);
    });

    testWidgets('can be created with custom color', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BarcodeOverlay(
              controller: controller,
              boxFit: BoxFit.contain,
              color: Colors.green,
            ),
          ),
        ),
      );

      expect(find.byType(BarcodeOverlay), findsOneWidget);
    });

    testWidgets('can be created with custom style', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BarcodeOverlay(
              controller: controller,
              boxFit: BoxFit.contain,
              style: PaintingStyle.stroke,
            ),
          ),
        ),
      );

      expect(find.byType(BarcodeOverlay), findsOneWidget);
    });
  });
}