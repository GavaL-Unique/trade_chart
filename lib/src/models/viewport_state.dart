import 'package:flutter/foundation.dart';

@immutable
class ViewportState {
  const ViewportState({
    required this.startTimestamp,
    required this.endTimestamp,
    required this.priceHigh,
    required this.priceLow,
    required this.visibleCandleCount,
    required this.candleWidth,
    required this.isAtLatest,
  });

  final int startTimestamp;
  final int endTimestamp;
  final double priceHigh;
  final double priceLow;
  final int visibleCandleCount;
  final double candleWidth;
  final bool isAtLatest;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ViewportState &&
            other.startTimestamp == startTimestamp &&
            other.endTimestamp == endTimestamp &&
            other.priceHigh == priceHigh &&
            other.priceLow == priceLow &&
            other.visibleCandleCount == visibleCandleCount &&
            other.candleWidth == candleWidth &&
            other.isAtLatest == isAtLatest);
  }

  @override
  int get hashCode => Object.hash(
    startTimestamp,
    endTimestamp,
    priceHigh,
    priceLow,
    visibleCandleCount,
    candleWidth,
    isAtLatest,
  );
}
