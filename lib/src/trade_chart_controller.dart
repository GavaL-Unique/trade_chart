import 'dart:async';

import 'package:flutter/foundation.dart';

import 'bridge/chart_bridge.dart';
import 'events/crosshair_event.dart';
import 'events/viewport_event.dart';
import 'models/candle_data.dart';
import 'models/chart_marker.dart';
import 'models/chart_timeframe.dart';
import 'models/chart_type.dart';
import 'models/drawing_tool.dart';
import 'models/fullscreen_behavior.dart';
import 'models/indicator_config.dart';
import 'models/trade_chart_ui_state.dart';
import 'models/viewport_state.dart';
import 'trade_chart_config.dart';
import 'trade_chart_theme.dart';

class TradeChartController {
  /// Creates a controller for a single [TradeChart] instance.
  TradeChartController();

  ChartBridge? _bridge;
  StreamSubscription<ViewportChangeEvent>? _viewportSubscription;
  ViewportState? _currentViewport;
  bool _disposed = false;
  TradeChartConfig _lastConfig = const TradeChartConfig();
  TradeChartTheme _lastTheme = const TradeChartTheme.dark();
  final StreamController<bool> _fullscreenRequests =
      StreamController<bool>.broadcast();
  final ValueNotifier<TradeChartUiState> _uiState =
      ValueNotifier<TradeChartUiState>(const TradeChartUiState());

  /// Stream of crosshair updates during long-press gestures.
  Stream<CrosshairEvent> get onCrosshairUpdate =>
      _bridge?.crosshairStream ?? const Stream<CrosshairEvent>.empty();

  @Deprecated(
    'Use onCrosshairUpdate instead. This alias will be removed in a future release.',
  )
  Stream<CrosshairEvent> get crosshairEvents =>
      _bridge?.crosshairStream ?? const Stream<CrosshairEvent>.empty();

  /// Stream of viewport updates after load, pan, zoom, resize, and scroll.
  Stream<ViewportChangeEvent> get onViewportChange =>
      _bridge?.viewportStream ?? const Stream<ViewportChangeEvent>.empty();

  @Deprecated(
    'Use onViewportChange instead. This alias will be removed in a future release.',
  )
  Stream<ViewportChangeEvent> get viewportEvents =>
      _bridge?.viewportStream ?? const Stream<ViewportChangeEvent>.empty();

  bool get isAttached => _bridge != null;
  ViewportState? get currentViewport => _currentViewport;
  TradeChartConfig get currentConfig => _lastConfig;
  TradeChartTheme get currentTheme => _lastTheme;
  ValueListenable<TradeChartUiState> get uiStateListenable => _uiState;
  Stream<bool> get fullscreenRequests => _fullscreenRequests.stream;
  bool get isFullscreen => _uiState.value.isFullscreen;
  bool get isDrawingMode => _uiState.value.isDrawingMode;
  DrawingTool get activeDrawingTool => _uiState.value.activeDrawingTool;
  List<IndicatorConfig> get indicators => _uiState.value.indicators;
  List<DrawingObject> get drawings => _uiState.value.drawings;
  ChartTimeframe? get selectedTimeframe => _uiState.value.selectedTimeframe;
  bool get isCrosshairEnabled => _uiState.value.crosshairEnabled;

  void attachBridge(ChartBridge bridge) {
    _ensureNotDisposed();
    final existingBridge = _bridge;
    if (existingBridge != null && !identical(existingBridge, bridge)) {
      throw StateError(
        'TradeChartController is already attached to another TradeChart.',
      );
    }
    _bridge = bridge;
    _viewportSubscription?.cancel();
    _viewportSubscription = bridge.viewportStream.listen((event) {
      _currentViewport = event.viewport;
    });
  }

  void detachBridge(ChartBridge bridge) {
    if (identical(_bridge, bridge)) {
      _bridge = null;
      _viewportSubscription?.cancel();
      _viewportSubscription = null;
    }
  }

  Future<void> loadCandles(List<CandleData> candles, ChartTimeframe timeframe) {
    if (candles.isEmpty) {
      debugPrint('TradeChartController.loadCandles ignored an empty dataset.');
      return Future<void>.value();
    }
    _validateCandles(candles);
    return _requireBridge().loadCandles(candles, timeframe);
  }

