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

  test('controller tracks fullscreen, drawings, and indicators locally', () {
    final controller = TradeChartController();

    controller.enterFullscreen();
    controller.toggleDrawingMode();
    controller.setDrawingTool(DrawingTool.trendLine);
    controller.addIndicator(const IndicatorConfig.overlay(IndicatorKind.ma));

    expect(controller.isFullscreen, isTrue);
    expect(controller.isDrawingMode, isTrue);
    expect(controller.activeDrawingTool, DrawingTool.trendLine);
    expect(controller.indicators, hasLength(1));
  });

  test('controller restoreUiState restores serializable UI state', () {
    final controller = TradeChartController();

    controller.restoreUiState({
      'isFullscreen': true,
      'isDrawingMode': true,
      'activeDrawingTool': 'ray',
      'selectedTimeframe': 'm15',
      'crosshairEnabled': false,
      'indicators': [
        {
          'kind': 'ema',
          'enabled': true,
          'placement': 'overlay',
          'parameters': {'period': 7.0},
          'paneHeightFactor': null,
        },
      ],
      'drawings': [
        {
          'id': 'd1',
          'tool': 'horizontalLine',
          'points': [
            {'timestamp': 1, 'price': 100.0},
          ],
          'selected': false,
        },
      ],
    });

    expect(controller.isFullscreen, isTrue);
    expect(controller.activeDrawingTool, DrawingTool.ray);
    expect(controller.selectedTimeframe, ChartTimeframe.m15);
    expect(controller.isCrosshairEnabled, isFalse);
    expect(controller.indicators.single.kind, IndicatorKind.ema);
    expect(controller.drawings.single.tool, DrawingTool.horizontalLine);
  });
}
