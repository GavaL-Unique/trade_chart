# Engineering Risks — trade_chart SDK V1

Each risk includes likelihood, impact, detection strategy, and mitigation plan.

---

## R1. Texture Registration Platform Differences

**Category:** Flutter/Native Integration
**Likelihood:** Medium
**Impact:** High (blocks all rendering)

**Description:**
`SurfaceTexture` (Android) and `CVPixelBuffer` (iOS) registration with Flutter's `TextureRegistry` has subtle platform-specific behavior. The `Texture` widget may not display correctly if:
- Pixel buffer format is wrong (BGRA vs RGBA)
- Texture size doesn't account for device pixel ratio
- Texture update signaling is not called at the right time
- Surface is accessed from wrong thread

**Detection:**
Phase 1 milestone — if the solid-color rectangle doesn't appear, this risk has materialized.

**Mitigation:**
- Start Phase 1 with the simplest possible texture (solid color fill) to isolate registration issues from rendering complexity.
- Reference Flutter's `video_player` and `camera` plugin source code — they use the same `TextureRegistry` API.
- Android: Use `RGBA_8888` format for `SurfaceTexture`. Call `surfaceTexture.updateTexImage()` is NOT needed for Flutter's texture registry — Flutter reads from the `SurfaceTexture` directly. Signal via `textureEntry.surfaceTexture()`.
- iOS: Use `kCVPixelFormatType_32BGRA` for `CVPixelBuffer`. Call `textureRegistry.textureFrameAvailable(textureId)` after each render.
- Test on both emulator and physical device early — emulators sometimes have GPU-related texture quirks.

---

## R2. Gesture Conflicts with Parent Widgets

**Category:** Gesture Architecture
**Likelihood:** Medium
**Impact:** Medium

**Description:**
When `TradeChart` is placed inside a `PageView`, `TabBarView`, `ListView`, or `DraggableScrollableSheet`, horizontal pan gestures can conflict. The parent widget may steal the gesture from the chart, or the chart may prevent the parent from scrolling.

**Detection:**
Place chart inside a `PageView` in the example app and test swiping.

**Mitigation:**
- Implement `ChartGestureHandler` as a `RawGestureRecognizer` registered in Flutter's gesture arena, giving the chart priority for horizontal drags when the gesture starts clearly horizontal.
- Expose a `gestureConfig` parameter on `TradeChart` that allows the consumer to configure:
  - `consumeHorizontalDrag: true` (default) — chart wins horizontal drags
  - `consumeHorizontalDrag: false` — parent wins horizontal drags (chart only handles vertical/pinch)
- For `PageView` scenarios: detect horizontal drag angle. If >30° from horizontal, yield to parent. If ≤30°, claim the gesture.
- Document known gesture conflict scenarios and recommended solutions in README.

---

## R3. PlatformView Fallback Pressure

**Category:** Flutter/Native Integration
**Likelihood:** Low
**Impact:** High (architecture pivot)

**Description:**
If the Texture approach has unforeseen limitations (e.g., texture update latency, pixel format issues on specific Android manufacturers), there may be pressure to fall back to PlatformView. This would require significant re-architecture of gesture handling and overlay strategy.

**Detection:**
Performance profiling in Phase 3. If texture update latency exceeds 5ms, investigate.

**Mitigation:**
- The Texture approach is proven in production by Flutter's `video_player`, `camera`, `google_maps_flutter` (texture variant), and `webview_flutter`. It's not experimental.
- If specific devices show issues, investigate manufacturer-specific `SurfaceTexture` bugs before pivoting architecture.
- The rendering code (renderers, data stores, viewport calculator) is independent of the embedding strategy. Only `TextureRenderer` and the plugin entry point would change in a PlatformView pivot.

---

## R4. State Synchronization Between Flutter and Native

**Category:** State Management
**Likelihood:** Medium
**Impact:** Medium

**Description:**
Native owns viewport, data, and render state. Flutter owns widget state, theme, and config. If these get out of sync (e.g., Flutter thinks crosshair is active but native has already ended it), the UI becomes inconsistent.