  Future<void> appendCandle(CandleData candle) {
    _validateCandle(candle);
    return _requireBridge().appendCandle(candle);
  }

  Future<void> updateLastCandle(CandleData candle) {
    _validateCandle(candle);
    return _requireBridge().updateLastCandle(candle);
  }

  Future<void> setMarkers(List<ChartMarker> markers) {
    _validateMarkers(markers);
    return _requireBridge().setMarkers(markers);
  }

  Future<void> addMarker(ChartMarker marker) {
    _validateMarker(marker);
    return _requireBridge().addMarker(marker);
  }

  Future<void> clearMarkers() {
    return _requireBridge().clearMarkers();
  }

  Future<void> setChartType(ChartType chartType) {
    return _requireBridge().setChartType(chartType);
  }

  Future<void> setTimeframe(ChartTimeframe timeframe) {
    _setUiState(_uiState.value.copyWith(selectedTimeframe: timeframe));
    return _requireBridge().setTimeframe(timeframe);
  }

  Future<void> setTheme(TradeChartTheme theme) {
    _lastTheme = theme;
    return _requireBridge().setTheme(theme);
  }

  Future<void> setConfig(TradeChartConfig config) {
    _lastConfig = config;
    _setUiState(
      _uiState.value.copyWith(crosshairEnabled: config.enableCrosshair),
    );
    return _requireBridge().setConfig(config);
  }

  Future<void> scrollToEnd() {
    return _requireBridge().scrollToEnd();
  }

  void setInitialPresentation({
    required TradeChartConfig config,
    required TradeChartTheme theme,
    FullscreenBehavior fullscreenBehavior = const FullscreenBehavior(),
  }) {
    _lastConfig = config;
    _lastTheme = theme;
    _setUiState(
      _uiState.value.copyWith(
        crosshairEnabled: config.enableCrosshair,
        fullscreenBehavior: fullscreenBehavior,
      ),
    );
  }

  void enterFullscreen() {
    _setUiState(_uiState.value.copyWith(isFullscreen: true));
    _fullscreenRequests.add(true);
  }

  void exitFullscreen() {
    _setUiState(_uiState.value.copyWith(isFullscreen: false));
    _fullscreenRequests.add(false);
  }

  void toggleDrawingMode() {
    _setUiState(
      _uiState.value.copyWith(isDrawingMode: !_uiState.value.isDrawingMode),
    );
  }

  void setDrawingTool(DrawingTool tool) {
    _setUiState(
      _uiState.value.copyWith(
        activeDrawingTool: tool,
        isDrawingMode: tool != DrawingTool.none,
      ),
    );
  }

  void setDrawings(List<DrawingObject> drawings) {
    _setUiState(_uiState.value.copyWith(drawings: drawings));
  }

  void clearDrawings() {
    _setUiState(_uiState.value.copyWith(drawings: const <DrawingObject>[]));
  }

  void addIndicator(IndicatorConfig indicator) {
    final indicators = List<IndicatorConfig>.of(_uiState.value.indicators);
    final existingIndex =
        indicators.indexWhere((item) => item.kind == indicator.kind);
    if (existingIndex >= 0) {
      indicators[existingIndex] = indicator;
    } else {
      indicators.add(indicator);
    }
    _setUiState(_uiState.value.copyWith(indicators: indicators));
  }

  void removeIndicator(IndicatorKind kind) {
    final indicators = _uiState.value.indicators
        .where((item) => item.kind != kind)
        .toList(growable: false);
    _setUiState(_uiState.value.copyWith(indicators: indicators));
  }

  Future<void> setCrosshairEnabled(bool enabled) async {
    _lastConfig = _lastConfig.copyWith(enableCrosshair: enabled);
    _setUiState(_uiState.value.copyWith(crosshairEnabled: enabled));
    final bridge = _bridge;
    if (bridge != null) {
      await bridge.setConfig(_lastConfig);
    }
  }

  Map<String, Object?> saveUiState() => _uiState.value.toJson();

