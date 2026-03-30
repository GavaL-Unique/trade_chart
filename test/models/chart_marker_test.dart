import 'package:flutter_test/flutter_test.dart';
import 'package:trade_chart/trade_chart.dart';

void main() {
  test('ChartMarker equality is value-based', () {
    const a = ChartMarker(
      id: 'buy-1',
      timestamp: 1,
      price: 10,
      type: ChartMarkerType.buy,
      label: 'Buy',
    );
    const b = ChartMarker(
      id: 'buy-1',
      timestamp: 1,
      price: 10,
      type: ChartMarkerType.buy,
      label: 'Buy',
    );

    expect(a, b);
  });

  test('ChartMarker rejects an empty id', () {
    expect(
      () => ChartMarker(
        id: '',
        timestamp: 1,
        price: 10,
        type: ChartMarkerType.buy,
      ),
      throwsAssertionError,
    );
  });
}