**Detection:**
Stress testing: rapid gesture changes, fast theme toggles, quick widget rebuilds.

**Mitigation:**
- **Single direction of truth:** Flutter sends commands to native. Native sends events to Flutter. Neither side assumes the other's state.
- **Command-event pattern:** Flutter commands are fire-and-forget (no return values except init). State changes are confirmed via events (`onViewportChanged`, `onCrosshairData`).
- **Lifecycle binding:** When the Flutter widget disposes, ALL native state is destroyed. Reattaching creates fresh state.
- **Debounced size changes:** Widget rebuilds during animations send intermediate sizes. Debounce `onSizeChanged` with a 100ms timer to avoid rapid texture recreation.
- **Guard against stale callbacks:** `ChartFlutterApiHolder` checks if the engine is still alive before invoking Flutter callbacks. Prevents callbacks after dispose.

---

## R5. Memory Leaks from Improper Disposal

**Category:** Resource Management
**Likelihood:** Medium
**Impact:** High (crashes in long-running apps)

**Description:**
Native resources (`SurfaceTexture`, `Surface`, `CVPixelBuffer`, `Choreographer` callbacks, `CADisplayLink`) must be explicitly released. If the Flutter widget is disposed without proper cleanup, native resources leak. In a navigator-heavy app, this accumulates.

**Detection:**
- Android: LeakCanary, Android Studio Memory Profiler
- iOS: Xcode Instruments (Leaks + Allocations)
- Test: push chart screen, pop, repeat 20x, check memory.

**Mitigation:**
- `_TradeChartState.dispose()` calls `ChartHostApi.dispose()` synchronously.
- Native `dispose()` implementation follows a strict checklist:
  1. Cancel pending `Choreographer`/`CADisplayLink` callback
  2. Cancel fling animation
  3. Release `Surface` / `CVPixelBuffer`
  4. Unregister `SurfaceTexture` / texture entry from Flutter's registry
  5. Clear `CandleStore` and `MarkerStore`
  6. Null out `ChartFlutterApi` reference
- `ChartEngine` sets an `isDisposed` flag. All public methods check this flag and no-op if disposed.
- Double-dispose is safe (guarded by flag).

---

## R6. Thread Safety on Android

**Category:** Concurrency
**Likelihood:** Low (V1), Medium (V2 with background rendering)
**Impact:** High (crashes, corruption)

**Description:**
Pigeon callbacks arrive on the main thread. `Choreographer` callbacks run on the main thread. So V1 is single-threaded. However:
- `SurfaceTexture` has its own internal thread for buffer management.
- If we later move rendering to a background thread, `CandleStore` access becomes a race condition.

**Detection:**
StrictMode, Thread checker, crash reports.

**Mitigation:**
- V1: Keep everything on main thread. No threading issues possible.
- V1: Do NOT use `Handler.post()` or `Coroutines` for rendering. Use `Choreographer.postFrameCallback` which runs on main thread.
- V2 threading plan (documented now for future reference):
  - Rendering thread owns the `Canvas` and `Surface`
  - Main thread owns `CandleStore` and `ViewportCalculator`
  - Copy viewport snapshot + visible candle range to rendering thread per frame
  - No shared mutable state between threads

---

## R7. Testing and Debugging Difficulty

**Category:** Developer Experience
**Likelihood:** High
**Impact:** Medium (slows development)

**Description:**
Native rendering code cannot be tested with Flutter's widget test framework. Visual correctness must be verified manually or with screenshot tests. Bridge issues are hard to debug because errors can occur in serialization, native code, or callback delivery.

**Detection:**
Observed during development.

**Mitigation:**
- **Unit test native code independently:** Android: JUnit tests for `CandleStore`, `ViewportCalculator`, `BridgeMapper`. iOS: XCTest for same. These classes have no rendering dependencies.
- **Renderer tests with Canvas mocking:** Create mock `Canvas` that records draw calls. Verify `CandleRenderer` calls `drawRect` with correct coordinates. Same pattern in Swift with `CGContext` recording.
- **Integration tests:** Flutter integration tests that load candles and verify the texture widget exists and has non-zero size. Can't verify pixel content easily, but can verify lifecycle.
- **Screenshot comparison (V2):** Capture rendered texture as bitmap, compare against golden images.
- **Logging:** Add structured logging in native engine (guarded by debug flag). Log: frame render time, visible range, dirty flag state, bridge calls received.
- **Error propagation:** All native exceptions caught and forwarded via `ChartFlutterApi.onError()`. No silent failures.

