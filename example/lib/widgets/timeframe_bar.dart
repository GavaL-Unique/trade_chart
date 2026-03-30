import 'package:flutter/material.dart';

import 'package:trade_chart/trade_chart.dart';

class TimeframeBar extends StatelessWidget {
  const TimeframeBar({
    super.key,
    required this.selectedTimeframe,
    required this.selectedChartType,
    required this.onTimeframeSelected,
    required this.onChartTypeSelected,
  });

  final ChartTimeframe selectedTimeframe;
  final ChartType selectedChartType;
  final ValueChanged<ChartTimeframe> onTimeframeSelected;
  final ValueChanged<ChartType> onChartTypeSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          children: [ChartTimeframe.h1, ChartTimeframe.h4, ChartTimeframe.d1]
              .map((timeframe) {
                return ChoiceChip(
                  label: Text(timeframe.name),
                  selected: timeframe == selectedTimeframe,
                  onSelected: (_) => onTimeframeSelected(timeframe),
                );
              })
              .toList(growable: false),
        ),
        const SizedBox(height: 10),
        SegmentedButton<ChartType>(
          segments: const [
            ButtonSegment<ChartType>(
              value: ChartType.candle,
              label: Text('Candles'),
            ),
            ButtonSegment<ChartType>(
              value: ChartType.line,
              label: Text('Line'),
            ),
          ],
          selected: {selectedChartType},
          onSelectionChanged: (selection) {
            onChartTypeSelected(selection.first);
          },
        ),
      ],
    );
  }
}
