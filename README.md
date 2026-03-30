# trade_chart

`trade_chart` is a Flutter SDK for native-rendered trading charts on Android and iOS.

It is not a WebView wrapper. The chart is rendered natively on each platform and shown in Flutter through a `Texture`, while Flutter remains the orchestration and public API layer.

## What This SDK Does

The SDK currently gives you:

- Native candlestick and line chart rendering
- Volume pane
- Native pan, pinch zoom, fling, and long-press crosshair
- Realtime candle flows with `appendCandle()` and `updateLastCandle()`
- Native marker rendering for buy/sell points
- Viewport and crosshair callbacks back to Flutter
- Multi-chart-safe instance ownership
- Fullscreen-aware shell widget with Bybit-style mobile layout
- Controller-managed chart UI state such as fullscreen, drawing mode, indicators, and crosshair enable/disable
- Persistence-ready UI state serialization for future restoration flows

## Architecture

Ownership is split like this:

- Native owns rendering, candle storage, viewport math, and texture lifecycle
- Flutter owns widget composition, controller API, configuration, app state, and orchestration

This means you keep Flutter ergonomics without giving up native chart performance.

## Installation

Add the package to `pubspec.yaml`:

```yaml
dependencies:
  trade_chart:
    path: ../trade_chart
```

Then install packages:

```bash
flutter pub get
```

## Public Entry Points

The main exported API is:

- `TradeChart`
- `TradeChartWidget`
- `TradeChartController`
- `TradeChartConfig`
- `TradeChartTheme`
- `DrawingTool`
- `IndicatorConfig`
- `FullscreenBehavior`

Use them like this:

- `TradeChart`: raw native chart surface only
- `TradeChartWidget`: packaged mobile trading UI shell around the native chart
- `TradeChartController`: data loading, realtime updates, fullscreen, indicators, and UI state

## Quick Start

Create a controller:

```dart
final controller = TradeChartController();
```

Dispose it when the page is removed:

```dart
@override
void dispose() {
  controller.dispose();
  super.dispose();
}
```

## Basic Usage

If you want the richer mobile trading layout, use `TradeChartWidget`.

```dart
import 'package:flutter/material.dart';
import 'package:trade_chart/trade_chart.dart';

class ChartPage extends StatefulWidget {
  const ChartPage({super.key});

  @override
  State<ChartPage> createState() => _ChartPageState();
}

class _ChartPageState extends State<ChartPage> {
  final TradeChartController _controller = TradeChartController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SizedBox(
            width: 900,
            height: 520,
            child: TradeChartWidget(
              controller: _controller,
              theme: const TradeChartTheme.dark(),
              config: const TradeChartConfig(
                showVolume: true,
                initialChartType: ChartType.candle,
              ),
              fullscreenBehavior: const FullscreenBehavior(),
              availableTimeframes: const [
                ChartTimeframe.m1,
                ChartTimeframe.m5,
                ChartTimeframe.m15,
                ChartTimeframe.h1,
                ChartTimeframe.h4,
                ChartTimeframe.d1,
              ],
              onChartReady: () async {
                await _controller.loadCandles(_initialCandles, ChartTimeframe.h1);
                await _controller.setMarkers(_initialMarkers);
              },
              onTimeframeSelected: (timeframe) async {
                await _controller.setTimeframe(timeframe);
                await _controller.loadCandles(
                  loadCandlesFor(timeframe),
                  timeframe,
                );
              },
              onViewportChange: (event) {
                debugPrint(
                  'Visible candles: ${event.viewport.visibleCandleCount}',
                );
              },
              onCrosshairUpdate: (event) {
                debugPrint('Crosshair close: ${event.close}');
              },
            ),
          ),
        ),
      ),
    );
  }
}
```

## Raw Native Chart Usage

If you want only the native chart surface and you will build your own controls, use `TradeChart`.

```dart
TradeChart(
  controller: controller,
  theme: const TradeChartTheme.dark(),
  config: const TradeChartConfig(showVolume: true),
  onChartReady: () async {
    await controller.loadCandles(candles, ChartTimeframe.h1);
  },
)
```

Use `TradeChart` when:

- you already have a design system
- you want to place your own app bar, buttons, and tabs
- you only need the native chart surface

Use `TradeChartWidget` when:

- you want a ready-made mobile trading chart shell
- you want fullscreen behavior
- you want timeframe and indicator rows
- you want built-in drawing mode controls

## Controller API

### Data Loading

Load the initial historical candles:

```dart
await controller.loadCandles(candles, ChartTimeframe.h1);
```

Switch timeframe:

```dart
await controller.setTimeframe(ChartTimeframe.m15);
await controller.loadCandles(newCandles, ChartTimeframe.m15);
```

Change chart type:

```dart
await controller.setChartType(ChartType.line);
```

Scroll to latest:

```dart
await controller.scrollToEnd();
```

### Realtime Updates

For live data:

```dart
await controller.updateLastCandle(updatedInProgressCandle);
await controller.appendCandle(newClosedCandle);
```

Marker example:

```dart
await controller.addMarker(
  const ChartMarker(
    id: 'buy-123',
    timestamp: 1710000000000,
    price: 42050,
    type: ChartMarkerType.buy,
    label: 'BUY',
  ),
);
```

Realtime behavior:

