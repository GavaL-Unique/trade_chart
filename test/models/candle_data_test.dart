import 'package:flutter_test/flutter_test.dart';
import 'package:trade_chart/trade_chart.dart';

void main() {
  test('CandleData equality is value-based', () {
    const a = CandleData(
      timestamp: 1,
      open: 2,
      high: 3,
      low: 1,
      close: 2.5,
      volume: 10,
    );
    const b = CandleData(
      timestamp: 1,
      open: 2,
      high: 3,
      low: 1,
      close: 2.5,
      volume: 10,
    );

    expect(a, b);
  });

  test('CandleData rejects invalid OHLC ordering', () {
    expect(
      () => CandleData(
        timestamp: 1,
        open: 10,
        high: 9,
        low: 8,
        close: 9,
        volume: 1,
      ),
      throwsAssertionError,
    );
  });
}
