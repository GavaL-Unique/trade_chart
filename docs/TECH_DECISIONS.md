# Technical Decisions — trade_chart SDK V1

This document records every significant technical choice, the alternatives evaluated, and the rationale for the decision made.

---

## 1. Embedding Strategy

### Options Evaluated

| Approach | How It Works | Pros | Cons |
|----------|-------------|------|------|
| **PlatformView** (`AndroidView` / `UiKitView`) | Embeds a native view directly into the Flutter widget tree | Full native rendering + native gestures, access to native UI libraries | Android: Virtual Display has perf issues, Hybrid Composition adds overhead; iOS: z-ordering edge cases; gesture conflicts with Flutter; harder to overlay Flutter widgets |
| **Texture** (`Texture` widget) | Native renders to a GPU buffer; Flutter composites it as a texture | No PlatformView overhead, no z-ordering issues, Flutter-side gestures work cleanly, easy Flutter overlays | Must implement texture registration plumbing; gestures must be forwarded from Flutter to native |
| **CustomPainter** (pure Flutter) | Dart `Canvas` draws everything | Single codebase, no native code, Flutter gestures native | Dart rendering throughput ceiling for large datasets; no native GPU acceleration; harder to hit 60 fps with 5K+ candles during pan |

### Decision: **Texture**

**Primary reasons:**

1. **Performance**: Native rendering (Canvas/CoreGraphics) is faster than Dart CustomPainter for drawing thousands of primitives. The texture is composited by the Flutter engine at the GPU level with zero pixel copies.

2. **Gesture clarity**: Flutter's `GestureDetector` works normally on top of a `Texture` widget. No gesture conflict resolution needed, unlike PlatformView where native and Flutter gesture systems compete.

3. **Overlay capability**: Because `Texture` is a normal Flutter widget, we can place Flutter widgets above it in a `Stack` — useful for tooltips, crosshair value labels, or future indicator panels.

4. **Platform consistency**: The Texture approach behaves identically on Android and iOS. PlatformView has platform-specific quirks (Virtual Display vs Hybrid Composition on Android, different lifecycle behavior on iOS).

5. **SDK distribution**: Texture-based plugins have fewer platform edge cases in consumer apps. PlatformView plugins are notorious for subtle bugs when combined with other PlatformViews or specific Flutter navigation patterns.

**Accepted tradeoffs:**

- We must implement `SurfaceTexture` registration on Android and `CVPixelBuffer` registration on iOS. This is well-documented Flutter API surface and is a one-time cost.
- Gestures are captured in Flutter and forwarded to native. The latency of a single platform channel call (~0.1ms) is negligible compared to the 16ms frame budget.

---

## 2. Bridge / Communication Strategy

### Options Evaluated

| Approach | How It Works | Pros | Cons |
|----------|-------------|------|------|
| **MethodChannel** (manual) | String-based method dispatch, manual serialization | Simple to start, no build step | Error-prone, no type safety, tedious for many methods |
| **Pigeon** (code generation) | Dart interface definitions generate platform channel code for Dart, Kotlin, Swift | Type-safe, IDE-friendly, reduces boilerplate, generates both host and flutter APIs | Build step required, generated code is verbose (but hidden) |
| **FFI** (`dart:ffi`) | Dart calls C functions directly | Zero serialization overhead, shared C library across platforms | Requires C/C++ rendering core; debugging is harder; callbacks from C to Dart are complex; doesn't help with platform-specific APIs (SurfaceTexture, CVPixelBuffer) |
| **EventChannel** | Native pushes stream events to Flutter | Good for continuous data streams | One-directional only (native → Dart), untyped |

### Decision: **Pigeon** (primary) + potential EventChannel supplement

**Primary reasons:**

1. **Type safety**: Pigeon generates Kotlin/Swift/Dart code from a single Dart interface definition. Every method signature, parameter type, and return type is checked at compile time on all platforms.

