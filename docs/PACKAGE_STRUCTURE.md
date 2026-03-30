# Package Structure — trade_chart SDK V1

## Package Identity

| Field | Value |
|-------|-------|
| Package name | `trade_chart` |
| Min Flutter SDK | `3.16.0` |
| Min Android SDK | `23` (Android 6.0) |
| Min iOS | `13.0` |
| Plugin type | `flutter` (federated plugin, single package for V1) |
| Pigeon version | `^22.0.0` (latest stable) |

---

## Directory Tree

```
trade_chart/
├── pubspec.yaml
├── LICENSE
├── README.md
├── CHANGELOG.md
├── analysis_options.yaml
│
├── lib/
│   ├── trade_chart.dart                         # barrel export (public API only)
│   └── src/
│       ├── trade_chart_widget.dart               # TradeChart StatefulWidget
│       ├── trade_chart_controller.dart            # TradeChartController
│       ├── trade_chart_theme.dart                 # TradeChartTheme
│       ├── trade_chart_config.dart                # TradeChartConfig
│       │
│       ├── models/
│       │   ├── candle_data.dart                   # CandleData value class
│       │   ├── chart_marker.dart                  # ChartMarker value class
│       │   ├── chart_timeframe.dart               # ChartTimeframe enum
│       │   ├── chart_type.dart                    # ChartType enum (candle, line)
│       │   └── viewport_state.dart                # ViewportState value class
│       │
│       ├── events/
│       │   ├── crosshair_event.dart               # CrosshairEvent
│       │   └── viewport_event.dart                # ViewportChangeEvent
│       │
│       ├── gestures/
│       │   ├── chart_gesture_handler.dart          # Gesture state machine
│       │   └── gesture_state.dart                  # GestureMode enum + state
│       │
│       └── bridge/
│           ├── chart_bridge.dart                   # Façade wrapping Pigeon APIs
│           ├── generated/
│           │   └── chart_api.g.dart                # Pigeon generated Dart code
│           └── bridge_mapper.dart                  # Maps public models ↔ Pigeon messages
│
├── pigeons/
│   └── chart_api.dart                             # Pigeon interface definitions
│
├── android/
│   ├── build.gradle.kts
│   ├── src/main/
│   │   └── kotlin/com/tradechart/plugin/
│   │       ├── TradeChartPlugin.kt                # Flutter plugin entry point
│   │       ├── bridge/
│   │       │   ├── ChartHostApiImpl.kt            # Pigeon host API implementation
│   │       │   ├── ChartFlutterApiHolder.kt       # Holds FlutterApi reference
│   │       │   └── generated/
│   │       │       └── ChartApi.g.kt              # Pigeon generated Kotlin code
│   │       ├── engine/
│   │       │   ├── ChartEngine.kt                 # Orchestrator: owns renderers + frame loop
│   │       │   ├── TextureRenderer.kt             # SurfaceTexture + Surface management
│   │       │   └── ChartFrame.kt                  # Single frame rendering context
│   │       ├── renderer/
│   │       │   ├── ChartLayerRenderer.kt          # Interface for all renderers
│   │       │   ├── BackgroundRenderer.kt
│   │       │   ├── GridRenderer.kt
│   │       │   ├── VolumeRenderer.kt
│   │       │   ├── CandleRenderer.kt
│   │       │   ├── LineRenderer.kt
│   │       │   ├── MarkerRenderer.kt
│   │       │   ├── AxisRenderer.kt
│   │       │   └── CrosshairRenderer.kt
│   │       ├── data/
│   │       │   ├── CandleStore.kt                 # In-memory candle array
│   │       │   └── MarkerStore.kt                 # In-memory marker list
│   │       ├── viewport/
│   │       │   └── ViewportCalculator.kt          # Visible range, zoom, y-axis
│   │       └── theme/
│   │           └── NativeChartTheme.kt            # Deserialized theme (Paint cache)
│   └── proguard-rules.pro
│
├── ios/
│   ├── trade_chart.podspec
│   ├── Classes/
│   │   ├── TradeChartPlugin.swift                 # Flutter plugin entry point
│   │   ├── Bridge/
│   │   │   ├── ChartHostApiImpl.swift             # Pigeon host API implementation
│   │   │   ├── ChartFlutterApiHolder.swift
│   │   │   └── Generated/
│   │   │       └── ChartApi.g.swift               # Pigeon generated Swift code
│   │   ├── Engine/
│   │   │   ├── ChartEngine.swift                  # Orchestrator
│   │   │   ├── TextureRenderer.swift              # CVPixelBuffer management
│   │   │   └── ChartFrame.swift
│   │   ├── Renderer/
│   │   │   ├── ChartLayerRenderer.swift           # Protocol for all renderers
│   │   │   ├── BackgroundRenderer.swift
│   │   │   ├── GridRenderer.swift
│   │   │   ├── VolumeRenderer.swift
│   │   │   ├── CandleRenderer.swift
│   │   │   ├── LineRenderer.swift
│   │   │   ├── MarkerRenderer.swift
│   │   │   ├── AxisRenderer.swift
│   │   │   └── CrosshairRenderer.swift
│   │   ├── Data/
│   │   │   ├── CandleStore.swift
│   │   │   └── MarkerStore.swift
│   │   ├── Viewport/
│   │   │   └── ViewportCalculator.swift
│   │   └── Theme/
│   │       └── NativeChartTheme.swift
│   └── Assets/
│
├── example/
│   ├── pubspec.yaml
│   ├── lib/
│   │   ├── main.dart                              # Example app entry
│   │   ├── screens/
│   │   │   └── chart_screen.dart                  # Full-screen chart demo
│   │   ├── data/
│   │   │   ├── sample_candles.dart                # Static sample data
│   │   │   └── fake_realtime_stream.dart          # Simulated WS stream
│   │   └── widgets/
│   │       └── timeframe_bar.dart                 # Timeframe selector UI
│   └── android/
│   └── ios/
│
├── test/
│   ├── models/
│   │   ├── candle_data_test.dart
│   │   └── chart_marker_test.dart
│   ├── controller/
│   │   └── trade_chart_controller_test.dart
│   ├── gestures/
│   │   └── chart_gesture_handler_test.dart
│   └── bridge/
│       └── bridge_mapper_test.dart
│
└── docs/
    ├── ARCHITECTURE.md
    ├── TECH_DECISIONS.md
    ├── PACKAGE_STRUCTURE.md    (this file)
    ├── API_SPEC.md
    ├── BRIDGE_CONTRACT.md
    ├── DATA_FLOW.md
    ├── PERFORMANCE_PLAN.md
    ├── ROADMAP.md
    ├── RISKS.md
    └── V1_SCOPE.md
```

