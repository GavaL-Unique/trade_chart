import 'package:pigeon/pigeon.dart';

class ChartInitParams {
  ChartInitParams({
    required this.width,
    required this.height,
    required this.devicePixelRatio,
    required this.theme,
    required this.config,
  });

  final double width;
  final double height;
  final double devicePixelRatio;
  final ThemeMessage theme;
  final ConfigMessage config;
}

class ThemeMessage {
  ThemeMessage({
    required this.backgroundColorArgb,
    required this.gridColorArgb,
    required this.bullColorArgb,
    required this.bearColorArgb,
    required this.volumeBullColorArgb,
    required this.volumeBearColorArgb,
    required this.crosshairColorArgb,
    required this.crosshairLabelBgColorArgb,
    required this.textColorArgb,
    required this.axisColorArgb,
    required this.buyMarkerColorArgb,
    required this.sellMarkerColorArgb,
    required this.axisTextSize,
    required this.crosshairTextSize,
  });

  final int backgroundColorArgb;
  final int gridColorArgb;
  final int bullColorArgb;
  final int bearColorArgb;
  final int volumeBullColorArgb;
  final int volumeBearColorArgb;
  final int crosshairColorArgb;
  final int crosshairLabelBgColorArgb;
  final int textColorArgb;
  final int axisColorArgb;
  final int buyMarkerColorArgb;
  final int sellMarkerColorArgb;
  final double axisTextSize;
  final double crosshairTextSize;
}

class ConfigMessage {
  ConfigMessage({
    required this.showVolume,
    required this.showGrid,
    required this.enableCrosshair,
    required this.showAxis,
    required this.volumeHeightRatio,
    required this.maxVisibleCandles,
    required this.minVisibleCandles,
    required this.initialChartType,
    required this.yAxisPaddingRatio,
    required this.autoScrollOnAppend,
  });

  final bool showVolume;
  final bool showGrid;
  final bool enableCrosshair;
  final bool showAxis;
  final double volumeHeightRatio;
  final int maxVisibleCandles;
  final int minVisibleCandles;
  final String initialChartType;
  final double yAxisPaddingRatio;
  final bool autoScrollOnAppend;
}

class CandleDataMessage {
  CandleDataMessage({
    required this.timestamp,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });

  final int timestamp;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;
}

class CandleDataListMessage {
  CandleDataListMessage({
    required this.candles,
    required this.timeframe,
  });

  final List<CandleDataMessage> candles;
  final String timeframe;
}

class MarkerMessage {
  MarkerMessage({
    required this.id,
    required this.timestamp,
    required this.price,
    required this.type,
    this.label,
  });

  final String id;
  final int timestamp;
  final double price;
  final String type;
  final String? label;
}

class MarkerListMessage {
  MarkerListMessage({required this.markers});

  final List<MarkerMessage> markers;
}

class ViewportStateMessage {
  ViewportStateMessage({
    required this.startTimestamp,
    required this.endTimestamp,
    required this.priceHigh,
    required this.priceLow,
    required this.visibleCandleCount,
    required this.candleWidth,
    required this.isAtLatest,
  });

  final int startTimestamp;
  final int endTimestamp;
  final double priceHigh;
  final double priceLow;
  final int visibleCandleCount;
  final double candleWidth;
  final bool isAtLatest;
}

class CrosshairDataMessage {
  CrosshairDataMessage({
    required this.timestamp,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
    required this.x,
    required this.y,
  });

  final int timestamp;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;
  final double x;
  final double y;
}

@HostApi()
abstract class ChartHostApi {
  @async
  int initialize(ChartInitParams params);

  void dispose();

  void onSizeChanged(double width, double height);

  void loadCandles(CandleDataListMessage data);

  void appendCandle(CandleDataMessage candle);

  void updateLastCandle(CandleDataMessage candle);

  void setMarkers(MarkerListMessage markers);

  void addMarker(MarkerMessage marker);

  void clearMarkers();

  void setChartType(String chartType);

  void setTimeframe(String timeframe);

  void setTheme(ThemeMessage theme);

  void setConfig(ConfigMessage config);

  void scrollToEnd();

  void onPanUpdate(double deltaX);

  void onPanEnd(double velocityX);

  void onScaleUpdate(double scaleFactor, double focalPointX);

  void onScaleEnd();

  void onCrosshairStart(double x, double y);

  void onCrosshairMove(double x, double y);

  void onCrosshairEnd();
}

@FlutterApi()
abstract class ChartFlutterApi {
  void onChartReady();

  void onViewportChanged(ViewportStateMessage viewport);

  void onCrosshairData(CrosshairDataMessage data);

  void onError(String code, String message);
}
