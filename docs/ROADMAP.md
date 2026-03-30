# Implementation Roadmap — trade_chart SDK V1

Five phases, each producing a testable milestone. Each phase builds on the previous. Estimated total: 5–7 weeks for a single developer.

---

## Phase 1: Architecture Skeleton

**Goal:** Plugin project compiles on both platforms. Pigeon bridge works. Texture displays a solid color.

**Duration:** Week 1–2

### Tasks

| # | Task | Files Created/Modified | Acceptance Criteria |
|---|------|----------------------|---------------------|
| 1.1 | Create Flutter plugin project with `flutter create --template=plugin --platforms=android,ios trade_chart` | All scaffold files | Project compiles |
| 1.2 | Configure `pubspec.yaml` with package metadata, min SDKs, Pigeon dev dependency | `pubspec.yaml` | `flutter pub get` succeeds |
| 1.3 | Write Pigeon definition file with all message types + `ChartHostApi` + `ChartFlutterApi` | `pigeons/chart_api.dart` | `dart run pigeon` generates code for all 3 platforms |
| 1.4 | Create barrel export file with all public class stubs | `lib/trade_chart.dart`, all `lib/src/` files | Package exports compile |
| 1.5 | Implement Dart public model classes | `models/*.dart` | Unit tests pass |
| 1.6 | Implement `BridgeMapper` | `bridge/bridge_mapper.dart` | Mapper unit tests pass |
| 1.7 | Implement `TradeChartPlugin.kt` (Android) — register Pigeon, obtain `TextureRegistry` | `TradeChartPlugin.kt` | Plugin registers without crash |
| 1.8 | Implement `TextureRenderer.kt` — create `SurfaceTexture`, bind `Surface`, draw solid color | `engine/TextureRenderer.kt` | Texture ID returned |
| 1.9 | Implement `ChartHostApiImpl.kt` stub — `initialize()` creates engine, returns texture ID | `bridge/ChartHostApiImpl.kt` | Bridge call succeeds |
| 1.10 | Implement `TradeChartPlugin.swift` (iOS) — register Pigeon, obtain `FlutterTextureRegistry` | `TradeChartPlugin.swift` | Plugin registers |
| 1.11 | Implement `TextureRenderer.swift` — create `CVPixelBuffer`, draw solid color | `Engine/TextureRenderer.swift` | Texture ID returned |
| 1.12 | Implement `ChartHostApiImpl.swift` stub | `Bridge/ChartHostApiImpl.swift` | Bridge call succeeds |
| 1.13 | Implement `_TradeChartState` — calls `initialize()`, displays `Texture` widget | `trade_chart_widget.dart` | Solid colored rectangle visible in example app |
| 1.14 | Implement `TradeChartController` stub — lifecycle methods only | `trade_chart_controller.dart` | Attach/detach/dispose work |
| 1.15 | Create example app with `TradeChart` widget in a `SizedBox` | `example/lib/main.dart` | Runs on both platforms, shows solid rectangle |

### Phase 1 Milestone
A colored rectangle rendered by native code is visible in the Flutter example app on both Android and iOS. Pigeon bridge is functional. Plugin lifecycle (init/dispose) works without leaks.

---

## Phase 2: Static Chart Rendering

**Goal:** Load historical candles and render a static candlestick chart with grid, axes, and volume.

**Duration:** Week 2–3

### Tasks

| # | Task | Files | Criteria |
|---|------|-------|----------|
| 2.1 | Implement `CandleStore.kt` / `.swift` — load, array storage, range query, binary search | `data/CandleStore.kt`, `Data/CandleStore.swift` | Stores 5K candles, range query returns correct subset |
| 2.2 | Implement `ViewportCalculator` — initial viewport, visible range, y-axis scaling | `viewport/ViewportCalculator.kt`, `Viewport/ViewportCalculator.swift` | Correct visible indices and price range for given chart width |
| 2.3 | Implement `NativeChartTheme` — deserialize theme, pre-allocate Paint/CGColor | `theme/NativeChartTheme.kt`, `Theme/NativeChartTheme.swift` | Paint objects created from theme values |
| 2.4 | Implement `ChartFrame` — per-render context object | `engine/ChartFrame.kt`, `Engine/ChartFrame.swift` | Carries canvas, viewport snapshot, theme, config |
| 2.5 | Implement `ChartLayerRenderer` interface/protocol | `renderer/ChartLayerRenderer.kt`, `Renderer/ChartLayerRenderer.swift` | Single `render(frame)` method |
| 2.6 | Implement `BackgroundRenderer` | Both platforms | Fills background color |
| 2.7 | Implement `GridRenderer` — horizontal price lines, vertical time lines | Both platforms | Grid lines match visible range |
| 2.8 | Implement `CandleRenderer` — draw OHLC candles (body + wick) | Both platforms | Candles render correctly with bull/bear colors |
| 2.9 | Implement `VolumeRenderer` — volume bars in bottom area | Both platforms | Volume bars scale to visible volume range |
| 2.10 | Implement `AxisRenderer` — price labels (right), time labels (bottom) | Both platforms | Labels positioned correctly, formatted numbers |
| 2.11 | Implement `ChartEngine` — orchestrate renderers, dirty flag, vsync scheduling | `engine/ChartEngine.kt`, `Engine/ChartEngine.swift` | Renderers called in order, frame scheduled on dirty |
| 2.12 | Wire `ChartHostApi.loadCandles()` through to `CandleStore` + render | `ChartHostApiImpl` on both platforms | `loadCandles()` → chart renders |
| 2.13 | Implement `TradeChartController.loadCandles()` end-to-end | Dart controller + bridge | Consumer loads candles, chart appears |
| 2.14 | Implement `TradeChartTheme.dark()` factory | `trade_chart_theme.dart` | Default dark theme values |
| 2.15 | Implement `TradeChartConfig` with defaults | `trade_chart_config.dart` | Default config values |
| 2.16 | Create sample candle data for example app | `example/lib/data/sample_candles.dart` | 500+ realistic BTC/USDT candles |
| 2.17 | Update example app to load sample data on chart ready | `example/lib/main.dart` | Static chart visible with candles, grid, volume, axes |

