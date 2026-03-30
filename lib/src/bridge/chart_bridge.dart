import 'dart:async';

import '../events/crosshair_event.dart';
import '../events/viewport_event.dart';
import '../models/candle_data.dart';
import '../models/chart_marker.dart';
import '../models/chart_timeframe.dart';
import '../models/chart_type.dart';
import '../trade_chart_config.dart';
import '../trade_chart_theme.dart';
import 'bridge_mapper.dart';
import 'generated/chart_api.g.dart';

typedef ChartReadyCallback = void Function();
typedef ViewportChangedCallback = void Function(ViewportChangeEvent event);
typedef CrosshairChangedCallback = void Function(CrosshairEvent event);
typedef ChartErrorCallback = void Function(String code, String message);

abstract class ChartGestureBridge {
  Future<void> onPanUpdate(double deltaX);
  Future<void> onPanEnd(double velocityX);
  Future<void> onScaleUpdate(double scaleFactor, double focalPointX);
  Future<void> onScaleEnd();
  Future<void> onCrosshairStart(double x, double y);
  Future<void> onCrosshairMove(double x, double y);
  Future<void> onCrosshairEnd();
}

class ChartBridge implements ChartGestureBridge {
  ChartBridge({ChartHostApi? hostApi}) : _hostApi = hostApi ?? ChartHostApi();

  final ChartHostApi _hostApi;
  final StreamController<ViewportChangeEvent> _viewportController =
      StreamController<ViewportChangeEvent>.broadcast();
  final StreamController<CrosshairEvent> _crosshairController =
      StreamController<CrosshairEvent>.broadcast();

  _ChartFlutterApiHandler? _flutterHandler;
  bool _disposed = false;
  bool _initialized = false;

  Stream<ViewportChangeEvent> get viewportStream => _viewportController.stream;
  Stream<CrosshairEvent> get crosshairStream => _crosshairController.stream;