  void restoreUiState(Map<String, Object?> json) {
    final timeframeName = json['selectedTimeframe'] as String?;
    _setUiState(
      _uiState.value.copyWith(
        isFullscreen: json['isFullscreen'] as bool? ?? false,
        isDrawingMode: json['isDrawingMode'] as bool? ?? false,
        activeDrawingTool: DrawingTool.values.byName(
          json['activeDrawingTool'] as String? ?? DrawingTool.none.name,
        ),
        selectedTimeframe: timeframeName == null
            ? null
            : ChartTimeframe.values.byName(timeframeName),
        crosshairEnabled: json['crosshairEnabled'] as bool? ?? true,
        indicators: (json['indicators'] as List<Object?>? ?? const [])
            .cast<Map<String, Object?>>()
            .map(IndicatorConfig.fromJson)
            .toList(growable: false),
        drawings: (json['drawings'] as List<Object?>? ?? const [])
            .cast<Map<String, Object?>>()
            .map(DrawingObject.fromJson)
            .toList(growable: false),
      ),
    );
  }

  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _viewportSubscription?.cancel();
    _viewportSubscription = null;
    final bridge = _bridge;
    _bridge = null;
    _currentViewport = null;
    if (bridge != null) {
      unawaited(bridge.dispose());
    }
    unawaited(_fullscreenRequests.close());
    _uiState.dispose();
  }

  ChartBridge _requireBridge() {
    _ensureNotDisposed();
    final bridge = _bridge;
    if (bridge == null) {
      throw StateError('TradeChartController is not attached to a TradeChart.');
    }
    return bridge;
  }

  void _ensureNotDisposed() {
    if (_disposed) {
      throw StateError('TradeChartController has been disposed.');
    }
  }

  void _setUiState(TradeChartUiState state) {
    if (_uiState.value == state) {
      return;
    }
    _uiState.value = state;
  }

  static void _validateCandles(List<CandleData> candles) {
    var previousTimestamp = -1;
    for (final candle in candles) {
      _validateCandle(candle);
      if (candle.timestamp <= previousTimestamp) {
        throw ArgumentError(
          'Candles must be sorted by strictly increasing timestamp.',
          'candles',
        );
      }
      previousTimestamp = candle.timestamp;
    }
  }

  static void _validateCandle(CandleData candle) {
    if (candle.timestamp < 0) {
      throw ArgumentError.value(
        candle.timestamp,
        'candle.timestamp',
        'must be >= 0.',
      );
    }
    if (!candle.open.isFinite ||
        !candle.high.isFinite ||
        !candle.low.isFinite ||
        !candle.close.isFinite ||
        !candle.volume.isFinite) {
      throw ArgumentError.value(
          candle, 'candle', 'must contain finite values.');
    }
    if (candle.volume < 0) {
      throw ArgumentError.value(
        candle.volume,
        'candle.volume',
        'must be >= 0.',
      );
    }
    if (candle.high < candle.low ||
        candle.high < candle.open ||
        candle.high < candle.close ||
        candle.low > candle.open ||
        candle.low > candle.close) {
      throw ArgumentError.value(
        candle,
        'candle',
        'must satisfy low <= open/close <= high.',
      );
    }
  }

  static void _validateMarkers(List<ChartMarker> markers) {
    final ids = <String>{};
    for (final marker in markers) {
      _validateMarker(marker);
      if (!ids.add(marker.id)) {
        throw ArgumentError.value(
          markers,
          'markers',
          'must not contain duplicate marker ids.',
        );
      }
    }
  }

  static void _validateMarker(ChartMarker marker) {
    if (marker.id.isEmpty) {
      throw ArgumentError.value(marker.id, 'marker.id', 'must not be empty.');
    }
    if (marker.timestamp < 0) {
      throw ArgumentError.value(
        marker.timestamp,
        'marker.timestamp',
        'must be >= 0.',
      );
    }
    if (!marker.price.isFinite) {
      throw ArgumentError.value(
        marker.price,
        'marker.price',
        'must be finite.',
      );
    }
    if (marker.label != null && marker.label!.isEmpty) {
      throw ArgumentError.value(
        marker.label,
        'marker.label',
        'must not be empty when provided.',
      );
    }
  }
}
