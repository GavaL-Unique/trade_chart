import 'dart:async';

import 'package:flutter/material.dart';

import 'package:trade_chart/trade_chart.dart';

import '../data/fake_realtime_stream.dart';
import '../data/sample_candles.dart';

class ChartScreen extends StatefulWidget {
  const ChartScreen({super.key});

  @override
  State<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  final TradeChartController _controller = TradeChartController();
  final FakeRealtimeStream _fakeRealtimeStream = FakeRealtimeStream();

  final ChartType _chartType = ChartType.candle;
  ChartTimeframe _timeframe = ChartTimeframe.h1;
  ViewportState? _viewport;
  CrosshairEvent? _crosshair;
  List<CandleData> _candles = buildSampleCandles();
  bool _realtimeEnabled = false;
  StreamSubscription<FakeRealtimeEvent>? _realtimeSubscription;
  Future<void> _realtimeQueue = Future<void>.value();
  int _realtimeGeneration = 0;
  bool _chartReady = false;

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = const TradeChartTheme.dark();

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(title: const Text('trade_chart Bybit-style Example')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Switch(
                  value: _realtimeEnabled,
                  onChanged: (enabled) async {
                    setState(() {
                      _realtimeEnabled = enabled;
                    });
                    if (enabled) {
                      _startRealtime();
                    } else {
                      await _stopRealtime();
                    }
                  },
                ),
                const SizedBox(width: 8),
                const Text('Realtime updates'),
                const SizedBox(width: 12),
                Text(
                  _realtimeEnabled ? 'Streaming' : 'Paused',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => _controller.scrollToEnd(),
                  child: const Text('Scroll to latest'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _controller.enterFullscreen,
                  child: const Text('Fullscreen'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _viewport == null
                  ? 'Loading initial dataset...'
                  : 'Mode: ${_chartType.name}  Timeframe: ${_timeframe.name}  '
                        'Visible candles: ${_viewport!.visibleCandleCount}  Price range: '
                        '${_viewport!.priceLow.toStringAsFixed(2)} - ${_viewport!.priceHigh.toStringAsFixed(2)}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Text(
              _crosshair == null
                  ? 'Long press to inspect OHLCV. Drag to pan. Pinch to zoom. '
                        'Toggle realtime to stream native append/update events.'
                  : 'Last crosshair: O ${_crosshair!.open.toStringAsFixed(2)}  '
                        'H ${_crosshair!.high.toStringAsFixed(2)}  '
                        'L ${_crosshair!.low.toStringAsFixed(2)}  '
                        'C ${_crosshair!.close.toStringAsFixed(2)}  '
                        'V ${_crosshair!.volume.toStringAsFixed(0)}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Text(
              _viewport == null
                  ? 'Viewport status unavailable.'
                  : _viewport!.isAtLatest
                  ? 'Viewport is pinned to the latest candle.'
                  : 'Viewport is exploring historical data.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.white54),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white24),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: TradeChartWidget(
                        controller: _controller,
                        theme: theme,
                        config: TradeChartConfig(
                          showVolume: true,
                          initialChartType: _chartType,
                        ),
                        availableTimeframes: const [
                          ChartTimeframe.m1,
                          ChartTimeframe.m5,
                          ChartTimeframe.m15,
                          ChartTimeframe.h1,
                          ChartTimeframe.h4,
                          ChartTimeframe.d1,
                        ],
                        onTimeframeSelected: _handleTimeframeSelected,
                        onChartReady: () async {
                          _chartReady = true;
                          await _loadTimeframe(_timeframe);
                          if (_realtimeEnabled) {
                            _startRealtime();
                          }
                        },
                        onViewportChange: (event) {
                          setState(() {
                            _viewport = event.viewport;
                          });
                        },
                        onCrosshairUpdate: (event) {
                          setState(() {
                            _crosshair = event;
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleTimeframeSelected(ChartTimeframe timeframe) async {
    setState(() {
      _timeframe = timeframe;
    });
    if (!_chartReady) {
      return;
    }
    await _loadTimeframe(timeframe);
    if (_realtimeEnabled) {
      _startRealtime();
    }
  }

  Future<void> _loadTimeframe(ChartTimeframe timeframe) async {
    await _stopRealtime();
    final candles = buildSampleCandles(timeframe: timeframe);
    final markers = buildSampleMarkers(candles);
    _candles = List<CandleData>.of(candles);
    _crosshair = null;
    _viewport = null;

    await _controller.setTimeframe(timeframe);
    await _controller.loadCandles(_candles, timeframe);
    await _controller.setMarkers(markers);
    await _controller.setChartType(_chartType);
    if (mounted) {
      setState(() {});
    }
  }

  void _startRealtime() {
    _realtimeGeneration += 1;
    final generation = _realtimeGeneration;
    _realtimeSubscription?.cancel();
    if (_candles.isEmpty) {
      return;
    }
    _realtimeSubscription = _fakeRealtimeStream
        .stream(seedCandle: _candles.last, timeframe: _timeframe)
        .listen((event) {
          _realtimeQueue = _realtimeQueue.then(
            (_) => _applyRealtimeEvent(event, generation),
          );
        });
  }

  Future<void> _stopRealtime() async {
    _realtimeGeneration += 1;
    await _realtimeSubscription?.cancel();
    _realtimeSubscription = null;
  }

  Future<void> _applyRealtimeEvent(
    FakeRealtimeEvent event,
    int generation,
  ) async {
    if (!mounted || generation != _realtimeGeneration) {
      return;
    }

    switch (event.type) {
      case FakeRealtimeEventType.updateLast:
        if (_candles.isEmpty) {
          _candles = <CandleData>[event.candle];
        } else {
          _candles[_candles.length - 1] = event.candle;
        }
        await _controller.updateLastCandle(event.candle);
        break;
      case FakeRealtimeEventType.append:
        _candles = List<CandleData>.of(_candles)..add(event.candle);
        await _controller.appendCandle(event.candle);
        if (event.marker != null) {
          await _controller.addMarker(event.marker!);
        }
        break;
    }

    if (mounted) {
      setState(() {});
    }
  }
}
