import 'package:flutter/foundation.dart';

import 'models/chart_type.dart';

@immutable
class TradeChartConfig {
  const TradeChartConfig({
    this.showVolume = true,
    this.showGrid = true,
    this.enableCrosshair = true,
    this.showAxis = true,
    this.volumeHeightRatio = 0.2,
    this.maxVisibleCandles = 300,
    this.minVisibleCandles = 20,
    this.initialChartType = ChartType.candle,
    this.yAxisPaddingRatio = 0.1,
    this.autoScrollOnAppend = true,
  })  : assert(
          volumeHeightRatio > 0 && volumeHeightRatio < 1,
          'volumeHeightRatio must be > 0 and < 1.',
        ),
        assert(minVisibleCandles >= 1, 'minVisibleCandles must be >= 1.'),
        assert(
          maxVisibleCandles >= minVisibleCandles,
          'maxVisibleCandles must be >= minVisibleCandles.',
        ),
        assert(
          yAxisPaddingRatio >= 0,
          'yAxisPaddingRatio must be >= 0.',
        );

  final bool showVolume;
  final bool showGrid;
  final bool enableCrosshair;
  final bool showAxis;
  final double volumeHeightRatio;
  final int maxVisibleCandles;
  final int minVisibleCandles;
  final ChartType initialChartType;
  final double yAxisPaddingRatio;
  final bool autoScrollOnAppend;

  TradeChartConfig copyWith({
    bool? showVolume,
    bool? showGrid,
    bool? enableCrosshair,
    bool? showAxis,
    double? volumeHeightRatio,
    int? maxVisibleCandles,
    int? minVisibleCandles,
    ChartType? initialChartType,
    double? yAxisPaddingRatio,
    bool? autoScrollOnAppend,
  }) {
    return TradeChartConfig(
      showVolume: showVolume ?? this.showVolume,
      showGrid: showGrid ?? this.showGrid,
      enableCrosshair: enableCrosshair ?? this.enableCrosshair,
      showAxis: showAxis ?? this.showAxis,
      volumeHeightRatio: volumeHeightRatio ?? this.volumeHeightRatio,
      maxVisibleCandles: maxVisibleCandles ?? this.maxVisibleCandles,
      minVisibleCandles: minVisibleCandles ?? this.minVisibleCandles,
      initialChartType: initialChartType ?? this.initialChartType,
      yAxisPaddingRatio: yAxisPaddingRatio ?? this.yAxisPaddingRatio,
      autoScrollOnAppend: autoScrollOnAppend ?? this.autoScrollOnAppend,
    );
  }
}
