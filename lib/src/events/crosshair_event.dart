import 'package:flutter/foundation.dart';

@immutable
class CrosshairEvent {
  const CrosshairEvent({
    required this.timestamp,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
    required this.x,
    required this.y,
  });

  final int timestamp;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;
  final double x;
  final double y;
}
