import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trade_chart/trade_chart.dart';

void main() {
  testWidgets('TradeChart throws for unbounded constraints', (tester) async {
    final controller = TradeChartController();

    await tester.pumpWidget(
      MaterialApp(
        home: SingleChildScrollView(
          child: SizedBox(
            width: 320,
            child: TradeChart(controller: controller),
          ),
        ),
      ),
    );

    final dynamic exception = tester.takeException();
    expect(exception, isFlutterError);
    expect(
      (exception as FlutterError).toStringDeep(),
      contains('TradeChart requires bounded width and height'),
    );
  });
}
