# Architecture — trade_chart SDK V1

## Executive Summary

`trade_chart` is a Flutter plugin package that delivers a high-performance trading chart by delegating all rendering and data management to native platform engines (Android/iOS) and compositing the result via Flutter's `Texture` widget. Flutter owns the public API surface, gesture capture, widget overlay, and lifecycle management. Native owns the rendering pipeline, candle data store, viewport arithmetic, and frame scheduling.

---

## Layered Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Consumer App                           │
│  TradeChart widget · TradeChartController · CandleData      │
├─────────────────────────────────────────────────────────────┤
│                  Flutter Public API Layer                    │
│  TradeChart (StatefulWidget)                                │
│  TradeChartController                                       │
│  TradeChartTheme / TradeChartConfig                         │
│  Models: CandleData, ChartMarker, ChartTimeframe            │
│  Events: CrosshairEvent, ViewportEvent                      │
├─────────────────────────────────────────────────────────────┤
│                  Flutter Internal Layer                      │
│  _TradeChartState (Texture + GestureDetector)               │
│  ChartGestureHandler (pan/zoom/crosshair state machine)     │
│  Bridge façade (wraps Pigeon-generated code)                │
├─────────────────────────────────────────────────────────────┤
│            Pigeon Bridge (generated code)                    │
│  ChartHostApi   (Flutter → Native)                          │
│  ChartFlutterApi (Native → Flutter)                         │
├─────────────────────────────────────────────────────────────┤
│               Native Chart Engine (per-platform)            │
│  ChartEngine  — orchestrator, owns render loop              │
│  CandleStore  — in-memory candle array                      │
│  ViewportCalculator — visible range, zoom, y-axis scale     │
│  Renderers: Background, Grid, Volume, Candle, Line,        │
│             Marker, Axis, Crosshair                         │
│  TextureRenderer — manages SurfaceTexture / CVPixelBuffer   │
└─────────────────────────────────────────────────────────────┘
```

---

## Ownership Boundaries

| Concern                | Owner           | Rationale |
|------------------------|-----------------|-----------|
| Public widget API      | Flutter         | Dart is the consumer-facing language |
| Gesture capture        | Flutter         | Flutter's gesture arena is robust and avoids PlatformView conflicts |
| Gesture interpretation | Native          | Pan deltas → viewport shift; scale → zoom; positions → crosshair |
| Candle data storage    | Native          | Avoids serializing large datasets across the bridge repeatedly |
| Viewport state         | Native          | Tightly coupled with rendering; single source of truth |
| Rendering pipeline     | Native          | 2D Canvas (Android) / CoreGraphics (iOS) for 60 fps drawing |
| Frame scheduling       | Native          | Choreographer (Android) / CADisplayLink (iOS) |
| Texture compositing    | Flutter Engine  | Texture widget is lightweight and avoids PlatformView overhead |
| Crosshair data output  | Native → Flutter| Native resolves coordinates to OHLCV, sends via FlutterApi |
| Lifecycle management   | Flutter         | Widget init/dispose drives native engine create/destroy |
| Theme / config         | Flutter → Native| Dart-side config objects serialized once at init + on change |

---

## Rendering Strategy

The SDK uses Flutter's **Texture** embedding approach:

1. On widget init, Flutter requests a texture ID from the native `TextureRegistry`.
2. Native creates a rendering surface bound to that texture:
   - **Android**: `SurfaceTexture` → `Surface` → draw with `android.graphics.Canvas`
   - **iOS**: `CVPixelBuffer` via `FlutterTextureRegistry` → draw with `CGContext`
3. Flutter displays the texture via `Texture(textureId: id)`.
4. On each frame that needs redraw, native draws all chart layers onto the surface and signals the Flutter engine that the texture has new content.
5. Flutter composites the texture into the widget tree at the GPU level — no pixel copying.

This approach avoids PlatformView overhead, z-ordering issues, and gesture conflicts while preserving native rendering performance.

---

## Bridge Strategy

Communication uses **Pigeon** for type-safe, code-generated platform channels:

- `ChartHostApi` — Flutter calls native (init, load data, gestures, config changes)
- `ChartFlutterApi` — Native calls Flutter (viewport updates, crosshair data, errors)

High-frequency gesture events (pan, crosshair move) are sent via the same Pigeon host API. Pigeon's `BasicMessageChannel` encoding is efficient enough for these small payloads (~3 doubles per call). If profiling reveals overhead, V2 can introduce a binary `BasicMessageChannel` for gesture streams.

Bulk candle loads serialize via Pigeon's `List<CandleDataMessage>`. For datasets exceeding ~50K candles, a future binary transfer channel can be added without changing the public API.

---

## Gesture Architecture

```
┌──────────────────────────────────────────────────┐
│   Flutter GestureDetector (unified ScaleGesture)  │
│                                                    │
│  onScaleStart / onScaleUpdate / onScaleEnd         │
│    pointerCount == 1 → pan (focalPointDelta.dx)    │
│    pointerCount >= 2 → zoom (scale, focalPoint)    │
│  onLongPressStart / onLongPressMoveUpdate / End    │
└──────────────────┬───────────────────────────────┘
                   │ processed deltas / positions
                   ▼
┌──────────────────────────────────────────────────┐
│      ChartGestureHandler                          │
│  State machine: idle → panning → (fling on end)   │
│                  idle → zooming                    │
│                  idle → crosshair                  │
│  Pan deltas coalesced (max 1 bridge call / frame) │
│  Pan → zoom transition flushes pending delta       │
└──────────────────┬───────────────────────────────┘
                   │ ChartHostApi calls
                   ▼
