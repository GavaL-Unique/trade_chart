import 'package:flutter/foundation.dart';

enum ChartMarkerType { buy, sell }

@immutable
class ChartMarker {
  const ChartMarker({
    required this.id,
    required this.timestamp,
    required this.price,
    required this.type,
    this.label,
  })  : assert(id != '', 'id must not be empty.'),
        assert(timestamp >= 0, 'timestamp must be >= 0.'),
        assert(
            label == null || label != '', 'label must not be empty when set.');

  final String id;
  final int timestamp;
  final double price;
  final ChartMarkerType type;
  final String? label;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ChartMarker &&
            other.id == id &&
            other.timestamp == timestamp &&
            other.price == price &&
            other.type == type &&
            other.label == label);
  }

  @override
  int get hashCode => Object.hash(id, timestamp, price, type, label);
}
