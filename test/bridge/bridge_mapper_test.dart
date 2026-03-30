import 'package:flutter_test/flutter_test.dart';
import 'package:trade_chart/src/bridge/bridge_mapper.dart';
import 'package:trade_chart/trade_chart.dart';

void main() {
  test('BridgeMapper converts candle to message', () {
    const candle = CandleData(
      timestamp: 1000,
      open: 1,
      high: 2,
      low: 0.5,
      close: 1.5,
      volume: 3,
    );

    final message = BridgeMapper.candleToMessage(candle);

    expect(message.timestamp, 1000);
    expect(message.close, 1.5);
  });

  test('BridgeMapper converts marker list to message', () {
    const markers = <ChartMarker>[
      ChartMarker(
        id: 'buy-1',
        timestamp: 2000,
        price: 101.5,
        type: ChartMarkerType.buy,
        label: 'BUY',
      ),
      ChartMarker(
        id: 'sell-1',
        timestamp: 3000,
        price: 98.0,
        type: ChartMarkerType.sell,
        label: 'SELL',
      ),
    ];

    final message = BridgeMapper.markersToMessage(markers);

    expect(message.markers, hasLength(2));
    expect(message.markers.first.type, 'buy');
    expect(message.markers.last.label, 'SELL');
  });
}