  Future<int> initialize({
    required double width,
    required double height,
    required double devicePixelRatio,
    required TradeChartTheme theme,
    required TradeChartConfig config,
    ChartReadyCallback? onChartReady,
    ViewportChangedCallback? onViewportChanged,
    CrosshairChangedCallback? onCrosshairData,
    ChartErrorCallback? onError,
  }) async {
    _ensureNotDisposed();
    if (width <= 0 || height <= 0) {
      throw ArgumentError(
        'ChartBridge.initialize requires width and height greater than zero.',
      );
    }
    if (!devicePixelRatio.isFinite || devicePixelRatio <= 0) {
      throw ArgumentError.value(
        devicePixelRatio,
        'devicePixelRatio',
        'must be finite and greater than zero.',
      );
    }
    _flutterHandler = _ChartFlutterApiHandler(
      viewportSink: _viewportController,
      crosshairSink: _crosshairController,
      onChartReadyCallback: onChartReady,
      onViewportChangedCallback: onViewportChanged,
      onCrosshairDataCallback: onCrosshairData,
      onErrorCallback: onError,
    );
    ChartFlutterApi.setUp(_flutterHandler);

    _initialized = true;
    try {
      return await _hostApi.initialize(
        ChartInitParams(
          width: width,
          height: height,
          devicePixelRatio: devicePixelRatio,
          theme: BridgeMapper.themeToMessage(theme),
          config: BridgeMapper.configToMessage(config),
        ),
      );
    } catch (_) {
      _initialized = false;
      rethrow;
    }
  }

  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    if (_initialized) {
      await _hostApi.dispose();
    }
    ChartFlutterApi.setUp(null);
    await _viewportController.close();
    await _crosshairController.close();
    _initialized = false;
    _disposed = true;
  }

  Future<void> onSizeChanged(double width, double height) {
    _ensureInitialized();
    if (width <= 0 || height <= 0) {
      return Future<void>.value();
    }
    return _hostApi.onSizeChanged(width, height);
  }

  Future<void> loadCandles(List<CandleData> candles, ChartTimeframe timeframe) {
    _ensureInitialized();
    return _hostApi.loadCandles(
      BridgeMapper.candlesToMessage(candles, timeframe),
    );
  }

  Future<void> appendCandle(CandleData candle) {
    _ensureInitialized();
    return _hostApi.appendCandle(BridgeMapper.candleToMessage(candle));
  }

  Future<void> updateLastCandle(CandleData candle) {
    _ensureInitialized();
    return _hostApi.updateLastCandle(BridgeMapper.candleToMessage(candle));
  }

  Future<void> setMarkers(List<ChartMarker> markers) {
    _ensureInitialized();
    return _hostApi.setMarkers(BridgeMapper.markersToMessage(markers));
  }

  Future<void> addMarker(ChartMarker marker) {
    _ensureInitialized();
    return _hostApi.addMarker(BridgeMapper.markerToMessage(marker));
  }

  Future<void> clearMarkers() {
    _ensureInitialized();
    return _hostApi.clearMarkers();
  }

  Future<void> setChartType(ChartType chartType) {
    _ensureInitialized();
    return _hostApi.setChartType(chartType.name);
  }

  Future<void> setTimeframe(ChartTimeframe timeframe) {
    _ensureInitialized();
    return _hostApi.setTimeframe(timeframe.name);
  }

  Future<void> setTheme(TradeChartTheme theme) {
    _ensureInitialized();
    return _hostApi.setTheme(BridgeMapper.themeToMessage(theme));
  }

  Future<void> setConfig(TradeChartConfig config) {
    _ensureInitialized();
    return _hostApi.setConfig(BridgeMapper.configToMessage(config));
  }

  Future<void> scrollToEnd() {
    _ensureInitialized();
    return _hostApi.scrollToEnd();
  }

  @override
  Future<void> onPanUpdate(double deltaX) {
    _ensureInitialized();
    return _hostApi.onPanUpdate(deltaX);
  }

  @override
  Future<void> onPanEnd(double velocityX) {
    _ensureInitialized();
    return _hostApi.onPanEnd(velocityX);
  }

  @override
  Future<void> onScaleUpdate(double scaleFactor, double focalPointX) {
    _ensureInitialized();
    return _hostApi.onScaleUpdate(scaleFactor, focalPointX);
  }

  @override
  Future<void> onScaleEnd() {
    _ensureInitialized();
    return _hostApi.onScaleEnd();
  }

  @override
  Future<void> onCrosshairStart(double x, double y) {
    _ensureInitialized();
    return _hostApi.onCrosshairStart(x, y);
  }

  @override
  Future<void> onCrosshairMove(double x, double y) {
    _ensureInitialized();
    return _hostApi.onCrosshairMove(x, y);
  }

  @override
  Future<void> onCrosshairEnd() {
    _ensureInitialized();
    return _hostApi.onCrosshairEnd();
  }

  void _ensureInitialized() {
    _ensureNotDisposed();
    if (!_initialized) {
      throw StateError('Chart bridge has not been initialized.');
    }
  }

  void _ensureNotDisposed() {
    if (_disposed) {
      throw StateError('Chart bridge has been disposed.');
    }
  }
}

class _ChartFlutterApiHandler extends ChartFlutterApi {
  _ChartFlutterApiHandler({
    required this.viewportSink,
    required this.crosshairSink,
    this.onChartReadyCallback,
    this.onViewportChangedCallback,
    this.onCrosshairDataCallback,
    this.onErrorCallback,
  });

  final StreamController<ViewportChangeEvent> viewportSink;
  final StreamController<CrosshairEvent> crosshairSink;
  final ChartReadyCallback? onChartReadyCallback;
  final ViewportChangedCallback? onViewportChangedCallback;
  final CrosshairChangedCallback? onCrosshairDataCallback;
  final ChartErrorCallback? onErrorCallback;

  @override
  void onChartReady() {
    onChartReadyCallback?.call();
  }

  @override
  void onCrosshairData(CrosshairDataMessage data) {
    final event = BridgeMapper.crosshairFromMessage(data);
    crosshairSink.add(event);
    onCrosshairDataCallback?.call(event);
  }

  @override
  void onError(String code, String message) {
    onErrorCallback?.call(code, message);
  }

  @override
  void onViewportChanged(ViewportStateMessage viewport) {
    final event = ViewportChangeEvent(
      viewport: BridgeMapper.viewportFromMessage(viewport),
      isAtLatest: viewport.isAtLatest,
    );
    viewportSink.add(event);
    onViewportChangedCallback?.call(event);
  }
}
