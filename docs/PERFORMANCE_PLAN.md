# Performance Plan — trade_chart SDK V1

Target: 60 fps during pan, zoom, and crosshair on mid-range devices (2020+ Android, iPhone 11+) with up to 50K loaded candles.

---

## 1. Minimize Bridge Calls

### Problem
Every Flutter → Native call crosses the platform channel with serialization overhead (~0.05–0.2ms per call depending on payload size). During fast gestures, excessive calls eat into the 16ms frame budget.

### Strategy

| Technique | Detail |
|-----------|--------|
| **Coalesce gesture events** | `ChartGestureHandler` throttles `onPanUpdate` to at most one call per frame (~60/sec). Flutter's gesture system fires drag events faster than vsync; we accumulate deltas and send one batched delta per frame using `SchedulerBinding.addPostFrameCallback`. |
| **No per-frame bridge reads** | Native owns all rendering state. Flutter never reads viewport or candle data per frame. Viewport snapshots are pushed from native only after actual changes, not on a timer. |
| **Batch marker updates** | `setMarkers(list)` sends all markers in one call instead of N individual calls. |
| **One-shot config/theme** | Theme and config are sent once at init and only again on explicit change. Native caches them as pre-allocated `Paint`/`CGColor` objects. |

### Budget Allocation
- Gesture bridge call: ~0.1ms (within 16ms budget, leaves 15.9ms for rendering)
- Bulk candle load (5K candles): ~2ms serialization, ~1ms deserialization. Happens once, not per-frame.

---

## 2. Batching Updates

### Problem
Realtime feeds can deliver 5–20 ticks per second. Each tick calls `updateLastCandle()`. Without batching, this triggers 5–20 bridge calls and potentially 5–20 renders per second.

### Strategy

**Native-side dirty coalescing:**
- `updateLastCandle()` writes to `CandleStore` and calls `markDirty()`.
- `markDirty()` sets a boolean flag. If already dirty, it's a no-op (no duplicate frame request).
- Rendering only happens on vsync. Multiple ticks between two vsyncs result in one render with the latest data.

**Result:** Even at 20 ticks/sec, we render at most 60 frames/sec (vsync-limited), and each frame uses the most recent data. No wasted renders.

**Bridge call coalescing (if needed in V2):**
If profiling shows the bridge calls themselves are costly, batch `updateLastCandle` on the Dart side with a 16ms timer. But for V1, individual calls are cheap enough (~0.1ms each) that 20/sec is only 2ms total bridge overhead.

---

## 3. Visible-Range-Only Rendering

### Problem
With 50K loaded candles, iterating and drawing all of them every frame is wasteful and slow.

### Strategy

**ViewportCalculator maintains:**
- `visibleStartIndex`: first candle index that falls within the viewport
- `visibleEndIndex`: last candle index within the viewport
- `bufferSize`: extra candles on each side for smooth pan overscroll (default: `visibleCount * 0.5`)

**Renderer loop:**
```
renderStartIndex = max(0, visibleStartIndex - bufferSize)
renderEndIndex = min(candleCount - 1, visibleEndIndex + bufferSize)

for i in renderStartIndex..renderEndIndex:
    draw candle[i]
```

**Impact:** For a typical view of 80 candles with 40-candle buffer on each side, we draw ~160 candles regardless of whether 5K or 50K are loaded. Drawing 160 candles at ~0.01ms each = ~1.6ms.

**Binary search for visible range:**
`CandleStore` timestamps are sorted. `ViewportCalculator` uses binary search to find the first/last visible candle index when the viewport changes. O(log n) for 50K candles = ~16 comparisons.

---

## 4. Redraw Strategy

### Problem
Rendering is expensive. Drawing background, grid, candles, volume, markers, axes, and crosshair from scratch every frame wastes time when only part of the scene changed.

### V1 Strategy: Full redraw on dirty

