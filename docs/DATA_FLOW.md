# Data Flow — trade_chart SDK V1

This document traces every data path through the system with exact class names and method calls. Use this as the implementation reference for how data enters, transforms, and renders.

---

## Flow 1: Initial Historical Load

**Trigger:** Consumer calls `controller.loadCandles(candles, timeframe)`

```
Consumer App
  │
  ▼
TradeChartController.loadCandles(List<CandleData>, ChartTimeframe)
  │
  │  Converts to bridge types:
  │  BridgeMapper.candlesToMessage(candles, timeframe)
  │    → CandleDataListMessage { candles: List<CandleDataMessage>, timeframe: "h1" }
  │
  ▼
ChartBridge.loadCandles(CandleDataListMessage)
  │
  │  Pigeon serialization (StandardMessageCodec)
  │  ~1ms for 5K candles
  │
  ▼
─── Platform Channel ───────────────────────────────────
  │
  ▼
ChartHostApiImpl.loadCandles(CandleDataListMessage)       [Android/iOS]
  │
  │  Deserializes into native candle array:
  │
  ▼
CandleStore.load(candles: Array<NativeCandle>)
  │  - Clears existing data
  │  - Stores as contiguous array (struct-of-arrays for perf):
  │      timestamps: LongArray
  │      opens: DoubleArray
  │      highs: DoubleArray
  │      lows: DoubleArray
  │      closes: DoubleArray
  │      volumes: DoubleArray
  │  - Records candle count
  │
  ▼
ViewportCalculator.resetToLatest(candleCount, chartWidth, config)
  │  - Computes initial visible range: last N candles that fit at default zoom
  │  - Calculates y-axis range from visible candles + padding
  │  - Sets isAtLatest = true
  │
  ▼
ChartEngine.markDirty()
  │  - Sets needsRedraw = true
  │  - Requests next vsync callback
  │
  ▼
[Next Vsync]
ChartEngine.onFrame()
  │  - Creates ChartFrame(canvas, viewport, theme, config)
  │  - Calls each renderer in order:
  │    1. BackgroundRenderer.render(frame)
  │    2. GridRenderer.render(frame)
  │    3. VolumeRenderer.render(frame)     ← reads CandleStore visible range
  │    4. CandleRenderer.render(frame)     ← reads CandleStore visible range
  │    5. MarkerRenderer.render(frame)     ← reads MarkerStore visible range
  │    6. AxisRenderer.render(frame)       ← reads viewport price/time range
  │    7. CrosshairRenderer.render(frame)  ← skipped (crosshair not active)
  │  - Signals texture available
  │  - Clears dirty flag
  │
  ▼
ChartFlutterApiHolder.onChartReady()          [first load only]
ChartFlutterApiHolder.onViewportChanged(ViewportStateMessage)
  │
  │  Pigeon deserialization
  │
  ▼
─── Platform Channel ───────────────────────────────────
  │
  ▼
ChartBridge._onViewportChanged(ViewportStateMessage)
  │  BridgeMapper.viewportFromMessage(msg) → ViewportState
  │
  ▼
TradeChartController._viewportStreamController.add(ViewportChangeEvent)
  │
  ▼
Consumer receives via stream or widget callback
```

---

## Flow 2: Append New Candle (New Period)

**Trigger:** Consumer calls `controller.appendCandle(candle)` when a new period starts.

```
TradeChartController.appendCandle(CandleData)
  │
  ▼
ChartBridge → ChartHostApi.appendCandle(CandleDataMessage)
  │
  ▼
ChartHostApiImpl.appendCandle(msg)                        [Native]
  │
  ▼
CandleStore.append(candle)
  │  - Appends to end of arrays
  │  - Increments count
  │
  ▼
ViewportCalculator.onCandleAppended(isAtLatest)
  │  - If isAtLatest && config.autoScrollOnAppend:
  │      Shift viewport right by 1 candle
  │      Recalculate y-axis for new visible range
  │  - Else: no viewport change (user has scrolled back)
  │
  ▼
ChartEngine.markDirty()
  │  → renders on next vsync
  │  → sends onViewportChanged if viewport shifted
```

---

## Flow 3: Update In-Progress Candle (Realtime Tick)

**Trigger:** Consumer calls `controller.updateLastCandle(candle)` on each price tick.

```
TradeChartController.updateLastCandle(CandleData)
  │
  ▼
ChartBridge → ChartHostApi.updateLastCandle(CandleDataMessage)
  │
  ▼
ChartHostApiImpl.updateLastCandle(msg)                    [Native]
  │
  ▼
CandleStore.updateLast(candle)
  │  - Overwrites last index in each array
  │  - NO allocation, NO array resize
  │
  ▼
ViewportCalculator.onLastCandleUpdated()
  │  - If last candle is visible:
  │      Recalculate y-axis (new high/low might exceed current range)
  │  - Else: no-op
  │
  ▼
ChartEngine.markDirty()
  │  → renders on next vsync (coalesces rapid ticks into 1 frame)
```

