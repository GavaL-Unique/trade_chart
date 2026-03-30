import '../events/crosshair_event.dart';
import '../models/candle_data.dart';
import '../models/chart_marker.dart';
import '../models/chart_timeframe.dart';
import '../models/viewport_state.dart';
import '../trade_chart_config.dart';
import '../trade_chart_theme.dart';
import 'generated/chart_api.g.dart';

class BridgeMapper {
  static CandleDataMessage candleToMessage(CandleData candle) {
    return CandleDataMessage(
      timestamp: candle.timestamp,
      open: candle.open,
      high: candle.high,
      low: candle.low,
      close: candle.close,
      volume: candle.volume,
    );
  }

  static CandleDataListMessage candlesToMessage(
    List<CandleData> candles,
    ChartTimeframe timeframe,
  ) {
    return CandleDataListMessage(
      candles: candles.map(candleToMessage).toList(growable: false),
      timeframe: timeframe.name,
    );
  }

  static MarkerMessage markerToMessage(ChartMarker marker) {
    return MarkerMessage(
      id: marker.id,
      timestamp: marker.timestamp,
      price: marker.price,
      type: marker.type.name,
      label: marker.label,
    );
  }

  static MarkerListMessage markersToMessage(List<ChartMarker> markers) {
    return MarkerListMessage(
      markers: markers.map(markerToMessage).toList(growable: false),
    );
  }

  static ThemeMessage themeToMessage(TradeChartTheme theme) {
    return ThemeMessage(
      backgroundColorArgb: theme.backgroundColor.toARGB32(),
      gridColorArgb: theme.gridColor.toARGB32(),
      bullColorArgb: theme.bullColor.toARGB32(),
      bearColorArgb: theme.bearColor.toARGB32(),
      volumeBullColorArgb: theme.volumeBullColor.toARGB32(),
      volumeBearColorArgb: theme.volumeBearColor.toARGB32(),
      crosshairColorArgb: theme.crosshairColor.toARGB32(),
      crosshairLabelBgColorArgb: theme.crosshairLabelBackgroundColor.toARGB32(),
      textColorArgb: theme.textColor.toARGB32(),
      axisColorArgb: theme.axisColor.toARGB32(),
      buyMarkerColorArgb: theme.buyMarkerColor.toARGB32(),
      sellMarkerColorArgb: theme.sellMarkerColor.toARGB32(),
      axisTextSize: theme.axisTextSize,
      crosshairTextSize: theme.crosshairTextSize,
    );
  }

  static ConfigMessage configToMessage(TradeChartConfig config) {
    return ConfigMessage(
      showVolume: config.showVolume,
      showGrid: config.showGrid,
      enableCrosshair: config.enableCrosshair,
      showAxis: config.showAxis,
      volumeHeightRatio: config.volumeHeightRatio,
      maxVisibleCandles: config.maxVisibleCandles,
      minVisibleCandles: config.minVisibleCandles,
      initialChartType: config.initialChartType.name,
      yAxisPaddingRatio: config.yAxisPaddingRatio,
      autoScrollOnAppend: config.autoScrollOnAppend,
    );
  }

  static ViewportState viewportFromMessage(ViewportStateMessage msg) {
    return ViewportState(
      startTimestamp: msg.startTimestamp,
      endTimestamp: msg.endTimestamp,
      priceHigh: msg.priceHigh,
      priceLow: msg.priceLow,
      visibleCandleCount: msg.visibleCandleCount,
      candleWidth: msg.candleWidth,
      isAtLatest: msg.isAtLatest,
    );
  }

  static CrosshairEvent crosshairFromMessage(CrosshairDataMessage msg) {
    return CrosshairEvent(
      timestamp: msg.timestamp,
      open: msg.open,
      high: msg.high,
      low: msg.low,
      close: msg.close,
      volume: msg.volume,
      x: msg.x,
      y: msg.y,
    );
  }
}
