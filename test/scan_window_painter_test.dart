import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/overlay/scan_window_painter.dart';
import 'package:mocktail/mocktail.dart';

class MockCanvas extends Mock implements Canvas {}

void main() {
  setUpAll(() {
    registerFallbackValue(Paint());
    registerFallbackValue(Offset.zero);
    registerFallbackValue(Path());
    registerFallbackValue(Rect.zero);
    registerFallbackValue(RRect.zero);
  });

  group('ScanWindowPainter', () {
    group('constructor', () {
      test('creates instance with required parameters', () {
        const painter = ScanWindowPainter(
          borderColor: Colors.white,
          borderRadius: BorderRadius.zero,
          borderStrokeCap: StrokeCap.butt,
          borderStrokeJoin: StrokeJoin.miter,
          borderStyle: PaintingStyle.stroke,
          borderWidth: 2.0,
          color: Color(0x80000000),
          scanWindow: Rect.fromLTWH(0.1, 0.1, 0.8, 0.8),
        );

        expect(painter.borderColor, Colors.white);
        expect(painter.borderRadius, BorderRadius.zero);
        expect(painter.borderStrokeCap, StrokeCap.butt);
        expect(painter.borderStrokeJoin, StrokeJoin.miter);
        expect(painter.borderStyle, PaintingStyle.stroke);
        expect(painter.borderWidth, 2.0);
        expect(painter.color, const Color(0x80000000));
        expect(painter.scanWindow, const Rect.fromLTWH(0.1, 0.1, 0.8, 0.8));
      });

      test('creates instance with custom border radius', () {
        const painter = ScanWindowPainter(
          borderColor: Colors.red,
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderStrokeCap: StrokeCap.round,
          borderStrokeJoin: StrokeJoin.round,
          borderStyle: PaintingStyle.fill,
          borderWidth: 3.0,
          color: Color(0x40000000),
          scanWindow: Rect.fromLTWH(0.2, 0.2, 0.6, 0.6),
        );

        expect(painter.borderColor, Colors.red);
        expect(
          painter.borderRadius,
          const BorderRadius.all(Radius.circular(10)),
        );
        expect(painter.borderStrokeCap, StrokeCap.round);
        expect(painter.borderStrokeJoin, StrokeJoin.round);
        expect(painter.borderStyle, PaintingStyle.fill);
        expect(painter.borderWidth, 3.0);
        expect(painter.color, const Color(0x40000000));
        expect(painter.scanWindow, const Rect.fromLTWH(0.2, 0.2, 0.6, 0.6));
      });
    });

    group('paint', () {
      testWidgets('draws overlay with cutout for normal scan window', (
        tester,
      ) async {
        final mockCanvas = MockCanvas();

        const painter = ScanWindowPainter(
          borderColor: Colors.white,
          borderRadius: BorderRadius.zero,
          borderStrokeCap: StrokeCap.butt,
          borderStrokeJoin: StrokeJoin.miter,
          borderStyle: PaintingStyle.stroke,
          borderWidth: 2.0,
          color: Color(0x80000000),
          scanWindow: Rect.fromLTWH(25, 25, 50, 50),
        );

        painter.paint(mockCanvas, const Size(100, 100));

        verify(() => mockCanvas.drawPath(any(), any())).called(1);
        verify(() => mockCanvas.drawRRect(any(), any())).called(1);
      });

      testWidgets('does not draw when scanWindow is empty', (tester) async {
        final mockCanvas = MockCanvas();

        const painter = ScanWindowPainter(
          borderColor: Colors.white,
          borderRadius: BorderRadius.zero,
          borderStrokeCap: StrokeCap.butt,
          borderStrokeJoin: StrokeJoin.miter,
          borderStyle: PaintingStyle.stroke,
          borderWidth: 2.0,
          color: Color(0x80000000),
          scanWindow: Rect.zero,
        );

        painter.paint(mockCanvas, const Size(100, 100));

        verifyNever(() => mockCanvas.drawPath(any(), any()));
        verifyNever(() => mockCanvas.drawRRect(any(), any()));
      });

      testWidgets('does not draw when scanWindow is infinite', (tester) async {
        final mockCanvas = MockCanvas();

        final painter = ScanWindowPainter(
          borderColor: Colors.white,
          borderRadius: BorderRadius.zero,
          borderStrokeCap: StrokeCap.butt,
          borderStrokeJoin: StrokeJoin.miter,
          borderStyle: PaintingStyle.stroke,
          borderWidth: 2.0,
          color: const Color(0x80000000),
          scanWindow: Rect.fromLTRB(
            double.negativeInfinity,
            double.negativeInfinity,
            double.infinity,
            double.infinity,
          ),
        );

        painter.paint(mockCanvas, const Size(100, 100));

        verifyNever(() => mockCanvas.drawPath(any(), any()));
        verifyNever(() => mockCanvas.drawRRect(any(), any()));
      });

      testWidgets('draws with custom border radius', (tester) async {
        final mockCanvas = MockCanvas();

        const painter = ScanWindowPainter(
          borderColor: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderStrokeCap: StrokeCap.round,
          borderStrokeJoin: StrokeJoin.round,
          borderStyle: PaintingStyle.stroke,
          borderWidth: 3.0,
          color: Color(0x80000000),
          scanWindow: Rect.fromLTWH(10, 10, 80, 80),
        );

        painter.paint(mockCanvas, const Size(100, 100));

        verify(() => mockCanvas.drawPath(any(), any())).called(1);
        verify(() => mockCanvas.drawRRect(any(), any())).called(1);
      });
    });

    group('shouldRepaint', () {
      test('returns true when scanWindow changes', () {
        const painter1 = ScanWindowPainter(
          borderColor: Colors.white,
          borderRadius: BorderRadius.zero,
          borderStrokeCap: StrokeCap.butt,
          borderStrokeJoin: StrokeJoin.miter,
          borderStyle: PaintingStyle.stroke,
          borderWidth: 2.0,
          color: Color(0x80000000),
          scanWindow: Rect.fromLTWH(0.1, 0.1, 0.8, 0.8),
        );

        const painter2 = ScanWindowPainter(
          borderColor: Colors.white,
          borderRadius: BorderRadius.zero,
          borderStrokeCap: StrokeCap.butt,
          borderStrokeJoin: StrokeJoin.miter,
          borderStyle: PaintingStyle.stroke,
          borderWidth: 2.0,
          color: Color(0x80000000),
          scanWindow: Rect.fromLTWH(0.2, 0.2, 0.6, 0.6),
        );

        expect(painter1.shouldRepaint(painter2), isTrue);
      });

      test('returns true when color changes', () {
        const painter1 = ScanWindowPainter(
          borderColor: Colors.white,
          borderRadius: BorderRadius.zero,
          borderStrokeCap: StrokeCap.butt,
          borderStrokeJoin: StrokeJoin.miter,
          borderStyle: PaintingStyle.stroke,
          borderWidth: 2.0,
          color: Color(0x80000000),
          scanWindow: Rect.fromLTWH(0.1, 0.1, 0.8, 0.8),
        );

        const painter2 = ScanWindowPainter(
          borderColor: Colors.white,
          borderRadius: BorderRadius.zero,
          borderStrokeCap: StrokeCap.butt,
          borderStrokeJoin: StrokeJoin.miter,
          borderStyle: PaintingStyle.stroke,
          borderWidth: 2.0,
          color: Color(0x40000000),
          scanWindow: Rect.fromLTWH(0.1, 0.1, 0.8, 0.8),
        );

        expect(painter1.shouldRepaint(painter2), isTrue);
      });

      test('returns true when borderRadius changes', () {
        const painter1 = ScanWindowPainter(
          borderColor: Colors.white,
          borderRadius: BorderRadius.zero,
          borderStrokeCap: StrokeCap.butt,
          borderStrokeJoin: StrokeJoin.miter,
          borderStyle: PaintingStyle.stroke,
          borderWidth: 2.0,
          color: Color(0x80000000),
          scanWindow: Rect.fromLTWH(0.1, 0.1, 0.8, 0.8),
        );

        const painter2 = ScanWindowPainter(
          borderColor: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(5)),
          borderStrokeCap: StrokeCap.butt,
          borderStrokeJoin: StrokeJoin.miter,
          borderStyle: PaintingStyle.stroke,
          borderWidth: 2.0,
          color: Color(0x80000000),
          scanWindow: Rect.fromLTWH(0.1, 0.1, 0.8, 0.8),
        );

        expect(painter1.shouldRepaint(painter2), isTrue);
      });

      test('returns false when all properties are the same', () {
        const painter1 = ScanWindowPainter(
          borderColor: Colors.white,
          borderRadius: BorderRadius.zero,
          borderStrokeCap: StrokeCap.butt,
          borderStrokeJoin: StrokeJoin.miter,
          borderStyle: PaintingStyle.stroke,
          borderWidth: 2.0,
          color: Color(0x80000000),
          scanWindow: Rect.fromLTWH(0.1, 0.1, 0.8, 0.8),
        );

        const painter2 = ScanWindowPainter(
          borderColor: Colors.white,
          borderRadius: BorderRadius.zero,
          borderStrokeCap: StrokeCap.butt,
          borderStrokeJoin: StrokeJoin.miter,
          borderStyle: PaintingStyle.stroke,
          borderWidth: 2.0,
          color: Color(0x80000000),
          scanWindow: Rect.fromLTWH(0.1, 0.1, 0.8, 0.8),
        );

        expect(painter1.shouldRepaint(painter2), isFalse);
      });
    });
  });
}