# API Specification — trade_chart SDK V1

This document defines the complete public Dart API surface of the `trade_chart` package. Everything listed here is exported from `lib/trade_chart.dart`. Internal classes, bridge code, and generated code are NOT part of the public API.

---

## 1. TradeChart Widget

```dart
/// The main chart widget. Renders a native trading chart via a Texture surface.
///
/// Requires a [TradeChartController] to load data and control behavior.
/// Must be placed in a widget with bounded constraints (e.g., SizedBox,
/// Expanded, or a parent with finite height).
class TradeChart extends StatefulWidget {
  const TradeChart({
    super.key,
    required this.controller,
    this.theme = const TradeChartTheme.dark(),
    this.config = const TradeChartConfig(),
    this.onCrosshairUpdate,
    this.onViewportChange,
    this.onChartReady,
  });

  /// Controller for loading data, pushing updates, and controlling chart state.
  final TradeChartController controller;

  /// Visual theme (colors, text styles, spacing).
  final TradeChartTheme theme;

  /// Behavioral configuration (volume visibility, candle limits, etc.).
  final TradeChartConfig config;

  /// Called when the crosshair position updates during a long-press drag.
  /// Provides OHLCV data for the candle under the crosshair.
  final ValueChanged<CrosshairEvent>? onCrosshairUpdate;

  /// Called when the visible viewport changes (pan, zoom, data load).
  final ValueChanged<ViewportChangeEvent>? onViewportChange;

  /// Called once when the native engine is initialized and ready to render.
  final VoidCallback? onChartReady;
}
```

**Usage:**

```dart
final controller = TradeChartController();

// In build():
TradeChart(
  controller: controller,
  theme: const TradeChartTheme.dark(),
  config: const TradeChartConfig(showVolume: true),
  onCrosshairUpdate: (event) => print('${event.close}'),
  onViewportChange: (event) => print('${event.viewport.visibleCandleCount}'),
  onChartReady: () => _loadInitialData(),
)
```

---

## 2. TradeChartController

```dart
/// Controls the chart's data, viewport, and display mode.
///
/// Create one instance and pass it to [TradeChart]. Call [dispose] when done.
/// A controller can only be attached to one [TradeChart] at a time.
class TradeChartController {
  TradeChartController();

  // ──────────────── Data Loading ────────────────

  /// Loads a batch of historical candles and sets the active timeframe.
  /// Replaces any previously loaded data.
  /// The chart auto-scrolls to show the most recent candles.
  Future<void> loadCandles(List<CandleData> candles, ChartTimeframe timeframe);

  /// Appends a new completed candle to the end of the dataset.
  /// If the viewport is at the latest candle, auto-scrolls to show it.
  Future<void> appendCandle(CandleData candle);

  /// Updates the last (in-progress) candle with new OHLCV values.
  /// Use this for realtime tick updates within the current period.
  Future<void> updateLastCandle(CandleData candle);

  // ──────────────── Markers ────────────────

  /// Replaces all markers with the provided list.
  Future<void> setMarkers(List<ChartMarker> markers);

  /// Adds a single marker without clearing existing ones.
  Future<void> addMarker(ChartMarker marker);

  /// Removes all markers from the chart.
  Future<void> clearMarkers();

  // ──────────────── Chart Control ────────────────

  /// Changes the chart rendering type (candlestick or line).
  Future<void> setChartType(ChartType type);

  /// Switches the active timeframe. The consumer must also call
  /// [loadCandles] with new data for the new timeframe.
  Future<void> setTimeframe(ChartTimeframe timeframe);

  /// Scrolls the viewport to show the latest candle and re-enables auto-scroll.
  Future<void> scrollToEnd();

  // ──────────────── Streams ────────────────

  /// Stream of crosshair updates during long-press gestures.
  /// Emits data for the candle under the crosshair.
  Stream<CrosshairEvent> get onCrosshairUpdate;

  /// Stream of viewport state changes (pan, zoom, data load, resize).
  Stream<ViewportChangeEvent> get onViewportChange;

  // ──────────────── State ────────────────

  /// Whether the controller is currently attached to a widget.
  bool get isAttached;

  /// The current viewport state, or null if not yet initialized.
  ViewportState? get currentViewport;

  // ──────────────── Lifecycle ────────────────

  /// Releases native resources. Must be called when the controller
  /// is no longer needed. The controller cannot be reused after dispose.
  void dispose();
}
```

---

## 3. Models

### CandleData