**Key performance property:** If 10 ticks arrive within one 16ms frame, `markDirty()` is called 10 times but the engine only renders once on the next vsync. The last tick's data is what gets rendered. This is correct because each `updateLastCandle` overwrites the same array slot.

---

## Flow 4: Timeframe Switch

**Trigger:** Consumer calls `controller.setTimeframe(tf)` then `controller.loadCandles(newCandles, tf)`.

```
TradeChartController.setTimeframe(ChartTimeframe)
  │
  ▼
ChartBridge → ChartHostApi.setTimeframe("h4")
  │
  ▼
ChartHostApiImpl.setTimeframe(tf)                         [Native]
  │
  ▼
CandleStore.clear()
  │  - Zeros out arrays, resets count
  │  - This prevents rendering stale data during the brief gap
  │
  ▼
ChartEngine.markDirty()  → renders blank frame (just background + grid)

// Then immediately:

TradeChartController.loadCandles(candles, tf)
  │  → same as Flow 1 from here
```

The consumer is responsible for fetching data for the new timeframe. The SDK does not make network requests.

---

## Flow 5: Viewport Change (Pan)

**Trigger:** User drags horizontally on the chart.

```
Flutter GestureDetector.onScaleUpdate (pointerCount == 1)
  │
  ▼
ChartGestureHandler.handlePanUpdate(focalPointDelta.dx)
  │  - Checks mode != zooming && mode != crosshair
  │  - Sets mode = panning
  │  - Extracts deltaX from focalPointDelta
  │
  ▼
ChartBridge → ChartHostApi.onPanUpdate(deltaX: -12.5)
  │
  ▼
ChartHostApiImpl.onPanUpdate(deltaX)                      [Native]
  │
  ▼
ViewportCalculator.applyPanDelta(deltaX)
  │  - Converts pixel delta to candle offset:
  │      candleShift = deltaX / (candleWidth + candleSpacing)
  │  - Shifts visible range start/end indices
  │  - Clamps to [0, candleCount - minVisibleCandles]
  │  - Recalculates y-axis for new visible range
  │  - Updates isAtLatest based on whether right edge is at last candle
  │
  ▼
ChartEngine.markDirty()
  │
  ▼
[Next Vsync] → render → texture update
  │
  ▼
ChartFlutterApiHolder.onViewportChanged(...)
  │  → flows back to Flutter controller → consumer
```

**Pan end with fling:**

```
Flutter GestureDetector.onScaleEnd (mode was panning)
  │
  ▼
ChartGestureHandler.handlePanEnd(velocity.pixelsPerSecond.dx)
  │  - Flushes any pending coalesced pan delta
  │  - Transitions mode: panning → idle
  │  - Sends velocity to native for fling
  │
  ▼
ChartBridge → ChartHostApi.onPanEnd(velocityX: -1500.0)
  │
  ▼
ViewportCalculator.startFling(velocityX)                  [Native]
  │  - Creates a deceleration animation (friction-based)
  │  - On each animation tick: applyPanDelta(frameDelta)
  │  - Animation runs until velocity < threshold
  │  - Each tick: markDirty() → renders on vsync
```

---

## Flow 6: Viewport Change (Pinch Zoom)

**Trigger:** User pinches on the chart.

```
Flutter GestureDetector.onScaleUpdate
  │
  ▼
ChartGestureHandler.onScaleUpdate(ScaleUpdateDetails)
  │  - Checks state == idle || state == zooming
  │  - Computes scaleFactor relative to gesture start
  │  - Computes focalPointX (center of pinch relative to chart left)
  │
  ▼
ChartBridge → ChartHostApi.onScaleUpdate(scaleFactor: 1.3, focalPointX: 150.0)
  │
  ▼
ViewportCalculator.applyScale(scaleFactor, focalPointX)   [Native]
  │  - Adjusts candleWidth: newWidth = baseCandleWidth * scaleFactor
  │  - Clamps to [minWidth, maxWidth] based on min/maxVisibleCandles
  │  - Recomputes visible range centered around focalPointX
  │  - Recalculates y-axis
  │
  ▼
ChartEngine.markDirty() → render on vsync
```

---

## Flow 7: Crosshair Move

**Trigger:** User long-presses and drags on the chart.

```
Flutter GestureDetector.onLongPressStart
  │
  ▼
ChartGestureHandler.onCrosshairStart(LongPressStartDetails)
  │  - Transitions state: idle → crosshair
  │  - Extracts (x, y) relative to chart
  │
  ▼
ChartBridge → ChartHostApi.onCrosshairStart(x, y)
  │
  ▼
ChartEngine.setCrosshairActive(true)                      [Native]
ViewportCalculator.resolveCrosshair(x, y)
  │  - Finds nearest candle to x coordinate:
  │      candleIndex = visibleStartIndex + floor(x / (candleWidth + spacing))
  │  - Snaps x to candle center
  │  - Reads OHLCV from CandleStore[candleIndex]
  │  - Converts y to price value
  │
  ▼
ChartEngine.markDirty()  → renders with crosshair overlay
  │
  ▼
ChartFlutterApiHolder.onCrosshairData(CrosshairDataMessage)
  │  timestamp, O, H, L, C, V, snappedX, y
  │
  ▼
─── Platform Channel ───────────────────────────────────
  │
  ▼
TradeChartController._crosshairStreamController.add(CrosshairEvent)
  │
  ▼
Consumer widget callback / stream listener
```