### Phase 2 Milestone
Example app displays a static candlestick chart with 500+ candles, grid lines, volume bars, price/time axes, and the dark trading theme. No interaction yet.

---

## Phase 3: Gestures

**Goal:** Pan, zoom, and fling work smoothly. Viewport tracks user interaction.

**Duration:** Week 3–4

### Tasks

| # | Task | Files | Criteria |
|---|------|-------|----------|
| 3.1 | Implement `GestureState` enum and state tracking | `gestures/gesture_state.dart` | States: idle, panning, zooming, crosshair |
| 3.2 | Implement `ChartGestureHandler` — state machine, pan/zoom/crosshair routing | `gestures/chart_gesture_handler.dart` | Correct state transitions, no conflicting gestures |
| 3.3 | Wire `GestureDetector` into `_TradeChartState` | `trade_chart_widget.dart` | Pan, scale, long-press detected |
| 3.4 | Implement gesture throttling (one bridge call per frame) | `chart_gesture_handler.dart` | Bridge calls ≤60/sec during fast drag |
| 3.5 | Implement `ViewportCalculator.applyPanDelta()` — shift visible range | Both platforms | Viewport scrolls, clamped to data bounds |
| 3.6 | Implement `ViewportCalculator.applyScale()` — zoom with focal point | Both platforms | Zoom in/out, centered on pinch point, clamped to min/max |
| 3.7 | Implement edge clamping — prevent scrolling past first/last candle | `ViewportCalculator` both platforms | Cannot scroll into empty space beyond data bounds |
| 3.8 | Implement `ViewportCalculator.startFling()` — deceleration animation | Both platforms | Smooth momentum scroll after fast pan |
| 3.9 | Implement `isAtLatest` tracking | `ViewportCalculator` both platforms | Flag correct after pan, fling, scroll-to-end |
| 3.10 | Wire `onPanUpdate`, `onPanEnd`, `onScaleUpdate`, `onScaleEnd` through bridge | `ChartHostApiImpl` both platforms | Gesture events reach engine |
| 3.11 | Implement `ChartFlutterApi.onViewportChanged()` — push viewport to Flutter | `ChartFlutterApiHolder` both platforms, `ChartBridge` Dart | Viewport stream emits on change |
| 3.12 | Implement `controller.scrollToEnd()` | Dart + both platforms | Scrolls to latest, re-enables auto-scroll |
| 3.13 | Test pan on example app | Manual | Smooth horizontal scroll, fling, edge clamping |
| 3.14 | Test zoom on example app | Manual | Pinch zoom in/out, focal point stability |

### Phase 3 Milestone
Chart pans smoothly with momentum/fling, pinch-zooms with stable focal point, clamps at data edges. Viewport change events flow to Dart.

---

## Phase 4: Interactive Features + Realtime

**Goal:** Crosshair, markers, line chart mode, timeframe switching, and realtime updates work.

**Duration:** Week 4–5

### Tasks