```dart
/// A single OHLCV candlestick data point.
class CandleData {
  const CandleData({
    required this.timestamp,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });

  /// Milliseconds since Unix epoch. Must be unique per candle in a dataset.
  final int timestamp;

  /// Opening price.
  final double open;

  /// Highest price in the period.
  final double high;

  /// Lowest price in the period.
  final double low;

  /// Closing price.
  final double close;

  /// Trading volume in the period.
  final double volume;
}
```

### ChartMarker

```dart
/// A visual marker placed on the chart at a specific price and time.
class ChartMarker {
  const ChartMarker({
    required this.id,
    required this.timestamp,
    required this.price,
    required this.type,
    this.label,
  });

  /// Unique identifier. Used for add/remove operations.
  final String id;

  /// Timestamp where the marker appears (x-axis).
  final int timestamp;

  /// Price level where the marker appears (y-axis).
  final double price;

  /// Marker type determines icon and color.
  final MarkerType type;

  /// Optional text label displayed near the marker.
  final String? label;
}

/// The type of chart marker.
enum MarkerType {
  /// Upward arrow in buy color. Placed below the candle.
  buy,

  /// Downward arrow in sell color. Placed above the candle.
  sell,
}
```

### ChartTimeframe

```dart
/// Supported candlestick timeframes.
enum ChartTimeframe {
  m1,   // 1 minute
  m3,   // 3 minutes
  m5,   // 5 minutes
  m15,  // 15 minutes
  m30,  // 30 minutes
  h1,   // 1 hour
  h4,   // 4 hours
  d1,   // 1 day
  w1,   // 1 week
  M1,   // 1 month
}
```

### ChartType

```dart
/// The visual rendering mode for price data.
enum ChartType {
  /// Traditional OHLC candlestick chart.
  candle,

  /// Close-price line chart.
  line,
}
```

### ViewportState

```dart
/// Describes the currently visible region of the chart.
class ViewportState {
  const ViewportState({
    required this.startTimestamp,
    required this.endTimestamp,
    required this.priceHigh,
    required this.priceLow,
    required this.visibleCandleCount,
    required this.candleWidth,
    required this.isAtLatest,
  });

  /// Timestamp of the leftmost visible candle.
  final int startTimestamp;

  /// Timestamp of the rightmost visible candle.
  final int endTimestamp;

  /// Highest price in the visible range (including padding).
  final double priceHigh;

  /// Lowest price in the visible range (including padding).
  final double priceLow;

  /// Number of candles currently visible.
  final int visibleCandleCount;

  /// Width of each candle in logical pixels.
  final double candleWidth;

  /// Whether the viewport is pinned to the latest candle (auto-scroll active).
  final bool isAtLatest;
}
```

---

## 4. Events

### CrosshairEvent

```dart
/// Emitted when the crosshair moves over a candle during a long-press gesture.
class CrosshairEvent {
  const CrosshairEvent({
    required this.timestamp,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
    required this.x,
    required this.y,
  });

  /// Timestamp of the candle under the crosshair.
  final int timestamp;

  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;

  /// Crosshair x position in logical pixels (relative to chart).
  final double x;

  /// Crosshair y position in logical pixels (relative to chart).
  final double y;
}
```

### ViewportChangeEvent

```dart
/// Emitted when the visible viewport changes.
class ViewportChangeEvent {
  const ViewportChangeEvent({
    required this.viewport,
  });

  /// The new viewport state.
  final ViewportState viewport;
}
```

---

## 5. Theme

```dart
/// Visual theme for the trading chart.
///
/// All colors and text styles used by the native rendering engine.
/// Provide a custom theme or use [TradeChartTheme.dark()] for the default
/// dark trading UI.
class TradeChartTheme {
  const TradeChartTheme({
    required this.backgroundColor,
    required this.gridColor,
    required this.bullColor,
    required this.bearColor,
    required this.volumeBullColor,
    required this.volumeBearColor,
    required this.crosshairColor,
    required this.crosshairLabelBackgroundColor,
    required this.textColor,
    required this.axisColor,
    required this.buyMarkerColor,
    required this.sellMarkerColor,
    required this.axisTextSize,
    required this.crosshairTextSize,
  });

  /// Default dark trading theme (dark background, green bull, red bear).
  const factory TradeChartTheme.dark();

  final Color backgroundColor;          // default: #1A1A2E
  final Color gridColor;                // default: #2A2A3E (subtle)
  final Color bullColor;                // default: #00C853 (green)
  final Color bearColor;                // default: #FF1744 (red)
  final Color volumeBullColor;          // default: #00C853 at 30% opacity
  final Color volumeBearColor;          // default: #FF1744 at 30% opacity
  final Color crosshairColor;           // default: #FFFFFF at 60% opacity
  final Color crosshairLabelBackgroundColor; // default: #333355
  final Color textColor;                // default: #8888AA
  final Color axisColor;                // default: #2A2A3E
  final Color buyMarkerColor;           // default: #00C853
  final Color sellMarkerColor;          // default: #FF1744
  final double axisTextSize;            // default: 10.0
  final double crosshairTextSize;       // default: 11.0

  /// Returns a copy with the given fields replaced.
  TradeChartTheme copyWith({ ... });
}
```

