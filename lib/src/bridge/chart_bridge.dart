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
  ChartBridge({ChartHostApi? hostApi})
      : _hostApi = hostApi ?? ChartHostApi(),
        chartId = _nextChartId++;

  static int _nextChartId = 1;

  final int chartId;
  final ChartHostApi _hostApi;
  final StreamController<ViewportChangeEvent> _viewportController =
      StreamController<ViewportChangeEvent>.broadcast();
  final StreamController<CrosshairEvent> _crosshairController =
      StreamController<CrosshairEvent>.broadcast();

  _ChartBridgeCallbacks _callbacks = const _ChartBridgeCallbacks();
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
    updateCallbacks(
      onChartReady: onChartReady,
      onViewportChanged: onViewportChanged,
      onCrosshairData: onCrosshairData,
      onError: onError,
    );
    _ChartFlutterDispatcher.instance.registerBridge(this);

    _initialized = true;
    try {
      return await _hostApi.initialize(
        ChartInitParams(
          chartId: chartId,
          width: width,
          height: height,
          devicePixelRatio: devicePixelRatio,
          theme: BridgeMapper.themeToMessage(theme),
          config: BridgeMapper.configToMessage(config),
        ),
      );
    } catch (_) {
      _initialized = false;
      _ChartFlutterDispatcher.instance.unregisterBridge(chartId);
      rethrow;
    }
  }

  void updateCallbacks({
    ChartReadyCallback? onChartReady,
    ViewportChangedCallback? onViewportChanged,
    CrosshairChangedCallback? onCrosshairData,
    ChartErrorCallback? onError,
  }) {
    _callbacks = _ChartBridgeCallbacks(
      onChartReady: onChartReady,
      onViewportChanged: onViewportChanged,
      onCrosshairData: onCrosshairData,
      onError: onError,
    );
  }

  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _ChartFlutterDispatcher.instance.unregisterBridge(chartId);
    if (_initialized) {
      await _hostApi.dispose(chartId);
    }
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
    return _hostApi.onSizeChanged(chartId, width, height);
  }

  Future<void> loadCandles(List<CandleData> candles, ChartTimeframe timeframe) {
    _ensureInitialized();
    return _hostApi.loadCandles(
      chartId,
      BridgeMapper.candlesToMessage(candles, timeframe),
    );
  }

  Future<void> appendCandle(CandleData candle) {
    _ensureInitialized();
    return _hostApi.appendCandle(chartId, BridgeMapper.candleToMessage(candle));
  }

  Future<void> updateLastCandle(CandleData candle) {
    _ensureInitialized();
    return _hostApi.updateLastCandle(
      chartId,
      BridgeMapper.candleToMessage(candle),
    );
  }

  Future<void> setMarkers(List<ChartMarker> markers) {
    _ensureInitialized();
    return _hostApi.setMarkers(chartId, BridgeMapper.markersToMessage(markers));
  }

  Future<void> addMarker(ChartMarker marker) {
    _ensureInitialized();
    return _hostApi.addMarker(chartId, BridgeMapper.markerToMessage(marker));
  }

  Future<void> clearMarkers() {
    _ensureInitialized();
    return _hostApi.clearMarkers(chartId);
  }

  Future<void> setChartType(ChartType chartType) {
    _ensureInitialized();
    return _hostApi.setChartType(chartId, chartType.name);
  }

  Future<void> setTimeframe(ChartTimeframe timeframe) {
    _ensureInitialized();
    return _hostApi.setTimeframe(chartId, timeframe.name);
  }

  Future<void> setTheme(TradeChartTheme theme) {
    _ensureInitialized();
    return _hostApi.setTheme(chartId, BridgeMapper.themeToMessage(theme));
  }

  Future<void> setConfig(TradeChartConfig config) {
    _ensureInitialized();
    return _hostApi.setConfig(chartId, BridgeMapper.configToMessage(config));
  }

  Future<void> scrollToEnd() {
    _ensureInitialized();
    return _hostApi.scrollToEnd(chartId);
  }

  @override
  Future<void> onPanUpdate(double deltaX) {
    _ensureInitialized();
    return _hostApi.onPanUpdate(chartId, deltaX);
  }

  @override
  Future<void> onPanEnd(double velocityX) {
    _ensureInitialized();
    return _hostApi.onPanEnd(chartId, velocityX);
  }

  @override
  Future<void> onScaleUpdate(double scaleFactor, double focalPointX) {
    _ensureInitialized();
    return _hostApi.onScaleUpdate(chartId, scaleFactor, focalPointX);
  }

  @override
  Future<void> onScaleEnd() {
    _ensureInitialized();
    return _hostApi.onScaleEnd(chartId);
  }

  @override
  Future<void> onCrosshairStart(double x, double y) {
    _ensureInitialized();
    return _hostApi.onCrosshairStart(chartId, x, y);
  }

  @override
  Future<void> onCrosshairMove(double x, double y) {
    _ensureInitialized();
    return _hostApi.onCrosshairMove(chartId, x, y);
  }

  @override
  Future<void> onCrosshairEnd() {
    _ensureInitialized();
    return _hostApi.onCrosshairEnd(chartId);
  }

  void handleChartReady() {
    _callbacks.onChartReady?.call();
  }

  void handleCrosshairData(CrosshairDataMessage data) {
    final event = BridgeMapper.crosshairFromMessage(data);
    if (!_crosshairController.isClosed) {
      _crosshairController.add(event);
    }
    _callbacks.onCrosshairData?.call(event);
  }

  void handleError(String code, String message) {
    _callbacks.onError?.call(code, message);
  }

  void handleViewportChanged(ViewportStateMessage viewport) {
    final event = ViewportChangeEvent(
      viewport: BridgeMapper.viewportFromMessage(viewport),
      isAtLatest: viewport.isAtLatest,
    );
    if (!_viewportController.isClosed) {
      _viewportController.add(event);
    }
    _callbacks.onViewportChanged?.call(event);
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

class _ChartBridgeCallbacks {
  const _ChartBridgeCallbacks({
    this.onChartReady,
    this.onViewportChanged,
    this.onCrosshairData,
    this.onError,
  });

  final ChartReadyCallback? onChartReady;
  final ViewportChangedCallback? onViewportChanged;
  final CrosshairChangedCallback? onCrosshairData;
  final ChartErrorCallback? onError;
}

class _ChartFlutterDispatcher extends ChartFlutterApi {
  _ChartFlutterDispatcher._();

  static final _ChartFlutterDispatcher instance = _ChartFlutterDispatcher._();

  final Map<int, ChartBridge> _bridges = <int, ChartBridge>{};
  bool _installed = false;

  void registerBridge(ChartBridge bridge) {
    _bridges[bridge.chartId] = bridge;
    if (_installed) {
      return;
    }
    ChartFlutterApi.setUp(this);
    _installed = true;
  }

  void unregisterBridge(int chartId) {
    _bridges.remove(chartId);
    if (_bridges.isEmpty && _installed) {
      ChartFlutterApi.setUp(null);
      _installed = false;
    }
  }

  @override
  void onChartReady(int chartId) {
    _bridges[chartId]?.handleChartReady();
  }

  @override
  void onCrosshairData(int chartId, CrosshairDataMessage data) {
    _bridges[chartId]?.handleCrosshairData(data);
  }

  @override
  void onError(int chartId, String code, String message) {
    _bridges[chartId]?.handleError(code, message);
  }

  @override
  void onViewportChanged(int chartId, ViewportStateMessage viewport) {
    _bridges[chartId]?.handleViewportChanged(viewport);
  }
}
