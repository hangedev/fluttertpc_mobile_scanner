import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mobile_scanner/src/method_channel/mobile_scanner_method_channel.dart';
import 'package:mocktail/mocktail.dart';

class MockMobileScannerController extends Mock
    implements MobileScannerController {
  @override
  Widget buildCameraView() {
    return const Placeholder(
      fallbackHeight: 100,
      fallbackWidth: 100,
      color: Color(0xFF00FF00),
    );
  }
}

class MockMethodChannelMobileScanner extends MethodChannelMobileScanner {
  @override
  Future<void> stop({bool force = false}) async {
    // Do nothing instead of calling platform code
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockMobileScannerController mockController;
  late StreamController<BarcodeCapture> barcodeStreamController;

  setUp(() {
    MobileScannerPlatform.instance = MockMethodChannelMobileScanner();
    mockController = MockMobileScannerController();
    barcodeStreamController = StreamController<BarcodeCapture>.broadcast();

    when(() => mockController.autoStart).thenReturn(true);
    when(
      () => mockController.barcodes,
    ).thenAnswer((_) => barcodeStreamController.stream);
    when(() => mockController.value).thenReturn(
      const MobileScannerState(
        availableCameras: 2,
        cameraDirection: CameraFacing.back,
        isInitialized: true,
        isStarting: false,
        isRunning: true,
        size: Size(1920, 1080),
        torchState: TorchState.off,
        zoomScale: 1,
        deviceOrientation: DeviceOrientation.portraitUp,
      ),
    );
    when(() => mockController.start()).thenAnswer((_) async {});
    when(() => mockController.stop()).thenAnswer((_) async {});
    when(() => mockController.dispose()).thenAnswer((_) async {});
    when(() => mockController.toggleTorch()).thenAnswer((_) async {});
    when(() => mockController.switchCamera()).thenAnswer((_) async {});
    when(() => mockController.updateScanWindow(any())).thenAnswer((_) async {});
  });

  tearDown(() {
    unawaited(barcodeStreamController.close());
  });

  group('MobileScanner Widget Tests', () {
    testWidgets('calls onDetect when barcode is scanned', (tester) async {
      var wasCalled = false;
      final barcodeStreamController = StreamController<BarcodeCapture>();

      when(
        () => mockController.barcodes,
      ).thenAnswer((_) => barcodeStreamController.stream);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MobileScanner(
              controller: mockController,
              onDetect: (_) {
                wasCalled = true;
              },
            ),
          ),
        ),
      );

      barcodeStreamController.add(const BarcodeCapture());
      await tester.pump();

      expect(wasCalled, isTrue);
      await barcodeStreamController.close();
    });

    testWidgets('displays error UI when an error occurs', (tester) async {
      const exception = MobileScannerException(
        errorCode: MobileScannerErrorCode.controllerUninitialized,
      );

      when(() => mockController.value).thenReturn(
        const MobileScannerState(
          availableCameras: 2,
          cameraDirection: CameraFacing.back,
          isInitialized: true,
          isStarting: false,
          isRunning: false,
          size: Size.zero,
          torchState: TorchState.unavailable,
          zoomScale: 1,
          error: exception,
          deviceOrientation: DeviceOrientation.portraitUp,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: MobileScanner(controller: mockController)),
        ),
      );

      await tester.pump();

      expect(find.byIcon(Icons.error), findsOneWidget);
    });

    testWidgets('disposes properly when no controller is provided', (
      tester,
    ) async {
      const testWidget = MaterialApp(home: Scaffold(body: MobileScanner()));

      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();
      await tester.pumpWidget(
        Container(),
      ); // Remove the widget to trigger disposal

      expect(tester.takeException(), isNull);

      // Since MobileScanner created its own controller, it should be disposed.
      // However, we cannot verify it directly because it's internal.
      // Instead, we ensure there is no exception.
    });

    testWidgets('does not dispose externally provided controller', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: MobileScanner(controller: mockController)),
        ),
      );

      await tester.pumpAndSettle();
      await tester.pumpWidget(Container()); // Remove the widget

      // Verify that dispose() was NOT called because it's externally managed
      verifyNever(() => mockController.dispose());
    });
  });

  // TODO(juliansteenbakker): Improve tests in new PR
  group('MobileScannerController Tests', () {
    testWidgets('buildCameraView() returns a widget', (tester) async {
      final widget = mockController.buildCameraView();
      expect(widget, isA<Widget>());
    });

    testWidgets('toggleTorch() can be called', (tester) async {
      await mockController.toggleTorch();
      verify(() => mockController.toggleTorch()).called(1);
    });

    testWidgets('switchCamera() can be called', (tester) async {
      await mockController.switchCamera();
      verify(() => mockController.switchCamera()).called(1);
    });

    testWidgets('updateScanWindow() can be called', (tester) async {
      const scanWindow = Rect.fromLTWH(10, 10, 100, 100);
      await mockController.updateScanWindow(scanWindow);
      verify(() => mockController.updateScanWindow(scanWindow)).called(1);
    });
  });
}