---

## 6. Config

```dart
/// Behavioral configuration for the chart.
class TradeChartConfig {
  const TradeChartConfig({
    this.showVolume = true,
    this.showGrid = true,
    this.enableCrosshair = true,
    this.showAxis = true,
    this.volumeHeightRatio = 0.2,
    this.maxVisibleCandles = 200,
    this.minVisibleCandles = 10,
    this.initialChartType = ChartType.candle,
    this.yAxisPaddingRatio = 0.1,
    this.autoScrollOnAppend = true,
  });

  /// Whether to render volume bars at the bottom.
  final bool showVolume;

  /// Whether to render grid lines.
  final bool showGrid;

  /// Whether long-press crosshair is enabled.
  final bool enableCrosshair;

  /// Whether to render price/time axes.
  final bool showAxis;

  /// Volume bar area as a fraction of total chart height (0.0 to 0.5).
  final double volumeHeightRatio;

  /// Maximum candles visible at minimum zoom.
  final int maxVisibleCandles;

  /// Minimum candles visible at maximum zoom.
  final int minVisibleCandles;

  /// Chart type on first render.
  final ChartType initialChartType;

  /// Vertical padding above/below price range as fraction of range (0.0 to 0.3).
  final double yAxisPaddingRatio;

  /// Auto-scroll to latest candle when appendCandle is called and viewport is at latest.
  final bool autoScrollOnAppend;

  TradeChartConfig copyWith({ ... });
}
```

---

## 7. API Usage Examples

### Minimal Setup

```dart
class _ChartScreenState extends State<ChartScreen> {
  final _controller = TradeChartController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: TradeChart(
        controller: _controller,
        onChartReady: () => _loadData(),
      ),
    );
  }

  Future<void> _loadData() async {
    final candles = await api.fetchCandles('BTCUSDT', ChartTimeframe.h1);
    await _controller.loadCandles(candles, ChartTimeframe.h1);
  }
}
```

### Realtime Updates

```dart
late StreamSubscription _wsSub;

void _startRealtime() {
  _wsSub = wsClient.tickerStream('BTCUSDT').listen((tick) {
    _controller.updateLastCandle(CandleData(
      timestamp: tick.timestamp,
      open: tick.open,
      high: tick.high,
      low: tick.low,
      close: tick.close,
      volume: tick.volume,
    ));
  });
}
```

### Timeframe Switching

```dart
Future<void> _switchTimeframe(ChartTimeframe tf) async {
  final candles = await api.fetchCandles('BTCUSDT', tf);
  await _controller.setTimeframe(tf);
  await _controller.loadCandles(candles, tf);
}
```

### Buy/Sell Markers

```dart
await _controller.setMarkers([
  ChartMarker(
    id: 'buy-1',
    timestamp: 1700000000000,
    price: 42150.0,
    type: MarkerType.buy,
    label: 'Buy',
  ),
  ChartMarker(
    id: 'sell-1',
    timestamp: 1700003600000,
    price: 42800.0,
    type: MarkerType.sell,
  ),
]);
```

---

## 8. API Invariants

1. `TradeChartController` must be created before `TradeChart` widget is built.
2. One controller attaches to one widget at a time. Attaching to a second widget throws.
3. `loadCandles` must be called with at least 1 candle. Empty list is a no-op with a warning.
4. `appendCandle` requires the new candle's timestamp to be > the last candle's timestamp.
5. `updateLastCandle` must have the same timestamp as the current last candle.
6. All timestamps are in milliseconds since Unix epoch, UTC.
7. `dispose()` on the controller also releases native resources. Double-dispose is safe (no-op).
8. Theme and config changes trigger a full re-render on the next frame.
9. The widget must have bounded constraints. Unbounded height/width throws a layout error.