---

## Module Responsibilities

### Flutter — `lib/src/`

| File | Class | Responsibility |
|------|-------|---------------|
| `trade_chart_widget.dart` | `TradeChart` | Public `StatefulWidget`. Manages lifecycle, creates `Texture` + `GestureDetector`, forwards size to native. |
| `trade_chart_controller.dart` | `TradeChartController` | Public controller. Exposes data loading, realtime updates, markers, chart type, timeframe, scroll control. Internally delegates to bridge. Exposes `Stream<CrosshairEvent>`, `Stream<ViewportChangeEvent>`. |
| `trade_chart_theme.dart` | `TradeChartTheme` | Immutable value class with all colors, text styles, spacing. Has `const TradeChartTheme.dark()` factory. `copyWith()` support. |
| `trade_chart_config.dart` | `TradeChartConfig` | Immutable config: `showVolume`, `showGrid`, `showCrosshair`, `showAxis`, `volumeHeightRatio`, `maxVisibleCandles`, `minVisibleCandles`, `initialChartType`. |
| `models/candle_data.dart` | `CandleData` | Value class: `timestamp`, `open`, `high`, `low`, `close`, `volume`. |
| `models/chart_marker.dart` | `ChartMarker` | Value class: `id`, `timestamp`, `price`, `type` (buy/sell), `label`. |
| `models/chart_timeframe.dart` | `ChartTimeframe` | Enum: `m1, m3, m5, m15, m30, h1, h4, d1, w1, M1`. |
| `models/chart_type.dart` | `ChartType` | Enum: `candle, line`. |
| `models/viewport_state.dart` | `ViewportState` | Value class: `startTimestamp`, `endTimestamp`, `priceHigh`, `priceLow`, `visibleCandleCount`, `candleWidth`. |
| `events/crosshair_event.dart` | `CrosshairEvent` | Value class: `timestamp`, `open`, `high`, `low`, `close`, `volume`, `x`, `y`. |
| `events/viewport_event.dart` | `ViewportChangeEvent` | Wraps `ViewportState` with optional `isAtLatest` flag. |
| `gestures/chart_gesture_handler.dart` | `ChartGestureHandler` | State machine: processes raw Flutter gestures → emits semantic bridge calls. Handles pan, zoom, crosshair, fling prevention. |
| `gestures/gesture_state.dart` | `GestureMode` | Enum: `idle, panning, zooming, crosshair`. |
| `bridge/chart_bridge.dart` | `ChartBridge` | Wraps `ChartHostApi` + `ChartFlutterApi`, handles mapping between public models and Pigeon messages. |
| `bridge/bridge_mapper.dart` | `BridgeMapper` | Static methods converting `CandleData` ↔ `CandleDataMessage`, `ChartMarker` ↔ `MarkerMessage`, etc. |

### Android — `android/src/main/kotlin/`