┌──────────────────────────────────────────────────┐
│      Native ChartEngine                           │
│  Applies gesture to ViewportCalc                   │
│  Marks chart dirty → schedules frame               │
└──────────────────────────────────────────────────┘
```

**Critical design choice:** The widget uses ONLY `ScaleGestureRecognizer` (via `onScale*`), never `HorizontalDragGestureRecognizer`. Flutter's `ScaleGestureRecognizer` handles both single-finger pan and two-finger zoom natively. Registering both `onHorizontalDrag*` and `onScale*` on the same `GestureDetector` causes gesture arena conflicts where the two recognizers fight for ownership, resulting in stuck/frozen panning.

Gesture states:
- **Idle**: no active gesture
- **Panning**: single-finger horizontal scroll via `onScaleUpdate` with `pointerCount == 1`, sends `onPanUpdate(deltaX)` derived from `focalPointDelta.dx`
- **Flinging**: after pan ends with velocity, native runs deceleration animation via `Choreographer` / `CADisplayLink`
- **Zooming**: two-finger pinch via `onScaleUpdate` with `pointerCount >= 2`, sends `onScaleUpdate(scaleFactor, focalPointX)`. Once zooming starts, it stays zooming until gesture ends (prevents jitter when lifting one finger).
- **Crosshair**: long-press + drag (separate `LongPressGestureRecognizer`), sends `onCrosshairMove(x, y)`

The state machine prevents conflicting gestures (e.g., crosshair cannot start during a pan, zoom ignores during crosshair).

---

## Realtime Update Model

The SDK does **not** own WebSocket connections. The consumer app manages its data source and pushes updates to the SDK:

```
App WebSocket → App logic → controller.appendCandle(candle)
                           → controller.updateLastCandle(candle)
```

Native handles the merge:
- `appendCandle`: appends to `CandleStore`, auto-scrolls if viewport is at latest
- `updateLastCandle`: replaces last candle in store, re-renders in place

This decoupling means the SDK works with any data source: REST polling, WebSocket, gRPC, local replay, etc.

---

## Event / Callback Model

Callbacks flow from native to Flutter via `ChartFlutterApi`:

| Event                | Payload                          | Trigger |
|----------------------|----------------------------------|---------|
| `onChartReady`       | —                                | Texture registered, first frame rendered |
| `onViewportChanged`  | `ViewportState`                  | After any viewport mutation (pan, zoom, data load) |
| `onCrosshairData`    | `CrosshairData` (price, time, OHLCV) | Crosshair move |
| `onError`            | code + message                   | Engine error (e.g., texture allocation failure) |

Flutter-side, the controller exposes these as `Stream<T>` for reactive consumption and as widget callback props for declarative use.

---

## Native Engine Internals

### Renderer Composition

Each visual layer is a separate renderer class with a single `render(canvas, viewport, theme)` method:

1. `BackgroundRenderer` — fills background color
2. `GridRenderer` — horizontal price lines, vertical time lines
3. `VolumeRenderer` — volume bars in bottom region
4. `CandleRenderer` — OHLC candlesticks (or `LineRenderer` for line mode)
5. `MarkerRenderer` — buy/sell triangles/arrows at price+time
6. `AxisRenderer` — price labels (right), time labels (bottom)
7. `CrosshairRenderer` — horizontal + vertical lines with value labels

`ChartEngine` calls renderers in order on each frame. Renderers are stateless — all state comes from `CandleStore`, `ViewportCalculator`, and theme/config.

### Frame Scheduling

- Native maintains a `dirty` flag.
- When dirty, the engine requests a frame callback via `Choreographer.postFrameCallback` (Android) / `CADisplayLink` (iOS).
- On callback: render all layers → mark texture as available → clear dirty flag.
- This ensures at most one render per vsync and zero renders when idle.

---

## Widget Tree (Flutter side)

```
TradeChart (StatefulWidget)
└── LayoutBuilder
    └── Stack
        ├── GestureDetector
        │   └── Texture(textureId: _textureId)
        └── (future: Flutter overlay widgets for tooltips, etc.)
```

`LayoutBuilder` reports pixel dimensions to native so the engine sizes its surface correctly. The `Stack` allows future Flutter overlays (e.g., a crosshair tooltip widget) to float above the texture without requiring native rendering for every UI element.

---

## Initialization Sequence

```
1. TradeChart widget inserted into tree
2. _TradeChartState.initState()
3.   → controller._attach(this)
4.   → ChartHostApi.initialize(width, height, pixelRatio, theme, config)
5.     → Native allocates SurfaceTexture / CVPixelBuffer
6.     → Native returns textureId
7.   → setState: _textureId = id
8.   → Texture widget renders (initially blank)
9. Consumer calls controller.loadCandles(candles, timeframe)
10.  → ChartHostApi.loadCandles(serialized candles)
11.  → Native stores data, calculates viewport, renders first frame
12.  → ChartFlutterApi.onChartReady()
13.  → ChartFlutterApi.onViewportChanged(initialViewport)
```

---

## Dispose Sequence

```
1. TradeChart widget removed from tree
2. _TradeChartState.dispose()
3.   → ChartHostApi.dispose()
4.   → Native releases Surface / CVPixelBuffer
5.   → Native unregisters texture
6.   → controller._detach()
```

---

## Design Constraints for Future Extensibility

- Renderers are a list — adding an indicator is adding a renderer + its data source
- The bridge contract is versioned — new methods can be added without breaking existing ones
- `TradeChartConfig` uses a builder/copyWith pattern — new options are additive
- `ChartEngine` can support multiple panes (main + indicator sub-charts) by managing multiple renderer lists and dividing the canvas vertically
- Marker/annotation system is generic (id, timestamp, price, type) — extensible for order lines, alerts, drawings
