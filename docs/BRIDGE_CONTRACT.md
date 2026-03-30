# Bridge Contract — trade_chart SDK V1

This document defines the exact Pigeon interface definitions that generate the platform channel code for Flutter ↔ Native communication.

---

## Pigeon Definition File

**Location:** `pigeons/chart_api.dart`

This file is the single source of truth for the bridge contract. Running `dart run pigeon --input pigeons/chart_api.dart` generates:

- `lib/src/bridge/generated/chart_api.g.dart` (Dart)
- `android/src/main/kotlin/.../bridge/generated/ChartApi.g.kt` (Kotlin)
- `ios/Classes/Bridge/Generated/ChartApi.g.swift` (Swift)

---

## Message Types (DTOs)

These are Pigeon data classes that cross the bridge. They are separate from the public Dart models — `BridgeMapper` converts between them.

```dart
// ──────────────── Initialization ────────────────

class ChartInitParams {
  ChartInitParams({
    required this.width,
    required this.height,
    required this.devicePixelRatio,
    required this.theme,
    required this.config,
  });

  /// Logical width of the chart area in pixels.
  final double width;

  /// Logical height of the chart area in pixels.
  final double height;

  /// Device pixel ratio for hi-dpi rendering.
  final double devicePixelRatio;

  /// Serialized theme.
  final ThemeMessage theme;

  /// Serialized config.
  final ConfigMessage config;
}

// ──────────────── Theme ────────────────

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

  /// All colors as ARGB int (e.g., 0xFF00C853).
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

// ──────────────── Config ────────────────

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
  final String initialChartType;  // "candle" | "line"
  final double yAxisPaddingRatio;
  final bool autoScrollOnAppend;
}

// ──────────────── Candle Data ────────────────

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
  final String timeframe;  // enum name: "m1", "m3", "h1", "d1", etc.
}

// ──────────────── Markers ────────────────

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
  final String type;  // "buy" | "sell"
  final String? label;
}

class MarkerListMessage {
  MarkerListMessage({required this.markers});
  final List<MarkerMessage> markers;
}

// ──────────────── Viewport (native → Flutter) ────────────────

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

// ──────────────── Crosshair (native → Flutter) ────────────────

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
```

---

## Host API (Flutter → Native)

```dart
@HostApi()
abstract class ChartHostApi {

  // ──── Lifecycle ────

  /// Initializes the native engine. Returns the texture ID for the Texture widget.
  @async
  int initialize(ChartInitParams params);

  /// Releases all native resources (surface, buffers, data stores).
  void dispose();

  /// Notifies native that the chart area has resized.
  void onSizeChanged(double width, double height);

  // ──── Data ────

  /// Loads a batch of historical candles. Replaces existing data.
  void loadCandles(CandleDataListMessage data);

  /// Appends a new candle to the end.
  void appendCandle(CandleDataMessage candle);

  /// Updates the last candle in-place (realtime tick).
  void updateLastCandle(CandleDataMessage candle);

  // ──── Markers ────

  /// Replaces all markers.
  void setMarkers(MarkerListMessage markers);

  /// Adds one marker.
  void addMarker(MarkerMessage marker);

  /// Removes all markers.
  void clearMarkers();

  // ──── Chart control ────

  /// Sets chart type: "candle" or "line".
  void setChartType(String chartType);

  /// Sets active timeframe. Data must be loaded separately.
  void setTimeframe(String timeframe);

  /// Updates theme. Triggers re-render.
  void setTheme(ThemeMessage theme);

  /// Updates config. Triggers re-render.
  void setConfig(ConfigMessage config);

  /// Scrolls viewport to show the latest candle.
  void scrollToEnd();

  // ──── Gestures ────

  /// Horizontal pan delta in logical pixels.
  void onPanUpdate(double deltaX);

  /// Pan ended with velocity (logical pixels/second). Native handles fling.
  void onPanEnd(double velocityX);

  /// Pinch scale gesture. scaleFactor is relative to gesture start.
  /// focalPointX is the zoom center in logical pixels from chart left edge.
  void onScaleUpdate(double scaleFactor, double focalPointX);

  /// Scale gesture ended.
  void onScaleEnd();

  /// Long-press crosshair started at position.
  void onCrosshairStart(double x, double y);

  /// Crosshair finger moved.
  void onCrosshairMove(double x, double y);

  /// Crosshair gesture ended.
  void onCrosshairEnd();
}
```

