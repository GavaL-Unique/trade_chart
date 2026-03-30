import 'package:flutter_test/flutter_test.dart';
import 'package:trade_chart/trade_chart.dart';

void main() {
  test('TradeChartConfig rejects invalid visible candle bounds', () {
    expect(
      () => TradeChartConfig(
        minVisibleCandles: 40,
        maxVisibleCandles: 10,
      ),
      throwsAssertionError,
    );
  });

  test('TradeChartConfig rejects invalid volume ratio', () {
    expect(
      () => TradeChartConfig(volumeHeightRatio: 0),
      throwsAssertionError,
    );
  });
}
