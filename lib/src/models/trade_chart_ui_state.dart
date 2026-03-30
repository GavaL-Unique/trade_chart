import 'package:flutter/foundation.dart';

import 'chart_timeframe.dart';
import 'drawing_tool.dart';
import 'fullscreen_behavior.dart';
import 'indicator_config.dart';
import 'viewport_state.dart';

@immutable
class TradeChartUiState {
  const TradeChartUiState({
    this.isFullscreen = false,
    this.isDrawingMode = false,
    this.activeDrawingTool = DrawingTool.none,
    this.selectedTimeframe,
    this.crosshairEnabled = true,
    this.indicators = const <IndicatorConfig>[],
    this.drawings = const <DrawingObject>[],
    this.fullscreenBehavior = const FullscreenBehavior(),
    this.restoredViewport,
  });

  final bool isFullscreen;
  final bool isDrawingMode;
  final DrawingTool activeDrawingTool;
  final ChartTimeframe? selectedTimeframe;
  final bool crosshairEnabled;
  final List<IndicatorConfig> indicators;
  final List<DrawingObject> drawings;
  final FullscreenBehavior fullscreenBehavior;
  final ViewportState? restoredViewport;

  TradeChartUiState copyWith({
    bool? isFullscreen,
    bool? isDrawingMode,
    DrawingTool? activeDrawingTool,
    Object? selectedTimeframe = _sentinel,
    bool? crosshairEnabled,
    List<IndicatorConfig>? indicators,
    List<DrawingObject>? drawings,
    FullscreenBehavior? fullscreenBehavior,
    Object? restoredViewport = _sentinel,
  }) {
    return TradeChartUiState(
      isFullscreen: isFullscreen ?? this.isFullscreen,
      isDrawingMode: isDrawingMode ?? this.isDrawingMode,
      activeDrawingTool: activeDrawingTool ?? this.activeDrawingTool,
      selectedTimeframe: identical(selectedTimeframe, _sentinel)
          ? this.selectedTimeframe
          : selectedTimeframe as ChartTimeframe?,
      crosshairEnabled: crosshairEnabled ?? this.crosshairEnabled,
      indicators: indicators ?? this.indicators,
      drawings: drawings ?? this.drawings,
      fullscreenBehavior: fullscreenBehavior ?? this.fullscreenBehavior,
      restoredViewport: identical(restoredViewport, _sentinel)
          ? this.restoredViewport
          : restoredViewport as ViewportState?,
    );
  }

  Map<String, Object?> toJson() => {
        'isFullscreen': isFullscreen,
        'isDrawingMode': isDrawingMode,
        'activeDrawingTool': activeDrawingTool.name,
        'selectedTimeframe': selectedTimeframe?.name,
        'crosshairEnabled': crosshairEnabled,
        'indicators': indicators.map((item) => item.toJson()).toList(),
        'drawings': drawings.map((item) => item.toJson()).toList(),
        'restoredViewport': restoredViewport == null
            ? null
            : {
                'startTimestamp': restoredViewport!.startTimestamp,
                'endTimestamp': restoredViewport!.endTimestamp,
                'priceHigh': restoredViewport!.priceHigh,
                'priceLow': restoredViewport!.priceLow,
                'visibleCandleCount': restoredViewport!.visibleCandleCount,
                'candleWidth': restoredViewport!.candleWidth,
                'isAtLatest': restoredViewport!.isAtLatest,
              },
      };

  static const Object _sentinel = Object();
}