---

## Flutter API (Native → Flutter)

```dart
@FlutterApi()
abstract class ChartFlutterApi {

  /// Engine initialized, first frame ready.
  void onChartReady();

  /// Viewport changed (after pan, zoom, data load, resize).
  void onViewportChanged(ViewportStateMessage viewport);

  /// Crosshair data for the candle under the finger.
  void onCrosshairData(CrosshairDataMessage data);

  /// Recoverable error from native engine.
  void onError(String code, String message);
}
```

---

## Error Codes

| Code | Meaning | Recovery |
|------|---------|----------|
| `TEXTURE_ALLOC_FAILED` | Failed to allocate SurfaceTexture / CVPixelBuffer | Report to user, retry init |
| `INVALID_CANDLE_DATA` | Empty candle list or invalid timestamps | Fix data, retry load |
| `ENGINE_NOT_INITIALIZED` | Method called before initialize() completed | Wait for onChartReady |
| `RENDER_ERROR` | Unexpected rendering failure | Log, engine attempts recovery |

---

## Call Direction Summary

```
Flutter ──── ChartHostApi ────► Native
  initialize()
  dispose()
  onSizeChanged()
  loadCandles()
  appendCandle()
  updateLastCandle()
  setMarkers() / addMarker() / clearMarkers()
  setChartType() / setTimeframe()
  setTheme() / setConfig()
  scrollToEnd()
  onPanUpdate() / onPanEnd()
  onScaleUpdate() / onScaleEnd()
  onCrosshairStart() / onCrosshairMove() / onCrosshairEnd()

Native ──── ChartFlutterApi ──► Flutter
  onChartReady()
  onViewportChanged()
  onCrosshairData()
  onError()
```

---

## Bridge Mapper Contract

`BridgeMapper` (in `lib/src/bridge/bridge_mapper.dart`) provides these static methods:

```dart
class BridgeMapper {
  static CandleDataMessage candleToMessage(CandleData candle);
  static CandleDataListMessage candlesToMessage(List<CandleData> candles, ChartTimeframe tf);
  static MarkerMessage markerToMessage(ChartMarker marker);
  static MarkerListMessage markersToMessage(List<ChartMarker> markers);
  static ThemeMessage themeToMessage(TradeChartTheme theme);
  static ConfigMessage configToMessage(TradeChartConfig config);
  static ViewportState viewportFromMessage(ViewportStateMessage msg);
  static CrosshairEvent crosshairFromMessage(CrosshairDataMessage msg);
}
```

These mappers are the only code that knows about both public models and Pigeon messages. All other code works with one or the other, never both.

---

## Pigeon Build Command

```bash
dart run pigeon \
  --input pigeons/chart_api.dart \
  --dart_out lib/src/bridge/generated/chart_api.g.dart \
  --kotlin_out android/src/main/kotlin/com/tradechart/plugin/bridge/generated/ChartApi.g.kt \
  --kotlin_package com.tradechart.plugin.bridge.generated \
  --swift_out ios/Classes/Bridge/Generated/ChartApi.g.swift
```

Add this as a script in the project for convenience:

```bash
# scripts/generate_pigeon.sh
#!/bin/bash
dart run pigeon --input pigeons/chart_api.dart \
  --dart_out lib/src/bridge/generated/chart_api.g.dart \
  --kotlin_out android/src/main/kotlin/com/tradechart/plugin/bridge/generated/ChartApi.g.kt \
  --kotlin_package com.tradechart.plugin.bridge.generated \
  --swift_out ios/Classes/Bridge/Generated/ChartApi.g.swift
echo "Pigeon code generated."
```

---

## Versioning Strategy

The bridge contract is versioned implicitly by the package version. Breaking changes to the bridge require a major version bump. Additive changes (new methods, new fields with defaults) are minor version bumps. The Pigeon definition file is the canonical source — native implementations must match it exactly.
