# trade_chart

`trade_chart` is a Flutter SDK for native-rendered trading charts on Android and iOS.

V1 features:
- Native candlestick and line chart rendering
- Volume subchart
- Native pan, pinch zoom, fling, and long-press crosshair
- Realtime `appendCandle()` and `updateLastCandle()` flows
- Native buy/sell marker rendering
- Theme and config control from Flutter
- Viewport and crosshair callbacks back to Flutter

The SDK keeps rendering, dataset ownership, and viewport ownership in native code. Flutter owns the widget tree, gesture capture, configuration, and application-level orchestration.

## Getting Started

Add the package to your Flutter app and create a controller:

```dart
final controller = TradeChartController();
```

Mount the widget inside bounded constraints:

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
      body: Center(
        child: SizedBox(
          width: 800,
          height: 420,
          child: TradeChart(
            controller: _controller,
            theme: const TradeChartTheme.dark(),
            config: const TradeChartConfig(showVolume: true),
            onChartReady: () async {
              await _controller.loadCandles(_initialCandles, ChartTimeframe.h1);
              await _controller.setMarkers(_initialMarkers);
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
    );
  }
}
```

## Public API Overview

Core widget and controller:
- `TradeChart`
- `TradeChartController`

Data and display:
- `CandleData`
- `ChartMarker`
- `ChartMarkerType`
- `ChartTimeframe`
- `ChartType`
- `TradeChartTheme`
- `TradeChartConfig`
- `ViewportState`

Callbacks and streams:
- `onViewportChange`
- `onCrosshairUpdate`
- `TradeChartController.currentViewport`

## Realtime Updates

Use the controller after the initial dataset has been loaded:

```dart
await controller.updateLastCandle(updatedInProgressCandle);
await controller.appendCandle(newPeriodCandle);
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

Realtime behavior in V1:
- `appendCandle()` appends a new candle only when its timestamp is newer than the current last candle.
- `updateLastCandle()` updates the last candle in place and is intended for tick-by-tick realtime changes.
- If the viewport is pinned to the latest candle and `autoScrollOnAppend` is enabled, appends keep the chart aligned to the right edge.
- If the user has panned away from the latest region, appends do not force-reset the viewport.

## Pigeon Regeneration

The bridge contract is defined in [`pigeons/chart_api.dart`](/Users/developer/Desktop/project/package/chart/pigeons/chart_api.dart).

Regenerate bindings with:

```bash
./scripts/generate_pigeon.sh
```

Generated outputs live in:
- `lib/src/bridge/generated/chart_api.g.dart`
- `android/src/main/kotlin/com/tradechart/plugin/bridge/generated/ChartApi.g.kt`
- `ios/Classes/Bridge/Generated/ChartApi.g.swift`

## Example App

The example app demonstrates:
- initial historical load
- chart type switching
- timeframe switching
- realtime append/update simulation
- native marker rendering
- viewport status and crosshair readout

Run it with:

```bash
cd example
flutter run
```

## Known Limitations In V1

V1 intentionally does not include:
- indicators
- drawing tools
- order lines
- replay mode
- custom overlay widgets for annotations

The current renderer is optimized for V1 scope and structured so future phases can layer more native rendering features on top without moving ownership out of native.