2. **Bidirectional**: We need both Flutter→Native (`ChartHostApi` for commands and gestures) and Native→Flutter (`ChartFlutterApi` for viewport updates and crosshair data). Pigeon supports both via `@HostApi()` and `@FlutterApi()`.

3. **SDK quality**: Generated code is consistent and well-tested. Manual MethodChannels in an SDK are a maintenance liability.

4. **Performance**: Pigeon uses `BasicMessageChannel` with `StandardMessageCodec` under the hood. For our payloads (a few doubles per gesture event, lists of candle objects for bulk loads), this is efficient. A single gesture event serializes to ~50 bytes. At 60 calls/second during a fast pan, that's ~3KB/s — negligible.

**Why not FFI:**

FFI would be optimal if we had a shared C/C++ rendering engine (like Skia). But our rendering uses platform-specific APIs (`android.graphics.Canvas`, `CoreGraphics`). FFI doesn't help access these. A shared C core would add massive complexity for marginal gain in V1.

FFI remains a V3 option if we move to a cross-platform rendering engine (e.g., a shared Skia/Metal abstraction in C++).

---

## 3. Rendering API (per platform)

### Android

| Option | Pros | Cons |
|--------|------|------|
| `android.graphics.Canvas` | Simple 2D API, hardware-accelerated on modern devices, direct Surface access | Software fallback on old devices (irrelevant for our min SDK) |
| OpenGL ES via EGL | Full GPU control, shaders | Complex setup, overkill for 2D charts |
| Vulkan | Maximum GPU performance | Massive complexity, Android 7+ only, not justified |

**Decision: `android.graphics.Canvas`**

Trading charts are 2D drawings: rectangles (candles), lines (grid, crosshair), and text (labels). `Canvas` is hardware-accelerated by default, directly supports `Surface` (bound to `SurfaceTexture`), and the API surface is small and well-understood. OpenGL/Vulkan add complexity for zero visible benefit.

### iOS

| Option | Pros | Cons |
|--------|------|------|
| `CoreGraphics` (`CGContext`) | Simple 2D API, works with `CVPixelBuffer` | CPU-rendered (but fast for our primitives) |
| `Metal` | GPU-accelerated, modern | Complex setup, pipeline state objects for simple shapes |
| `CALayer` / CoreAnimation | Layer-based, GPU compositing | Not suited for per-frame custom drawing |

**Decision: `CoreGraphics` via `CGContext`**

Same reasoning as Android. 2D chart drawing does not justify Metal's complexity. CoreGraphics can render thousands of rectangles and lines at 60 fps on any modern iPhone. If profiling shows a bottleneck (unlikely for V1 data sizes), Metal is a surgical upgrade path for V2/V3.

---

## 4. Gesture Ownership

### Options

| Approach | Pros | Cons |
|----------|------|------|
| Flutter captures + forwards | Uses Flutter's mature gesture system; no PlatformView gesture conflicts; clean separation | Small bridge latency per event (~0.1ms) |
| Native captures (PlatformView) | Zero latency to native | Requires PlatformView; gesture conflict with Flutter; per-platform gesture code |
| Split (Flutter for some, native for others) | Theoretical best of both | Complex, hard to debug, state sync issues |

**Decision: Flutter captures all gestures, forwards semantic actions to native**

