import 'package:trade_chart/trade_chart.dart';

List<CandleData> buildSampleCandles({
  ChartTimeframe timeframe = ChartTimeframe.h1,
}) {
  const baseTimestamp = 1_710_000_000_000;
  final stepMs = timeframeStepMs(timeframe);
  var previousClose = 42250.0;

  return List<CandleData>.generate(240, (index) {
    final trend = index * 6.5;
    final wave = ((index % 12) - 6) * 18.0;
    final open = previousClose;
    final close = open + wave + (index.isEven ? 22.0 : -11.0) + trend * 0.015;
    final high = (open > close ? open : close) + 48.0 + (index % 5) * 7.0;
    final low = (open < close ? open : close) - 44.0 - (index % 4) * 6.0;
    final volume = 1800.0 + (index % 9) * 220.0 + index * 3.0;
    previousClose = close;

    return CandleData(
      timestamp: baseTimestamp + index * stepMs,
      open: open,
      high: high,
      low: low,
      close: close,
      volume: volume,
    );
  });
}

List<ChartMarker> buildSampleMarkers(List<CandleData> candles) {
  if (candles.length < 5) {
    return const <ChartMarker>[];
  }

  final markerIndexes = <int>[
    24,
    76,
    148,
    212,
  ].where((index) => index < candles.length).toList(growable: false);

  return List<ChartMarker>.generate(markerIndexes.length, (markerPosition) {
    final candle = candles[markerIndexes[markerPosition]];
    final isBuy = markerPosition.isEven;
    return ChartMarker(
      id: 'sample-${candle.timestamp}',
      timestamp: candle.timestamp,
      price: isBuy ? candle.low + 12.0 : candle.high - 12.0,
      type: isBuy ? ChartMarkerType.buy : ChartMarkerType.sell,
      label: isBuy ? 'BUY' : 'SELL',
    );
  });
}

int timeframeStepMs(ChartTimeframe timeframe) {
  switch (timeframe) {
    case ChartTimeframe.m1:
      return 60 * 1000;
    case ChartTimeframe.m3:
      return 3 * 60 * 1000;
    case ChartTimeframe.m5:
      return 5 * 60 * 1000;
    case ChartTimeframe.m15:
      return 15 * 60 * 1000;
    case ChartTimeframe.m30:
      return 30 * 60 * 1000;
    case ChartTimeframe.h1:
      return 60 * 60 * 1000;
    case ChartTimeframe.h4:
      return 4 * 60 * 60 * 1000;
    case ChartTimeframe.d1:
      return 24 * 60 * 60 * 1000;
    case ChartTimeframe.w1:
      return 7 * 24 * 60 * 60 * 1000;
    case ChartTimeframe.M1:
      return 30 * 24 * 60 * 60 * 1000;
  }
}