| # | Task | Files | Criteria |
|---|------|-------|----------|
| 4.1 | Implement `CrosshairRenderer` — horizontal + vertical lines, value labels | Both platforms | Crosshair draws at correct position |
| 4.2 | Implement crosshair snap-to-candle logic in `ViewportCalculator` | Both platforms | Crosshair snaps to nearest candle center |
| 4.3 | Wire long-press gesture → `onCrosshairStart/Move/End` | Dart gesture handler + bridge + native | Crosshair appears on long-press, tracks finger |
| 4.4 | Implement `ChartFlutterApi.onCrosshairData()` — push OHLCV to Dart | Both platforms + Dart | CrosshairEvent stream emits with correct data |
| 4.5 | Implement `MarkerStore` — set, add, clear, visible range query | `data/MarkerStore.kt`, `Data/MarkerStore.swift` | Stores and queries markers |
| 4.6 | Implement `MarkerRenderer` — draw buy/sell arrows at price/time | Both platforms | Buy arrows below candle (green), sell above (red) |
| 4.7 | Wire marker bridge methods (`setMarkers`, `addMarker`, `clearMarkers`) | Both platforms + Dart | Markers appear after `controller.setMarkers()` |
| 4.8 | Implement `LineRenderer` — close-price line with optional gradient fill | Both platforms | Smooth line connects close prices |
| 4.9 | Implement chart type switching (candle ↔ line) | `ChartEngine` both platforms + Dart | `controller.setChartType(ChartType.line)` switches renderer |
| 4.10 | Implement `CandleStore.append()` and `CandleStore.updateLast()` | Both platforms | Correct array mutation |
| 4.11 | Implement auto-scroll on append when `isAtLatest` | `ViewportCalculator` both platforms | Viewport shifts when new candle arrives at latest |
| 4.12 | Wire `controller.appendCandle()` and `controller.updateLastCandle()` | Dart + bridge + native | End-to-end realtime update |
| 4.13 | Implement timeframe switching (`setTimeframe` → clear → load) | Dart + native | Clean transition between timeframes |
| 4.14 | Create `FakeRealtimeStream` in example app | `example/lib/data/fake_realtime_stream.dart` | Simulates ticking candles with random price movement |
| 4.15 | Update example app with timeframe bar + realtime toggle + marker demo | `example/lib/` | Full interactive demo |

### Phase 4 Milestone
Crosshair works with OHLCV readout. Buy/sell markers render. Line chart mode works. Realtime candle updates display smoothly. Timeframe switching is clean. Example app demonstrates all features.

---

## Phase 5: Polish and Package

**Goal:** Production-ready package with documentation, error handling, edge cases, and performance validation.

**Duration:** Week 5–7

### Tasks

| # | Task | Files | Criteria |
|---|------|-------|----------|
| 5.1 | Error handling — engine init failures, invalid data, double-dispose | All bridge + engine files | Graceful errors, no crashes |
| 5.2 | Size change handling — orientation rotation, layout animation | `_TradeChartState` + native | Chart resizes without flicker or data loss |
| 5.3 | Edge cases — empty data, single candle, all same price, extreme zoom | All renderers | No crash, reasonable visual |
| 5.4 | Memory leak audit — dispose releases all native resources | Android + iOS | No leaked surfaces, textures, or callbacks |
| 5.5 | Widget rebuild handling — `didUpdateWidget` for theme/config changes | `_TradeChartState` | Theme hot-swap works |
| 5.6 | `ChartFlutterApi.onError()` implementation | Both platforms | Errors flow to Dart |
| 5.7 | Write Dart unit tests — models, mapper, controller, gesture handler | `test/` | >80% coverage on Dart code |
| 5.8 | Write integration test — load candles, verify texture renders | `integration_test/` | Passes on CI |
| 5.9 | Performance profiling on Android (Pixel 6-class device) | — | Pan/zoom at 60fps with 5K candles, render <5ms |
| 5.10 | Performance profiling on iOS (iPhone 12-class device) | — | Same targets |
| 5.11 | Profile memory for 50K candle load | — | <30MB native heap |
| 5.12 | Polish example app — full-screen chart, dark scaffold, timeframe selector, realtime toggle | `example/` | Professional demo |
| 5.13 | Write package README.md — installation, basic usage, API overview | `README.md` | Clear, concise, working code examples |
| 5.14 | Write CHANGELOG.md | `CHANGELOG.md` | V1.0.0 entry |
| 5.15 | Dartdoc comments on all public APIs | All `lib/src/` public files | `dart doc` generates clean docs |
| 5.16 | Configure analysis_options.yaml with strict lints | `analysis_options.yaml` | Zero analysis warnings |
| 5.17 | License file | `LICENSE` | MIT or chosen license |
| 5.18 | Final dry-run: `flutter pub publish --dry-run` | — | No errors |

### Phase 5 Milestone
Package is ready for pub.dev publication or private distribution. All V1 features work, performance targets met, documentation complete, no known crashes.

---

## Phase Dependencies

```
Phase 1 ──► Phase 2 ──► Phase 3 ──► Phase 4 ──► Phase 5
skeleton     static      gestures    interactive   polish
             render                  + realtime

Parallel opportunities:
- Android + iOS native work within each phase can be parallelized
- Dart model/test work can happen alongside native engine work
- Example app updates can happen incrementally
```

---

## Risk Checkpoints

| After Phase | Check | Action if Failed |
|-------------|-------|-----------------|
| 1 | Texture visible on both platforms | Debug platform-specific texture registration; this is the highest-risk step |
| 2 | Static chart renders in <10ms | Profile renderers individually; optimize hotspot before adding gestures |
| 3 | Pan at 60fps | Profile bridge call frequency; check for GC pauses; reduce render complexity |
| 4 | Realtime updates don't cause jank | Verify dirty coalescing works; check for unnecessary re-renders |
| 5 | Passes performance targets on real devices | Apply V2 optimizations early if needed (layer caching, binary bridge) |