The Texture approach naturally puts Flutter in control of touch events (the `Texture` widget doesn't intercept touches). Wrapping it in `GestureDetector`/`Listener` and forwarding processed gesture state to native is clean and debuggable. The ~0.1ms bridge latency is invisible within a 16ms frame budget.

---

## 5. Viewport State Ownership

**Decision: Native owns viewport state**

The viewport (visible time range, y-axis price range, zoom level) is read on every render frame. Having it in native avoids a bridge round-trip per frame. Flutter receives viewport snapshots via `ChartFlutterApi.onViewportChanged()` for display purposes (e.g., showing the current time range in a header widget).

---

## 6. Data Store Ownership

**Decision: Native owns the candle data store**

Candle data is consumed by the native rendering pipeline on every frame. Storing it in Dart and transferring visible-range slices on every viewport change would be expensive and fragile. Native `CandleStore` holds the full dataset in a contiguous array for cache-friendly access. Dart never holds a copy of the full dataset.

---

## 7. Frame Scheduling Strategy

**Decision: Dirty-flag + platform vsync callback**

- A `needsRedraw` boolean flag on `ChartEngine`.
- Any mutation (data change, viewport change, crosshair move, config change) sets `needsRedraw = true` and requests a frame callback.
- **Android**: `Choreographer.getInstance().postFrameCallback()`
- **iOS**: `CADisplayLink` with target callback
- On callback: if dirty, render all layers to surface, mark texture available, clear flag.
- If not dirty, do nothing (no wasted frames).

This is the standard approach in native rendering engines and guarantees at most one render per vsync while idling at zero cost.

---

## 8. Candle Data Serialization

### For bulk loads (loadCandles)

**Decision: Pigeon `List<CandleDataMessage>` for V1**

Each `CandleDataMessage` contains: `timestamp (int64)`, `open`, `high`, `low`, `close`, `volume` (all double). Pigeon serializes this via `StandardMessageCodec` which handles `List<Map>` efficiently. For 10K candles this is ~1MB — acceptable for an initial load that happens once per timeframe switch.

**V2 upgrade path**: If profiling shows serialization overhead for 100K+ candles, switch to a `BasicMessageChannel<ByteData>` with a flat binary layout (48 bytes per candle). The public API (`controller.loadCandles(List<CandleData>)`) stays unchanged; only the internal bridge encoding changes.

### For realtime updates (appendCandle, updateLastCandle)

Single candle messages. Pigeon overhead is negligible (~50 bytes, ~0.05ms).

---

## 9. Chart Type Rendering

**Decision: Shared renderer infrastructure, swap renderers**

`CandleRenderer` and `LineRenderer` implement the same interface. `ChartEngine` holds a reference to the active price renderer. Switching chart type swaps the renderer reference and marks dirty. No data reload needed.

---

## 10. Theme / Config Transmission

**Decision: Serialize theme + config at init and on explicit change**

Theme and config are stable — they change when the user switches themes or toggles a setting, not per-frame. Serialized once via Pigeon at `initialize()` and again via `setTheme()` / `setConfig()` when changed. Native caches the values and uses them on every render frame with zero bridge cost.

---

## 11. Auto-Scroll Behavior

**Decision: Native tracks `isAtLatest` flag**

When the viewport's right edge is at the latest candle, `isAtLatest = true`. When `appendCandle()` arrives and `isAtLatest`, viewport shifts right automatically. When the user pans left, `isAtLatest` becomes `false` and auto-scroll stops. The user can call `controller.scrollToEnd()` to re-enable it.

---

## 12. Y-Axis Scaling

**Decision: Auto-fit to visible range with configurable padding**

On every viewport change, native scans visible candles for min low / max high, adds configurable padding (default 10%), and sets the y-axis range. This is recalculated on pan, zoom, and data updates. Manual y-axis control is a V2 feature.

---

## Decision Summary Table

| Decision | Choice | Confidence | Upgrade Path |
|----------|--------|------------|--------------|
| Embedding | Texture widget | High | Stable — no upgrade needed |
| Bridge | Pigeon | High | Add binary channel for bulk data in V2 |
| Android rendering | android.graphics.Canvas | High | OpenGL ES if profiling demands |
| iOS rendering | CoreGraphics | High | Metal if profiling demands |
| Gesture ownership | Flutter | High | Stable — no upgrade needed |
| Viewport ownership | Native | High | Stable |
| Data store | Native | High | Stable |
| Frame scheduling | Dirty flag + vsync | High | Stable |
| Bulk serialization | Pigeon StandardCodec | Medium | Binary channel for 100K+ datasets |
| Chart type switch | Renderer swap | High | Stable |
