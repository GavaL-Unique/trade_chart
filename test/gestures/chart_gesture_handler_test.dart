import 'package:flutter_test/flutter_test.dart';
import 'package:trade_chart/src/bridge/chart_bridge.dart';
import 'package:trade_chart/src/gestures/chart_gesture_handler.dart';
import 'package:trade_chart/src/gestures/gesture_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('gesture handler forwards pan updates immediately', (
    tester,
  ) async {
    final bridge = _FakeGestureBridge();
    final handler = ChartGestureHandler(bridge);

    expect(handler.mode, GestureMode.idle);

    await handler.handlePanUpdate(10);
    await handler.handlePanUpdate(5);

    expect(handler.mode, GestureMode.panning);
    expect(bridge.panDeltas, [10.0, 5.0]);

    await handler.handlePanEnd(1200);
    expect(handler.mode, GestureMode.idle);
    expect(bridge.panEndVelocities, [1200.0]);
  });

  testWidgets('crosshair updates only while active', (tester) async {
    final bridge = _FakeGestureBridge();
    final handler = ChartGestureHandler(bridge);

    await handler.handleCrosshairMove(10, 20);
    expect(bridge.crosshairMoves, isEmpty);

    await handler.handleCrosshairStart(10, 20);
    expect(handler.mode, GestureMode.crosshair);

    await handler.handleCrosshairMove(30, 40);
    await handler.handleCrosshairEnd();

    expect(handler.mode, GestureMode.idle);
    expect(bridge.crosshairStarts, [
      const _Point(10, 20),
    ]);
    expect(bridge.crosshairMoves, [
      const _Point(30, 40),
    ]);
    expect(bridge.crosshairEnds, 1);
  });

  testWidgets('pan then zoom sends pan then scale', (tester) async {
    final bridge = _FakeGestureBridge();
    final handler = ChartGestureHandler(bridge);

    await handler.handlePanUpdate(10);
    expect(handler.mode, GestureMode.panning);

    await handler.handleScaleUpdate(1.5, 100.0);
    expect(handler.mode, GestureMode.zooming);
    expect(bridge.panDeltas, [10.0]);
    expect(bridge.scaleUpdates, [const _Point(1.5, 100.0)]);
  });

  testWidgets('zoom ignores during crosshair', (tester) async {
    final bridge = _FakeGestureBridge();
    final handler = ChartGestureHandler(bridge);

    await handler.handleCrosshairStart(10, 20);
    await handler.handleScaleUpdate(2.0, 150.0);
    expect(bridge.scaleUpdates, isEmpty);
    expect(handler.mode, GestureMode.crosshair);
  });

  testWidgets('scale end resets to idle', (tester) async {
    final bridge = _FakeGestureBridge();
    final handler = ChartGestureHandler(bridge);

    await handler.handleScaleUpdate(1.3, 80.0);
    expect(handler.mode, GestureMode.zooming);

    await handler.handleScaleEnd();
    expect(handler.mode, GestureMode.idle);
    expect(bridge.scaleEndCount, 1);
  });
}

class _FakeGestureBridge implements ChartGestureBridge {
  final List<double> panDeltas = <double>[];
  final List<double> panEndVelocities = <double>[];
  final List<_Point> scaleUpdates = <_Point>[];
  int scaleEndCount = 0;
  final List<_Point> crosshairStarts = <_Point>[];
  final List<_Point> crosshairMoves = <_Point>[];
  int crosshairEnds = 0;

  @override
  Future<void> onCrosshairEnd() async {
    crosshairEnds += 1;
  }

  @override
  Future<void> onCrosshairMove(double x, double y) async {
    crosshairMoves.add(_Point(x, y));
  }

  @override
  Future<void> onCrosshairStart(double x, double y) async {
    crosshairStarts.add(_Point(x, y));
  }

  @override
  Future<void> onPanEnd(double velocityX) async {
    panEndVelocities.add(velocityX);
  }

  @override
  Future<void> onPanUpdate(double deltaX) async {
    panDeltas.add(deltaX);
  }

  @override
  Future<void> onScaleEnd() async {
    scaleEndCount += 1;
  }

  @override
  Future<void> onScaleUpdate(double scaleFactor, double focalPointX) async {
    scaleUpdates.add(_Point(scaleFactor, focalPointX));
  }
}

class _Point {
  const _Point(this.x, this.y);

  final double x;
  final double y;

  @override
  bool operator ==(Object other) =>
      other is _Point && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);
}
