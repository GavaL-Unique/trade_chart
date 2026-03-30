import 'package:flutter_test/flutter_test.dart';
import 'package:trade_chart/src/bridge/chart_bridge.dart';
import 'package:trade_chart/src/bridge/bridge_mapper.dart';
import 'package:trade_chart/src/bridge/generated/chart_api.g.dart';
import 'package:trade_chart/trade_chart.dart';

void main() {
  test('controller starts detached', () {
    final controller = TradeChartController();

    expect(controller.isAttached, isFalse);
  });

  test('viewport mapper carries isAtLatest into viewport state', () {
    final viewport = BridgeMapper.viewportFromMessage(
      ViewportStateMessage(
        startTimestamp: 1,
        endTimestamp: 2,
        priceHigh: 10,
        priceLow: 5,
        visibleCandleCount: 30,
        candleWidth: 8,
        isAtLatest: true,
      ),
    );

    expect(viewport.isAtLatest, isTrue);
  });

  test('chart marker equality is value-based for realtime marker updates', () {
    const marker = ChartMarker(
      id: 'rt-1',
      timestamp: 1000,
      price: 50,
      type: ChartMarkerType.buy,
      label: 'BUY',
    );

    expect(
      marker,
      const ChartMarker(
        id: 'rt-1',
        timestamp: 1000,
        price: 50,
        type: ChartMarkerType.buy,
        label: 'BUY',
      ),
    );
  });

  test('controller rejects attaching to a second chart bridge', () {
    final controller = TradeChartController();
    final firstBridge = ChartBridge(hostApi: ChartHostApi());
    final secondBridge = ChartBridge(hostApi: ChartHostApi());

    controller.attachBridge(firstBridge);

    expect(
      () => controller.attachBridge(secondBridge),
      throwsStateError,
    );
  });

  test('loadCandles ignores an empty dataset', () async {
    final controller = TradeChartController();

    await controller.loadCandles(const <CandleData>[], ChartTimeframe.h1);

    expect(controller.isAttached, isFalse);
  });
}
