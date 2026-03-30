import 'package:flutter/material.dart';

@immutable
class TradeChartTheme {
  const TradeChartTheme({
    required this.backgroundColor,
    required this.gridColor,
    required this.bullColor,
    required this.bearColor,
    required this.volumeBullColor,
    required this.volumeBearColor,
    required this.crosshairColor,
    required this.crosshairLabelBackgroundColor,
    required this.textColor,
    required this.axisColor,
    required this.buyMarkerColor,
    required this.sellMarkerColor,
    required this.axisTextSize,
    required this.crosshairTextSize,
  });

  const TradeChartTheme.light()
    : backgroundColor = const Color(0xFFFFFFFF),
      gridColor = const Color(0xFFEAECEE),
      bullColor = const Color(0xFF16A34A),
      bearColor = const Color(0xFFDC2626),
      volumeBullColor = const Color(0x6616A34A),
      volumeBearColor = const Color(0x66DC2626),
      crosshairColor = const Color(0xFF4646BB),
      crosshairLabelBackgroundColor = const Color(0xFFF5F5F5),
      textColor = const Color(0xFF000000),
      axisColor = const Color(0xFF303030),
      buyMarkerColor = const Color(0xFF16A34A),
      sellMarkerColor = const Color(0xFFDC2626),
      axisTextSize = 11,
      crosshairTextSize = 12;

  const TradeChartTheme.dark()
    : backgroundColor = const Color(0xFF000000),
      gridColor = const Color(0xFF1C1C1C),
      bullColor = const Color(0xFF22C55E),
      bearColor = const Color(0xFFEF4444),
      volumeBullColor = const Color(0x6622C55E),
      volumeBearColor = const Color(0x66EF4444),
      crosshairColor = const Color(0xFF4646BB),
      crosshairLabelBackgroundColor = const Color(0xFF1C1C1C),
      textColor = const Color(0xFFFFFFFF),
      axisColor = const Color(0xFFE2E8F0),
      buyMarkerColor = const Color(0xFF22C55E),
      sellMarkerColor = const Color(0xFFEF4444),
      axisTextSize = 11,
      crosshairTextSize = 12;

  final Color backgroundColor;
  final Color gridColor;
  final Color bullColor;
  final Color bearColor;
  final Color volumeBullColor;
  final Color volumeBearColor;
  final Color crosshairColor;
  final Color crosshairLabelBackgroundColor;
  final Color textColor;
  final Color axisColor;
  final Color buyMarkerColor;
  final Color sellMarkerColor;
  final double axisTextSize;
  final double crosshairTextSize;

  TradeChartTheme copyWith({
    Color? backgroundColor,
    Color? gridColor,
    Color? bullColor,
    Color? bearColor,
    Color? volumeBullColor,
    Color? volumeBearColor,
    Color? crosshairColor,
    Color? crosshairLabelBackgroundColor,
    Color? textColor,
    Color? axisColor,
    Color? buyMarkerColor,
    Color? sellMarkerColor,
    double? axisTextSize,
    double? crosshairTextSize,
  }) {
    return TradeChartTheme(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      gridColor: gridColor ?? this.gridColor,
      bullColor: bullColor ?? this.bullColor,
      bearColor: bearColor ?? this.bearColor,
      volumeBullColor: volumeBullColor ?? this.volumeBullColor,
      volumeBearColor: volumeBearColor ?? this.volumeBearColor,
      crosshairColor: crosshairColor ?? this.crosshairColor,
      crosshairLabelBackgroundColor:
          crosshairLabelBackgroundColor ?? this.crosshairLabelBackgroundColor,
      textColor: textColor ?? this.textColor,
      axisColor: axisColor ?? this.axisColor,
      buyMarkerColor: buyMarkerColor ?? this.buyMarkerColor,
      sellMarkerColor: sellMarkerColor ?? this.sellMarkerColor,
      axisTextSize: axisTextSize ?? this.axisTextSize,
      crosshairTextSize: crosshairTextSize ?? this.crosshairTextSize,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TradeChartTheme &&
        other.backgroundColor == backgroundColor &&
        other.gridColor == gridColor &&
        other.bullColor == bullColor &&
        other.bearColor == bearColor &&
        other.volumeBullColor == volumeBullColor &&
        other.volumeBearColor == volumeBearColor &&
        other.crosshairColor == crosshairColor &&
        other.crosshairLabelBackgroundColor == crosshairLabelBackgroundColor &&
        other.textColor == textColor &&
        other.axisColor == axisColor &&
        other.buyMarkerColor == buyMarkerColor &&
        other.sellMarkerColor == sellMarkerColor &&
        other.axisTextSize == axisTextSize &&
        other.crosshairTextSize == crosshairTextSize;
  }

  @override
  int get hashCode => Object.hash(
        backgroundColor,
        gridColor,
        bullColor,
        bearColor,
        volumeBullColor,
        volumeBearColor,
        crosshairColor,
        crosshairLabelBackgroundColor,
        textColor,
        axisColor,
        buyMarkerColor,
        sellMarkerColor,
        axisTextSize,
        crosshairTextSize,
      );
}
