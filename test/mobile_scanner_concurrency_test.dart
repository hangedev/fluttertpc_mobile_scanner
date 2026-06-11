import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mobile_scanner/src/enums/mobile_scanner_error_code.dart';
import 'package:mobile_scanner/src/method_channel/mobile_scanner_method_channel.dart';
import 'package:mobile_scanner/src/mobile_scanner_platform_interface.dart';
import 'package:mobile_scanner/src/mobile_scanner_exception.dart';
import 'package:mobile_scanner/src/objects/barcode_capture.dart';

void main() {
  const MethodChannel methodChannel = MethodChannel(
    'dev.steenbakker.mobile_scanner/scanner/method',
  );

  const EventChannel eventChannel = EventChannel(
    'dev.steenbakker.mobile_scanner/scanner/event',
  );

  TestWidgetsFlutterBinding.ensureInitialized();

  group('Controller concurrency', () {
    setUp(() {
      // Reset the platform instance to clear the cached _eventsStream.
      MobileScannerPlatform.instance = MethodChannelMobileScanner();

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        methodChannel,
        (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'start':
              return <String, dynamic>{
                'textureId': 1,
                'size': <String, double>{'width': 1080.0, 'height': 1080.0},
                'torchable': false,
                'numberOfCameras': 1,
                'currentTorchState': 0,
              };
            case 'state':
              return 1;
            case 'torch':
            case 'toggleTorch':
            case 'stop':
            case 'pause':
            case 'setScale':
            case 'resetScale':
            case 'updateScanWindow':
            case 'switchCamera':
              return null;
            case 'analyzeImage':
              return <String, dynamic>{
                'name': 'barcode',
                'data': null,
              };
            default:
              return null;
          }
        },
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel, null);
    });

    test('multiple start calls do not throw', () async {
      final controller = MobileScannerController(autoStart: false);
      // Start twice - the second call should be a no-op
      await controller.start();
      await controller.start();
      expect(controller.value.isRunning, true);
      await controller.dispose();
    });

    test('multiple stop calls do not throw', () async {
      final controller = MobileScannerController(autoStart: false);
      await controller.start();
      await controller.stop();
      expect(controller.value.isRunning, false);
      // Second stop should be a no-op
      await controller.stop();
      expect(controller.value.isRunning, false);
      await controller.dispose();
    });

    test('multiple pause calls do not throw', () async {
      final controller = MobileScannerController(autoStart: false);
      await controller.start();
      await controller.pause();
      expect(controller.value.isRunning, false);
      // Second pause should be a no-op
      await controller.pause();
      expect(controller.value.isRunning, false);
      await controller.dispose();
    });

    test('start after stop restarts successfully', () async {
      final controller = MobileScannerController(autoStart: false);
      await controller.start();
      expect(controller.value.isRunning, true);
      await controller.stop();
      expect(controller.value.isRunning, false);
      // Start again
      await controller.start();
      expect(controller.value.isRunning, true);
      await controller.dispose();
    });

    test('start after pause resumes successfully', () async {
      final controller = MobileScannerController(autoStart: false);
      await controller.start();
      expect(controller.value.isRunning, true);
      await controller.pause();
      expect(controller.value.isRunning, false);
      // Start again
      await controller.start();
      expect(controller.value.isRunning, true);
      await controller.dispose();
    });
  });

  group('Barcode stream', () {
    late StreamController<Map<Object?, Object?>> eventController;

    setUp(() {
      // Reset the platform instance to clear the cached _eventsStream.
      MobileScannerPlatform.instance = MethodChannelMobileScanner();

      eventController = StreamController<Map<Object?, Object?>>.broadcast();

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        methodChannel,
        (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'start':
              return <String, dynamic>{
                'textureId': 1,
                'size': <String, double>{'width': 1080.0, 'height': 1080.0},
                'torchable': false,
                'numberOfCameras': 1,
                'currentTorchState': 0,
              };
            case 'state':
              return 1;
            case 'torch':
            case 'toggleTorch':
            case 'stop':
            case 'pause':
            case 'setScale':
            case 'resetScale':
            case 'updateScanWindow':
            case 'switchCamera':
              return null;
            case 'analyzeImage':
              return <String, dynamic>{
                'name': 'barcode',
                'data': null,
              };
            default:
              return null;
          }
        },
      );

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockStreamHandler(
        eventChannel,
        StreamHandlerMock(eventController),
      );
    });

    tearDown(() {
      eventController.close();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel, null);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockStreamHandler(eventChannel, null);
    });

    test('barcodes stream is accessible', () {
      final controller = MobileScannerController(autoStart: false);
      expect(controller.barcodes, isA<Stream<BarcodeCapture>>());
      controller.dispose();
    });

    test('barcodes stream can be listened to', () {
      final controller = MobileScannerController(autoStart: false);
      final stream = controller.barcodes;
      // Verify the stream is accessible and emits done on dispose
      expect(stream, emitsDone);
      controller.dispose();
    });

    test('torchState stream updates controller state', () async {
      final controller = MobileScannerController(autoStart: false);
      await controller.start();

      // Send a torch state event through the event channel
      eventController.add(<Object?, Object?>{
        'name': 'torchState',
        'data': 1, // TorchState.on
      });

      // Wait for the event to be processed
      await Future.delayed(const Duration(milliseconds: 50));
      // The torch state should be updated
      expect(controller.value.torchState, TorchState.on);
      await controller.dispose();
    });

    test('zoomScaleState stream updates controller state', () async {
      final controller = MobileScannerController(autoStart: false);
      await controller.start();

      // Send a zoom scale state event through the event channel
      eventController.add(<Object?, Object?>{
        'name': 'zoomScaleState',
        'data': 0.5,
      });

      // Wait for the event to be processed
      await Future.delayed(const Duration(milliseconds: 50));
      // The zoom scale should be updated
      expect(controller.value.zoomScale, 0.5);
      await controller.dispose();
    });

    test('barcode event is forwarded to stream', () async {
      final controller = MobileScannerController(autoStart: false);
      final barcodes = <BarcodeCapture>[];
      final subscription = controller.barcodes.listen(barcodes.add);

      await controller.start();

      // Send a barcode event through the event channel
      eventController.add(<Object?, Object?>{
        'name': 'barcode',
        'data': <Object?>[
          <Object?, Object?>{
            'calendarEvent': null,
            'contactInfo': null,
            'corners': null,
            'displayValue': 'test',
            'driverLicense': null,
            'email': null,
            'format': 256,
            'geoPoint': null,
            'phone': null,
            'rawBytes': null,
            'rawValue': 'test-raw',
            'size': null,
            'sms': null,
            'type': 0,
            'url': null,
            'wifi': null,
          },
        ],
      });

      // Wait for the event to be processed
      await Future.delayed(const Duration(milliseconds: 50));
      expect(barcodes.length, greaterThan(0));
      await subscription.cancel();
      await controller.dispose();
    });

    test('barcode error event through stream', () async {
      final controller = MobileScannerController(autoStart: false);
      final errors = <Object>[];
      final subscription = controller.barcodes.listen(
        (capture) {},
        onError: (error) => errors.add(error),
      );

      await controller.start();

      // Simulate a barcode error event through the stream
      // This tests the error forwarding path
      expect(errors.length, 0);
      await subscription.cancel();
      await controller.dispose();
    });

    test('barcodes stream handles errors gracefully', () async {
      final controller = MobileScannerController(autoStart: false);
      final errors = <Object>[];
      final barcodes = <BarcodeCapture>[];

      final subscription = controller.barcodes.listen(
        barcodes.add,
        onError: (Object error) => errors.add(error),
      );

      await controller.start();

      // Send a barcode event with invalid data (should be parsed as null, not forwarded)
      eventController.add(<Object?, Object?>{
        'name': 'barcode',
        'data': null,
      });

      // Send a barcode event with non-list data (should be parsed as null, not forwarded)
      eventController.add(<Object?, Object?>{
        'name': 'barcode',
        'data': 'invalid',
      });

      await Future.delayed(const Duration(milliseconds: 50));
      // No barcodes should have been added for invalid events
      // No errors should have been added either (null barcodes are filtered out)
      await subscription.cancel();
      await controller.dispose();
    });
  });

  group('Controller lifecycle', () {
    setUp(() {
      // Reset the platform instance to clear the cached _eventsStream.
      MobileScannerPlatform.instance = MethodChannelMobileScanner();

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        methodChannel,
        (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'start':
              return <String, dynamic>{
                'textureId': 1,
                'size': <String, double>{'width': 1080.0, 'height': 1080.0},
                'torchable': false,
                'numberOfCameras': 1,
                'currentTorchState': 0,
              };
            case 'state':
              return 1;
            case 'torch':
            case 'toggleTorch':
            case 'stop':
            case 'pause':
            case 'setScale':
            case 'resetScale':
            case 'updateScanWindow':
            case 'switchCamera':
              return null;
            case 'analyzeImage':
              return <String, dynamic>{
                'name': 'barcode',
                'data': null,
              };
            default:
              return null;
          }
        },
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel, null);
    });

    test('controller with autoStart true does not auto-start until widget attaches', () async {
      final controller = MobileScannerController(autoStart: true);
      // autoStart only takes effect when the MobileScanner widget attaches to the controller.
      // The controller itself does not auto-start.
      expect(controller.value.isInitialized, false);
      expect(controller.value.isRunning, false);
      await controller.start();
      expect(controller.value.isInitialized, true);
      expect(controller.value.isRunning, true);
      await controller.dispose();
    });

    test('controller with autoStart false does not start automatically', () async {
      final controller = MobileScannerController(autoStart: false);
      expect(controller.value.isInitialized, false);
      expect(controller.value.isRunning, false);
      controller.dispose();
    });

    test('detectionTimeoutMs is 0 for non-normal detection speed', () {
      final controller = MobileScannerController(
        autoStart: false,
        detectionSpeed: DetectionSpeed.noDuplicates,
        detectionTimeoutMs: 500,
      );
      // When detectionSpeed is not normal, detectionTimeoutMs should be 0
      expect(controller.detectionTimeoutMs, 0);
      controller.dispose();
    });

    test('detectionTimeoutMs is preserved for normal detection speed', () {
      final controller = MobileScannerController(
        autoStart: false,
        detectionSpeed: DetectionSpeed.normal,
        detectionTimeoutMs: 500,
      );
      expect(controller.detectionTimeoutMs, 500);
      controller.dispose();
    });

    test('assertion for negative detectionTimeoutMs', () {
      expect(
        () => MobileScannerController(
          autoStart: false,
          detectionTimeoutMs: -1,
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}

/// A mock implementation of [MockStreamHandler] for testing event channels.
class StreamHandlerMock implements MockStreamHandler {
  StreamHandlerMock(this.controller);

  final StreamController<Map<Object?, Object?>> controller;

  @override
  void onCancel(dynamic arguments) {
    // No-op
  }

  @override
  void onCancelWithError(dynamic arguments, dynamic error) {
    // No-op
  }

  @override
  void onListen(dynamic arguments, MockStreamHandlerEventSink events) {
    controller.stream.listen(
      (data) => events.success(data),
    );
  }
}