---

## R8. Pigeon Version Compatibility

**Category:** Build / Tooling
**Likelihood:** Low
**Impact:** Medium

**Description:**
Pigeon is actively developed. Major version bumps can change generated code signatures, breaking native implementations. If the consumer's project pins a different Pigeon version, conflicts arise.

**Mitigation:**
- Pigeon is a `dev_dependency`, not a runtime dependency. It's only used at code generation time. Consumers never interact with it.
- Pin Pigeon version in `pubspec.yaml` to a specific minor range: `pigeon: ^22.0.0`.
- Commit generated code to version control. Consumers don't need to run Pigeon.
- On Pigeon upgrades: re-generate, update native implementations, test.

---

## R9. Large Dataset Bridge Transfer

**Category:** Performance
**Likelihood:** Low (for V1 target of 50K candles)
**Impact:** Medium

**Description:**
Loading 50K candles through Pigeon's `StandardMessageCodec` transfers ~2.4MB of data. Serialization and deserialization may take >100ms, causing a visible pause.

**Detection:**
Profiling `loadCandles()` with 50K candles.

**Mitigation:**
- V1: For 5K–10K candles (typical initial load), transfer time is <50ms. Acceptable.
- V1: `loadCandles()` is `async` — it doesn't block the UI thread. The chart briefly shows an empty state until data loads.
- V2 upgrade path: Switch to `BasicMessageChannel<ByteData>` for bulk loads. Encode candles as flat binary (48 bytes each). 50K candles = 2.4MB binary, which transfers in ~20ms with binary codec.
- V3: Implement paginated loading — load visible range + buffer, fetch more on demand.

---

## R10. Consumer Misuse / API Ergonomics

**Category:** SDK Design
**Likelihood:** High
**Impact:** Low-Medium (bad UX, not crashes)

**Description:**
Consumers may:
- Call `updateLastCandle` before `loadCandles`
- Pass candles with out-of-order timestamps
- Forget to call `dispose()`
- Create multiple controllers and attach to one widget
- Call methods after dispose

**Mitigation:**
- **Defensive checks in controller:** Every public method checks `isAttached` and `!isDisposed`. Throws `StateError` with descriptive message if violated.
- **Data validation in native:** `CandleStore.load()` verifies timestamps are sorted. `append()` verifies new timestamp > last timestamp. `updateLast()` verifies timestamp matches.
- **Clear error messages:** Pigeon error callbacks include human-readable messages explaining what went wrong and how to fix it.
- **Documentation:** README includes "Common Mistakes" section.
- **Example app:** Demonstrates the correct lifecycle and data loading pattern.

---

## Risk Summary Matrix

| ID | Risk | Likelihood | Impact | Phase Affected | Mitigation Quality |
|----|------|-----------|--------|----------------|-------------------|
| R1 | Texture registration | Medium | High | 1 | Strong (proven API, reference code) |
| R2 | Gesture conflicts | Medium | Medium | 3 | Good (configurable, documented) |
| R3 | PlatformView fallback | Low | High | 1 | Moderate (architecture is modular) |
| R4 | State synchronization | Medium | Medium | 3–4 | Good (command-event pattern) |
| R5 | Memory leaks | Medium | High | 5 | Strong (strict dispose checklist) |
| R6 | Thread safety | Low | High | V2 | Good (single-threaded V1) |
| R7 | Testing difficulty | High | Medium | All | Moderate (unit tests + integration) |
| R8 | Pigeon compatibility | Low | Medium | Build | Strong (pinned, generated committed) |
| R9 | Large dataset transfer | Low | Medium | 2 | Good (binary upgrade path) |
| R10 | Consumer misuse | High | Low | 5 | Good (defensive checks, docs) |
