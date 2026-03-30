import 'dart:async';
import 'dart:math';

import 'package:trade_chart/trade_chart.dart';

import 'sample_candles.dart';

enum FakeRealtimeEventType { updateLast, append }

class FakeRealtimeEvent {
  const FakeRealtimeEvent._({
    required this.type,
    required this.candle,
    this.marker,
  });

  factory FakeRealtimeEvent.update(CandleData candle) {
    return FakeRealtimeEvent._(
      type: FakeRealtimeEventType.updateLast,
      candle: candle,
    );
  }

  factory FakeRealtimeEvent.append(CandleData candle, {ChartMarker? marker}) {
    return FakeRealtimeEvent._(
      type: FakeRealtimeEventType.append,
      candle: candle,
      marker: marker,
    );
  }

  final FakeRealtimeEventType type;
  final CandleData candle;
  final ChartMarker? marker;
}

class FakeRealtimeStream {
  FakeRealtimeStream({
    Random? random,
    this.tickInterval = const Duration(milliseconds: 700),
  }) : _random = random ?? Random(42);

  final Random _random;
  final Duration tickInterval;

  Stream<FakeRealtimeEvent> stream({
    required CandleData seedCandle,
    required ChartTimeframe timeframe,
  }) async* {
    var current = seedCandle;
    var tickCount = 0;

    while (true) {
      await Future<void>.delayed(tickInterval);
      tickCount += 1;

      final delta = (_random.nextDouble() - 0.5) * 64.0;
      final nextClose = current.close + delta;

      if (tickCount % 5 == 0) {
        final appended = CandleData(
          timestamp: current.timestamp + timeframeStepMs(timeframe),
          open: current.close,
          high: (current.close > nextClose ? current.close : nextClose) + 24.0,
          low: (current.close < nextClose ? current.close : nextClose) - 24.0,
          close: nextClose,
          volume: 1800.0 + _random.nextInt(1200).toDouble(),
        );
        current = appended;
        yield FakeRealtimeEvent.append(
          appended,
          marker: tickCount % 10 == 0
              ? ChartMarker(
                  id: 'rt-${appended.timestamp}',
                  timestamp: appended.timestamp,
                  price: appended.close,
                  type: appended.close >= appended.open
                      ? ChartMarkerType.buy
                      : ChartMarkerType.sell,
                  label: appended.close >= appended.open ? 'BUY' : 'SELL',
                )
              : null,
        );
      } else {
        final updated = CandleData(
          timestamp: current.timestamp,
          open: current.open,
          high: (current.high > nextClose ? current.high : nextClose) + 0.0,
          low: (current.low < nextClose ? current.low : nextClose) - 0.0,
          close: nextClose,
          volume: current.volume + 60 + _random.nextInt(140).toDouble(),
        );
        current = updated;
        yield FakeRealtimeEvent.update(updated);
      }
    }
  }
}
