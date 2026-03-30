import 'package:flutter/foundation.dart';

enum DrawingTool {
  none,
  trendLine,
  arrow,
  horizontalLine,
  verticalLine,
  ray,
  parallelChannel,
  brush,
  eraser,
}

@immutable
class DrawingPoint {
  const DrawingPoint({
    required this.timestamp,
    required this.price,
  });

  final int timestamp;
  final double price;

  Map<String, Object> toJson() => {
        'timestamp': timestamp,
        'price': price,
      };

  factory DrawingPoint.fromJson(Map<String, Object?> json) {
    return DrawingPoint(
      timestamp: json['timestamp']! as int,
      price: (json['price']! as num).toDouble(),
    );
  }
}

@immutable
class DrawingObject {
  const DrawingObject({
    required this.id,
    required this.tool,
    required this.points,
    this.selected = false,
  });

  final String id;
  final DrawingTool tool;
  final List<DrawingPoint> points;
  final bool selected;

  DrawingObject copyWith({
    String? id,
    DrawingTool? tool,
    List<DrawingPoint>? points,
    bool? selected,
  }) {
    return DrawingObject(
      id: id ?? this.id,
      tool: tool ?? this.tool,
      points: points ?? this.points,
      selected: selected ?? this.selected,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'tool': tool.name,
        'points': points.map((point) => point.toJson()).toList(growable: false),
        'selected': selected,
      };

  factory DrawingObject.fromJson(Map<String, Object?> json) {
    return DrawingObject(
      id: json['id']! as String,
      tool: DrawingTool.values.byName(json['tool']! as String),
      points: (json['points']! as List<Object?>)
          .cast<Map<String, Object?>>()
          .map(DrawingPoint.fromJson)
          .toList(growable: false),
      selected: json['selected'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is DrawingObject &&
            other.id == id &&
            other.tool == tool &&
            listEquals(other.points, points) &&
            other.selected == selected;
  }

  @override
  int get hashCode => Object.hash(id, tool, Object.hashAll(points), selected);
}
