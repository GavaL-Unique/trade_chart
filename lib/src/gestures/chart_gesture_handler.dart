import '../bridge/chart_bridge.dart';
import 'gesture_state.dart';

class ChartGestureHandler {
  ChartGestureHandler(this._bridge);

  final ChartGestureBridge _bridge;

  GestureMode mode = GestureMode.idle;

  /// Forwards each pan delta immediately so native can paint on the same frame
  /// (no [SchedulerBinding.addPostFrameCallback] batching — that added ~1 frame lag).
  Future<void> handlePanUpdate(double deltaX) {
    if (mode == GestureMode.zooming || mode == GestureMode.crosshair) {
      return Future<void>.value();
    }
    mode = GestureMode.panning;
    return _bridge.onPanUpdate(deltaX);
  }

  Future<void> handlePanEnd(double velocityX) {
    mode = GestureMode.idle;
    return _bridge.onPanEnd(velocityX);
  }

  Future<void> handleScaleUpdate(double scaleFactor, double focalPointX) {
    if (mode == GestureMode.crosshair) {
      return Future<void>.value();
    }
    mode = GestureMode.zooming;
    return _bridge.onScaleUpdate(scaleFactor, focalPointX);
  }

  Future<void> handleScaleEnd() {
    mode = GestureMode.idle;
    return _bridge.onScaleEnd();
  }

  Future<void> handleCrosshairStart(double x, double y) {
    if (mode != GestureMode.idle) {
      return Future<void>.value();
    }
    mode = GestureMode.crosshair;
    return _bridge.onCrosshairStart(x, y);
  }

  Future<void> handleCrosshairMove(double x, double y) {
    if (mode != GestureMode.crosshair) {
      return Future<void>.value();
    }
    return _bridge.onCrosshairMove(x, y);
  }

  Future<void> handleCrosshairEnd() {
    if (mode != GestureMode.crosshair) {
      mode = GestureMode.idle;
      return Future<void>.value();
    }
    mode = GestureMode.idle;
    return _bridge.onCrosshairEnd();
  }
}