- `updateLastCandle()` updates the last candle in place
- `appendCandle()` appends only if the new timestamp is newer than the current last candle
- if the viewport is pinned to latest, append keeps the chart aligned to the right
- if the user is exploring history, append does not force-scroll them back

### Fullscreen

Enter fullscreen:

```dart
controller.enterFullscreen();
```

Exit fullscreen:

```dart
controller.exitFullscreen();
```

The shell widget preserves UI state across fullscreen transitions, including:

- selected timeframe
- indicator selection
- drawing mode state
- crosshair enabled state
- controller-side serialized UI state

### Drawing Mode

The controller exposes drawing mode state now:

```dart
controller.toggleDrawingMode();
controller.setDrawingTool(DrawingTool.trendLine);
controller.clearDrawings();
```

Available tool enums:

- `trendLine`
- `arrow`
- `horizontalLine`
- `verticalLine`
- `ray`
- `parallelChannel`
- `brush`
- `eraser`

Important:

- the controller and shell API for drawing mode exist now
- full native interactive drawing editing is not complete yet
- this release prepares the state, toolbar, and persistence model for that native implementation

### Indicators

Add or remove indicator state:

```dart
controller.addIndicator(const IndicatorConfig.overlay(IndicatorKind.ma));
controller.addIndicator(const IndicatorConfig.pane(IndicatorKind.macd));
controller.removeIndicator(IndicatorKind.ma);
```

Available indicator kinds:

- `ma`
- `ema`
- `boll`
- `sar`
- `mavol`
- `macd`
- `kdj`

Important:

- the controller and shell API for indicator state are included
- the full native indicator rendering system is not finished yet
- this release establishes the API and state model for the renderer expansion

### Crosshair

Enable or disable crosshair dynamically:

```dart
await controller.setCrosshairEnabled(false);
```

### State Persistence

Save controller UI state:

```dart
final state = controller.saveUiState();
```

Restore it later:

```dart
controller.restoreUiState(state);
```

This is useful when you want to preserve:

- drawing mode state
- selected timeframe
- indicator selection
- fullscreen state intent
- serialized drawing objects

## Viewport And Events

Read the latest viewport:

```dart
final viewport = controller.currentViewport;
```

Or listen to stream updates:

```dart
controller.onViewportChange.listen((event) {
  debugPrint('Visible count: ${event.viewport.visibleCandleCount}');
});

controller.onCrosshairUpdate.listen((event) {
  debugPrint('Close: ${event.close}');
});
```

## Multi-Chart Usage

You can safely create multiple charts in the same app.

```dart
final leftController = TradeChartController();
final rightController = TradeChartController();
```

This package now isolates per-chart:

- native engine
- texture ownership
- callback routing
- lifecycle and disposal

There are no global callback collisions between chart instances.

## Timeframe Reset Behavior

When you call:

```dart
await controller.setTimeframe(ChartTimeframe.m15);
```

the native side clears the previous dataset and now also emits an empty viewport event immediately. This prevents stale `currentViewport` values on the Flutter side.

## Configuration

Basic chart behavior is controlled with `TradeChartConfig`.

```dart
const config = TradeChartConfig(
  showVolume: true,
  showGrid: true,
  enableCrosshair: true,
  showAxis: true,
  volumeHeightRatio: 0.2,
  maxVisibleCandles: 300,
  minVisibleCandles: 20,
  initialChartType: ChartType.candle,
  yAxisPaddingRatio: 0.1,
  autoScrollOnAppend: true,
);
```

Theme is controlled with `TradeChartTheme`.

```dart
const theme = TradeChartTheme.dark();
```

Or customize:

```dart
final theme = const TradeChartTheme.dark().copyWith(
  bullColor: const Color(0xFF00C087),
  bearColor: const Color(0xFFFF4D6D),
);
```

## Fullscreen Behavior Config

You can control how the shell handles fullscreen:

```dart
const fullscreenBehavior = FullscreenBehavior(
  enabled: true,
  rotateToLandscape: true,
  showTopToolbar: true,
  showTimeframeRow: true,
  showIndicatorRow: true,
  showDrawingToolbar: true,
);
```

## Example App

The example demonstrates:

- historical load
- timeframe switching
- realtime candle updates
- marker rendering
- fullscreen shell usage
- controller-driven chart state

Run it with:

```bash
cd example
flutter run
```

## Pigeon Regeneration

The bridge contract is defined in [pigeons/chart_api.dart](/Users/developer/Desktop/project/package/chart/pigeons/chart_api.dart).

Regenerate bindings with:

```bash
./scripts/generate_pigeon.sh
```

Generated files:

- `lib/src/bridge/generated/chart_api.g.dart`
- `android/src/main/kotlin/com/tradechart/plugin/bridge/generated/ChartApi.g.kt`
- `ios/Classes/Bridge/Generated/ChartApi.g.swift`

## Current Status And Limitations

This package already has production-ready improvements in:

- native rendering
- multi-chart-safe lifecycle
- per-instance callback routing
- cleared viewport handling after timeframe reset
- fullscreen-capable shell widget

Still in progress:

- full native drawing object create/select/move/resize/delete workflow
- full native indicator calculations and pane rendering for all declared indicators
- richer native chart chrome such as live price pill, advanced overlays, and full Bybit-grade editing behavior

So today the package is strong as a native chart foundation and controller/shell API, while the remaining Bybit-level drawing and indicator rendering work is the next expansion layer.