For V1, we do a full redraw of all layers when dirty. Rationale:
- A full chart render with 160 visible candles takes ~3–5ms on a mid-range device
- This is well within the 16ms budget
- Layer-level caching adds complexity without meaningful gain at V1 scale

The dirty flag ensures we never render when nothing changed.

### V2 Strategy: Layer caching (if needed)

If profiling shows frame drops:
1. Separate layers into stable (background, grid, axes) and dynamic (candles, crosshair)
2. Cache stable layers as bitmaps
3. Only redraw dynamic layers per frame
4. Invalidate stable layer cache on viewport change or theme change

---

## 5. Text and Layout Caching

### Problem
Drawing text (axis labels, crosshair values) is expensive relative to drawing shapes. Measuring and laying out text strings on every frame is wasteful.

### Strategy

**Pre-allocated text objects:**
- **Android**: `NativeChartTheme` pre-creates `TextPaint` objects with configured size, color, typeface. Reused on every frame — zero allocation.
- **iOS**: `NativeChartTheme` pre-creates `CTFont`, `CFAttributedString` templates. Reused per frame.

**Axis label caching:**
- Price axis labels change only on y-axis range change (not every frame during horizontal pan).
- Time axis labels change only when the visible time range shifts enough to show new labels.
- `AxisRenderer` caches computed label strings and positions. Invalidated when viewport or y-range changes.

**Number formatting:**
- Pre-build price formatters (e.g., 2 decimal places for BTC, 4 for forex).
- `AxisRenderer` holds a formatter reference. Formatting a double to string is cached for the current visible price range.

**Estimated savings:** Text drawing can consume 30–40% of frame time without caching. With pre-allocated objects and label caching, text overhead drops to <10%.

---

## 6. Memory Handling for Large Datasets

### Problem
50K candles at 48 bytes each = 2.4MB. Acceptable. But 500K candles = 24MB, which pressures mobile memory.

### V1 Strategy: Bounded dataset with consumer responsibility

- **V1 cap:** SDK does not impose a hard limit but documents that optimal performance is for datasets up to 50K candles.
- **Consumer responsibility:** The consumer should load reasonable windows of data. For 1-minute candles going back months, load the most recent N candles and fetch more on demand.
- **CandleStore capacity:** Pre-allocates arrays with initial capacity (default 10K). Grows by doubling when exceeded. Avoids frequent reallocations.

### V2 Strategy: Windowed / virtualized data

For V3/V4, support on-demand data loading:
- SDK requests more data via callback when user pans near the edge
- Consumer provides a `CandleDataProvider` interface
- CandleStore manages a sliding window

### Memory allocation discipline

| Resource | Allocation | Lifetime |
|----------|-----------|----------|
| CandleStore arrays | Once at `loadCandles`, grow on `append` | Until `dispose` or next `loadCandles` |
| MarkerStore list | Once at `setMarkers` | Until `clearMarkers` or `dispose` |
| Paint/Color objects | Once at init, updated on theme change | Until `dispose` |
| Surface/PixelBuffer | Once at init, recreated on resize | Until `dispose` |
| ChartFrame | Stack-allocated per render | Single frame |
| Formatted strings | Cached, invalidated on viewport change | Per viewport |

**Zero-allocation render loop goal:** After initial setup, the render loop should allocate no heap objects. All objects are pre-allocated and reused. This prevents GC pauses during animation.

---

## 7. Responsiveness During Interaction

### Problem
Pan, zoom, and crosshair must feel instant. Any perceptible lag (>16ms input-to-visual delay) breaks the trading app experience.

### Strategy

**Gesture-to-pixel pipeline latency budget:**

```
Touch event → Flutter framework:    ~2ms
GestureDetector processing:          ~0.5ms
Bridge call (serialize + deliver):   ~0.2ms
Native viewport calculation:         ~0.1ms
Wait for next vsync:                 0–16ms (average 8ms)
Render frame:                        ~3–5ms
Texture available to Flutter:        ~0.5ms
Flutter composite + display:         ~1ms
─────────────────────────────────────────
Total: ~7–25ms (1–1.5 frames)
```

