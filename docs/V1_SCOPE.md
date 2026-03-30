# V1 Scope — trade_chart SDK

Clear boundaries for what is included in V1 and what is deferred to later versions.

---

## V1 — Included

### Core Chart Features

| Feature | Detail |
|---------|--------|
| **Candlestick chart** | OHLC bodies + wicks, bull/bear colors, correct sizing based on zoom |
| **Line chart** | Close-price line, smooth rendering, switchable from candle mode |
| **Volume bars** | Rendered in bottom region, height proportional to volume, bull/bear colored |
| **Grid lines** | Horizontal (price levels) and vertical (time intervals), subtle styling |
| **Price axis** | Right-side labels showing price levels, auto-formatted |
| **Time axis** | Bottom labels showing dates/times appropriate to timeframe |
| **Dark theme** | Professional dark trading UI with customizable colors via `TradeChartTheme` |

### Interactions

| Feature | Detail |
|---------|--------|
| **Horizontal pan** | Scroll through candle history, edge-clamped |
| **Fling / momentum** | Pan with velocity → native deceleration animation |
| **Pinch zoom** | Zoom in/out centered on pinch point, min/max candle visibility limits |
| **Crosshair** | Long-press activates, drag to move, shows OHLCV data via callback |
| **Scroll to latest** | Programmatic API to jump to most recent candle |

### Data

| Feature | Detail |
|---------|--------|
| **Historical load** | `loadCandles()` accepts batch of candles, renders immediately |
| **Realtime append** | `appendCandle()` for new period candle, with auto-scroll |
| **Realtime update** | `updateLastCandle()` for in-progress candle tick updates |
| **Timeframe switching** | `setTimeframe()` + `loadCandles()` for new data |
| **Buy/sell markers** | `setMarkers()` / `addMarker()` places visual markers at price+time |

### SDK Shape

| Feature | Detail |
|---------|--------|
| **TradeChart widget** | Single `StatefulWidget`, accepts controller + theme + config + callbacks |
| **TradeChartController** | Programmatic API for all data and control operations |
| **TradeChartTheme** | Immutable theme with all colors and text sizes, dark factory |
| **TradeChartConfig** | Behavioral settings (volume, grid, crosshair, candle limits) |
| **Stream-based events** | `onCrosshairUpdate`, `onViewportChange` as Dart streams |
| **Pigeon bridge** | Type-safe generated code for Flutter ↔ Native communication |

### Platform Support

| Platform | Min Version | Rendering API |
|----------|-------------|---------------|
| Android | SDK 23 (Android 6.0) | `android.graphics.Canvas` via `SurfaceTexture` |
| iOS | 13.0 | `CoreGraphics` via `CVPixelBuffer` |

---

## V1 — NOT Included

These features are explicitly excluded from V1 scope. They are tracked for future versions.

### V2 Candidates (Next Priority)

| Feature | Reason for Deferral | Complexity |
|---------|---------------------|-----------|
| **Technical indicators** (MA, EMA, SMA, Bollinger Bands, RSI, MACD) | Requires indicator calculation engine, sub-chart rendering, and multi-pane layout. Significant architecture addition. | High |
| **Light theme** | Requires validating all renderers work with light colors. Low risk but not V1 priority. | Low |
| **Custom theme presets** | Multiple built-in themes (TradingView-style, Bloomberg-style). Design work. | Medium |
| **Horizontal price line overlays** | Persistent horizontal lines at specific prices (e.g., entry, stop-loss). Requires new renderer + data model. | Medium |
| **Manual y-axis control** | User drag on y-axis to override auto-scaling. Requires gesture zone detection + manual scale mode. | Medium |
| **Accessibility** | VoiceOver/TalkBack support for chart data. Requires native accessibility trees. | High |
| **Screenshot / export** | Capture current chart as PNG. Requires reading back from texture. | Medium |

### V3 Candidates (Future Roadmap)

| Feature | Reason for Deferral | Complexity |
|---------|---------------------|-----------|
| **Drawing tools** (trend lines, Fibonacci, horizontal lines, rectangles) | Major feature: touch-to-draw, serializable annotations, undo/redo. | Very High |
| **Order line rendering** | Show open orders, take-profit, stop-loss as interactive price lines. Requires state sync with trading engine. | High |
| **Replay / playback mode** | Replay historical data tick-by-tick for backtesting UI. Requires time control, buffering, playback speed. | High |
| **Multi-pane layout** | Main chart + indicator sub-charts (RSI pane, MACD pane) with synchronized x-axis. Requires pane manager. | Very High |
| **Depth chart** | Order book visualization (bids/asks). Completely separate renderer. | High |
| **On-demand data loading** | SDK requests more historical data when user pans to edge. Requires `CandleDataProvider` callback interface. | Medium |
| **GPU rendering** (OpenGL ES / Metal) | Upgrade from CPU Canvas/CoreGraphics to GPU shaders. Only needed if CPU rendering becomes a bottleneck. | High |
| **FFI bridge** | Replace Pigeon with dart:ffi for maximum bridge performance. Only needed if channel overhead is measurable. | High |
| **Web support** | Flutter web via CanvasKit. Requires JS interop or pure-Dart rendering fallback. | Very High |
| **Desktop support** | macOS, Windows, Linux. Requires platform-specific texture registration and rendering. | High per platform |
| **Annotations system** | Text labels, shapes, arrows placed on chart. Serializable. | High |
| **Comparison mode** | Overlay multiple symbols on the same chart. | High |

---

## V1 Quality Gates

Before V1 is considered complete, these criteria must be met:

| Gate | Criteria |
|------|----------|
| **Functionality** | All V1 features work on both Android and iOS |
| **Performance** | 60 fps pan/zoom with 5K candles on mid-range devices |
| **Stability** | No crashes during normal usage (load, pan, zoom, crosshair, realtime, timeframe switch, resize) |
| **Memory** | No memory leaks after 20 push/pop cycles of chart screen |
| **API cleanliness** | All public APIs have dartdoc, no internal types leaked |
| **Example app** | Demonstrates all V1 features in a realistic dark trading UI |
| **Package score** | `flutter pub publish --dry-run` passes with no errors |
| **Analysis** | Zero Dart analysis warnings with recommended lints |
| **Tests** | Unit tests for models, mapper, controller, gesture handler. Integration test for lifecycle. |

---

## Feature Addition Protocol (for V2+)

When adding a feature from the deferred list:

1. **Design doc**: Write a short design doc covering the feature's impact on existing architecture
2. **Bridge additions**: Add new Pigeon methods (additive, not breaking)
3. **New renderers**: Create new renderer classes (no modification to existing renderers)
4. **New config fields**: Add to `TradeChartConfig` with defaults that preserve V1 behavior
5. **New model classes**: Add to `models/`, export from barrel
6. **Tests**: Unit + integration tests for the new feature
7. **Example**: Demonstrate in example app
8. **Changelog**: Document in CHANGELOG.md

This protocol ensures backward compatibility. V1 consumers should be able to upgrade to V2 without code changes.
