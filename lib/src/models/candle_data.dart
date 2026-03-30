import 'package:flutter/foundation.dart';

@immutable
class CandleData {
  const CandleData({
    required this.timestamp,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  })  : assert(timestamp >= 0, 'timestamp must be >= 0.'),
        assert(volume >= 0, 'volume must be >= 0.'),
        assert(high >= low, 'high must be >= low.'),
        assert(
            high >= open && high >= close, 'high must be >= open and close.'),
        assert(low <= open && low <= close, 'low must be <= open and close.');

  final int timestamp;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is CandleData &&
            other.timestamp == timestamp &&
            other.open == open &&
            other.high == high &&
            other.low == low &&
            other.close == close &&
            other.volume == volume);
  }

  @override
  int get hashCode => Object.hash(timestamp, open, high, low, close, volume);
}