This is acceptable. 1-frame latency is imperceptible for chart panning.

**Fling smoothness:**
- Native-side fling animation uses `Choreographer`/`CADisplayLink` — frame-synchronized, no bridge round-trip per frame.
- Fling is fully native: set initial velocity, decelerate, apply viewport delta, render.
- Flutter is only notified of viewport changes (for consumer callbacks), not involved in the animation loop.

**Crosshair responsiveness:**
- Long-press detection inherently adds ~200ms delay (Flutter's `kLongPressTimeout`).
- After activation, crosshair moves track the finger at gesture event rate (~60 updates/sec).
- Snap-to-candle logic ensures crosshair doesn't jitter between candles.

**Zoom smoothness:**
- Scale factor is relative to gesture start (not per-frame deltas), preventing cumulative floating-point drift.
- Zoom center follows the pinch focal point, so content under the fingers stays stable.

---

## 8. 60fps Goals and Tradeoffs

### What we target at 60fps

| Interaction | Target | Budget |
|-------------|--------|--------|
| Pan scroll | 60 fps sustained | 16ms per frame (render ≤5ms) |
| Pinch zoom | 60 fps sustained | 16ms per frame (render ≤5ms) |
| Crosshair drag | 60 fps sustained | 16ms per frame (render ≤5ms) |
| Realtime tick updates (idle) | Render only when data changes | 0 fps when idle |
| Initial load (5K candles) | <100ms total | One-shot cost |
| Timeframe switch | <200ms (load + first render) | Includes bridge + store + render |

### Acceptable tradeoffs

| Tradeoff | Justification |
|----------|---------------|
| Full redraw vs layer caching | Simpler code, V1 render times are within budget |
| Single-threaded rendering | Avoids thread synchronization complexity; rendering is fast enough on main thread for V1 |
| Pigeon over FFI | Type safety and developer velocity matter more than the ~0.1ms per call we'd save with FFI |
| CPU rendering (Canvas/CoreGraphics) over GPU (OpenGL/Metal) | 2D charts don't need GPU shaders; CPU rendering is fast, simpler, and more portable |
| Float64 (double) throughout | No need for float32 optimization at V1 scale; doubles avoid precision issues with large BTC prices |

### When to escalate to V2 optimizations

| Signal | V2 Action |
|--------|-----------|
| Render time >8ms on target devices | Introduce layer caching (stable vs dynamic layers) |
| Bridge overhead >2ms during gestures | Switch gesture events to binary BasicMessageChannel |
| Frame drops during fling on low-end devices | Move rendering to background thread |
| Memory >50MB for loaded data | Implement windowed/virtualized CandleStore |
| Text rendering >2ms per frame | Implement glyph atlas / pre-rendered label textures |

---

## 9. Profiling Plan

### Key metrics to capture during development

| Metric | How to Measure | Target |
|--------|---------------|--------|
| Frame render time | Native: `System.nanoTime()` around render loop / `CACurrentMediaTime()` | <5ms |
| Bridge call latency | Dart: `Stopwatch` around Pigeon call | <0.3ms |
| Candle load time | Dart: `Stopwatch` around `loadCandles` end-to-end | <100ms for 5K |
| Memory (native heap) | Android Studio Memory Profiler / Xcode Instruments | <30MB for 50K candles |
| Frame drops | Flutter DevTools Performance / Android GPU profiler | 0 during pan/zoom |
| GC pauses during animation | Android Studio / Xcode | None |

### Profiling checkpoints
1. After Phase 2 (static rendering): measure render time for 5K candles
2. After Phase 3 (gestures): measure pan/zoom fps, bridge call rate
3. After Phase 4 (crosshair + realtime): measure full interaction loop
4. After Phase 5 (polish): final profiling pass on target devices