**Crosshair move (drag while long-pressing):**

```
Flutter GestureDetector.onLongPressMoveUpdate
  │
  ▼
ChartGestureHandler.onCrosshairMove(LongPressMoveUpdateDetails)
  │  → ChartHostApi.onCrosshairMove(x, y)
  │  → same native resolution + render + callback
```

**Crosshair end:**

```
Flutter GestureDetector.onLongPressEnd
  │
  ▼
ChartGestureHandler.onCrosshairEnd()
  │  - Transitions state: crosshair → idle
  │  → ChartHostApi.onCrosshairEnd()
  │  → ChartEngine.setCrosshairActive(false) → markDirty() → renders without crosshair
```

---

## Flow 8: Marker Updates

**Trigger:** Consumer calls `controller.setMarkers(markers)`.

```
TradeChartController.setMarkers(List<ChartMarker>)
  │
  ▼
ChartBridge → ChartHostApi.setMarkers(MarkerListMessage)
  │
  ▼
MarkerStore.setAll(markers)                               [Native]
  │  - Replaces marker list
  │  - Sorts by timestamp for efficient visible-range query
  │
  ▼
ChartEngine.markDirty() → renders with markers
```

---

## Flow 9: Size Change

**Trigger:** Widget is resized (orientation change, layout shift).

```
_TradeChartState.build() → LayoutBuilder reports new size
  │
  ▼
_TradeChartState._onSizeChanged(width, height)
  │  - Debounced: ignores rapid intermediate sizes during animation
  │  - Sends final size after 100ms settle
  │
  ▼
ChartBridge → ChartHostApi.onSizeChanged(width, height)
  │
  ▼
TextureRenderer.resize(width, height, pixelRatio)         [Native]
  │  - Releases old surface
  │  - Allocates new surface at new dimensions × pixelRatio
  │
  ▼
ViewportCalculator.onSizeChanged(width, height)
  │  - Recalculates visible candle count at current zoom
  │  - Recalculates y-axis
  │
  ▼
ChartEngine.markDirty() → renders at new size
```

---

## Flow 10: Theme / Config Change

**Trigger:** Consumer rebuilds `TradeChart` with new theme or config.

```
TradeChart widget rebuild with new TradeChartTheme
  │
  ▼
_TradeChartState.didUpdateWidget()
  │  - Compares old vs new theme/config
  │  - Only sends if changed
  │
  ▼
ChartBridge → ChartHostApi.setTheme(ThemeMessage)
  │
  ▼
NativeChartTheme.update(theme)                            [Native]
  │  - Updates cached Paint objects / CGColor objects
  │
  ▼
ChartEngine.markDirty() → renders with new theme
```

---

## Data Lifetime

```
                    ┌────────────────────────────────────────┐
                    │          Flutter (Dart)                 │
                    │                                        │
                    │  CandleData objects are transient —    │
                    │  passed to controller, serialized      │
                    │  to bridge, then eligible for GC.      │
                    │  Flutter does NOT hold a copy of the   │
                    │  full candle dataset.                   │
                    │                                        │
                    │  ViewportState / CrosshairEvent are    │
                    │  lightweight snapshots.                 │
                    └───────────────┬────────────────────────┘
                                    │
                              Pigeon bridge
                                    │
                    ┌───────────────▼────────────────────────┐
                    │          Native (Kotlin / Swift)        │
                    │                                        │
                    │  CandleStore: owns full dataset         │
                    │    Lifetime: init → dispose             │
                    │    Memory: ~48 bytes × candle count     │
                    │                                        │
                    │  MarkerStore: owns current markers      │
                    │    Lifetime: set → clear / dispose      │
                    │                                        │
                    │  ViewportCalculator: computed state     │
                    │    No persistent memory allocation      │
                    │                                        │
                    │  NativeChartTheme: cached Paint/Color   │
                    │    Allocated once, updated on change    │
                    │                                        │
                    │  TextureRenderer: surface/buffer        │
                    │    Allocated on init, released on       │
                    │    dispose or resize                    │
                    └────────────────────────────────────────┘
```

---

## Concurrency Model

**Flutter side:** All controller methods run on the main isolate. Pigeon calls are async but execute on the platform thread. No Dart isolate parallelism is used.

**Native side (Android):** Pigeon calls arrive on the main (UI) thread. `ChartEngine` processes them on the main thread. Rendering happens on the main thread synchronized with `Choreographer`. For V1, this is acceptable because rendering is fast (<5ms per frame for typical chart complexity). V2 can move rendering to a background thread with a dedicated GL context if needed.

**Native side (iOS):** Same model. Pigeon on main thread, rendering on main thread via `CADisplayLink`. CoreGraphics drawing is fast enough for V1.

**Thread safety invariant:** `CandleStore`, `ViewportCalculator`, and `ChartEngine` are accessed only from the main thread. No locks needed in V1.
