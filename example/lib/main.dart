import 'package:flutter/material.dart';

import 'screens/chart_screen.dart';

void main() {
  runApp(const TradeChartExampleApp());
}

class TradeChartExampleApp extends StatelessWidget {
  const TradeChartExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'trade_chart Example',
      theme: ThemeData.dark(),
      home: const ChartScreen(),
    );
  }
}