| File | Class | Responsibility |
|------|-------|---------------|
| `TradeChartPlugin.kt` | `TradeChartPlugin` | `FlutterPlugin`. Registers Pigeon APIs, obtains `TextureRegistry`, manages engine lifecycle. |
| `bridge/ChartHostApiImpl.kt` | `ChartHostApiImpl` | Implements `ChartHostApi`. Dispatches calls to `ChartEngine`. |
| `bridge/ChartFlutterApiHolder.kt` | `ChartFlutterApiHolder` | Holds `ChartFlutterApi` instance for native → Flutter callbacks. |
| `engine/ChartEngine.kt` | `ChartEngine` | Central orchestrator. Owns `CandleStore`, `ViewportCalculator`, renderer list, dirty flag, frame callback scheduling. |
| `engine/TextureRenderer.kt` | `TextureRenderer` | Creates `SurfaceTexture`, binds `Surface`, manages size changes, provides `Canvas` for drawing, signals Flutter engine on new frames. |
| `engine/ChartFrame.kt` | `ChartFrame` | Per-frame context: canvas, viewport snapshot, theme, config, chart dimensions. Passed to each renderer. |
| `renderer/ChartLayerRenderer.kt` | `ChartLayerRenderer` | Interface: `fun render(frame: ChartFrame)` |
| `renderer/BackgroundRenderer.kt` | `BackgroundRenderer` | Fills canvas with background color. |
| `renderer/GridRenderer.kt` | `GridRenderer` | Draws horizontal price lines and vertical time lines. |
| `renderer/VolumeRenderer.kt` | `VolumeRenderer` | Draws volume bars in the bottom region. |
| `renderer/CandleRenderer.kt` | `CandleRenderer` | Draws OHLC candlestick bodies and wicks. |
| `renderer/LineRenderer.kt` | `LineRenderer` | Draws close-price line with optional fill. |
| `renderer/MarkerRenderer.kt` | `MarkerRenderer` | Draws buy/sell markers at given timestamp/price. |
| `renderer/AxisRenderer.kt` | `AxisRenderer` | Draws price labels (right edge), time labels (bottom edge). |
| `renderer/CrosshairRenderer.kt` | `CrosshairRenderer` | Draws crosshair lines and value labels. |
| `data/CandleStore.kt` | `CandleStore` | Contiguous array of candle data. Supports `load()`, `append()`, `updateLast()`, binary search by timestamp, range queries. |
| `data/MarkerStore.kt` | `MarkerStore` | List of markers. Supports `set()`, `add()`, `clear()`, range queries for visible markers. |
| `viewport/ViewportCalculator.kt` | `ViewportCalculator` | Computes visible index range, candle width in pixels, y-axis min/max with padding, auto-scroll state. Handles pan delta, scale, and fling. |
| `theme/NativeChartTheme.kt` | `NativeChartTheme` | Holds deserialized theme. Pre-allocates `Paint` objects for bull, bear, grid, text, etc. Avoids allocation during render. |

### iOS — `ios/Classes/`

Mirror of Android structure with Swift equivalents:

| File | Class | Notes |
|------|-------|-------|
| `TradeChartPlugin.swift` | `TradeChartPlugin` | `FlutterPlugin`. Registers with `FlutterTextureRegistry`. |
| `Bridge/ChartHostApiImpl.swift` | `ChartHostApiImpl` | Same contract as Android. |
| `Engine/ChartEngine.swift` | `ChartEngine` | Uses `CADisplayLink` for frame scheduling. |
| `Engine/TextureRenderer.swift` | `TextureRenderer` | Creates `CVPixelBuffer`, obtains `CGContext`, signals texture update. |
| `Renderer/*.swift` | Same renderer set | Uses `CGContext` drawing APIs (CGContextFillRect, CGContextStrokePath, etc.) |
| `Data/CandleStore.swift` | `CandleStore` | Swift array-based. Same interface as Kotlin. |
| `Viewport/ViewportCalculator.swift` | `ViewportCalculator` | Same logic as Kotlin. |
| `Theme/NativeChartTheme.swift` | `NativeChartTheme` | Pre-allocates `CGColor`, `CTFont` objects. |

---

## Naming Conventions

| Layer | Language | Convention | Example |
|-------|----------|-----------|---------|
| Dart public | Dart | `snake_case` files, `PascalCase` classes | `candle_data.dart`, `CandleData` |
| Dart private | Dart | `_` prefix for private | `_TradeChartState` |
| Android | Kotlin | `PascalCase` files + classes | `CandleRenderer.kt`, `CandleRenderer` |
| iOS | Swift | `PascalCase` files + classes | `CandleRenderer.swift`, `CandleRenderer` |
| Pigeon defs | Dart | `PascalCase` with `Message` suffix for DTOs | `CandleDataMessage` |
| Pigeon generated | per-platform | Pigeon default naming | `ChartApi.g.dart`, `ChartApi.g.kt`, `ChartApi.g.swift` |

---

## Barrel Export (`lib/trade_chart.dart`)

Only export public API surface. Never export bridge, generated code, or internal gesture classes.

```dart
// lib/trade_chart.dart
library trade_chart;

export 'src/trade_chart_widget.dart';
export 'src/trade_chart_controller.dart';
export 'src/trade_chart_theme.dart';
export 'src/trade_chart_config.dart';
export 'src/models/candle_data.dart';
export 'src/models/chart_marker.dart';
export 'src/models/chart_timeframe.dart';
export 'src/models/chart_type.dart';
export 'src/models/viewport_state.dart';
export 'src/events/crosshair_event.dart';
export 'src/events/viewport_event.dart';
```
