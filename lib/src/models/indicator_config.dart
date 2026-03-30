import 'package:flutter/foundation.dart';

enum IndicatorKind {
  ma,
  ema,
  boll,
  sar,
  mavol,
  macd,
  kdj,
}

enum IndicatorPlacement {
  overlay,
  pane,
}

@immutable
class IndicatorConfig {
  const IndicatorConfig({
    required this.kind,
    required this.enabled,
    required this.placement,
    this.parameters = const <String, double>{},
    this.paneHeightFactor,
  });

  const IndicatorConfig.overlay(
    this.kind, {
    this.enabled = true,
    this.parameters = const <String, double>{},
  })  : placement = IndicatorPlacement.overlay,
        paneHeightFactor = null;

  const IndicatorConfig.pane(
    this.kind, {
    this.enabled = true,
    this.parameters = const <String, double>{},
    this.paneHeightFactor = 0.18,
  }) : placement = IndicatorPlacement.pane;

  final IndicatorKind kind;
  final bool enabled;
  final IndicatorPlacement placement;
  final Map<String, double> parameters;
  final double? paneHeightFactor;

  IndicatorConfig copyWith({
    IndicatorKind? kind,
    bool? enabled,
    IndicatorPlacement? placement,
    Map<String, double>? parameters,
    double? paneHeightFactor,
  }) {
    return IndicatorConfig(
      kind: kind ?? this.kind,
      enabled: enabled ?? this.enabled,
      placement: placement ?? this.placement,
      parameters: parameters ?? this.parameters,
      paneHeightFactor: paneHeightFactor ?? this.paneHeightFactor,
    );
  }

  Map<String, Object?> toJson() => {
        'kind': kind.name,
        'enabled': enabled,
        'placement': placement.name,
        'parameters': parameters.map(
          (key, value) => MapEntry<String, Object?>(key, value),
        ),
        'paneHeightFactor': paneHeightFactor,
      };

  factory IndicatorConfig.fromJson(Map<String, Object?> json) {
    return IndicatorConfig(
      kind: IndicatorKind.values.byName(json['kind']! as String),
      enabled: json['enabled'] as bool? ?? true,
      placement: IndicatorPlacement.values
          .byName(json['placement']! as String),
      parameters: ((json['parameters'] as Map<Object?, Object?>?) ?? const {})
          .map(
            (key, value) =>
                MapEntry(key! as String, (value! as num).toDouble()),
          ),
      paneHeightFactor: (json['paneHeightFactor'] as num?)?.toDouble(),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is IndicatorConfig &&
            other.kind == kind &&
            other.enabled == enabled &&
            other.placement == placement &&
            mapEquals(other.parameters, parameters) &&
            other.paneHeightFactor == paneHeightFactor;
  }

  @override
  int get hashCode => Object.hash(
        kind,
        enabled,
        placement,
        Object.hashAllUnordered(
          parameters.entries.map((entry) => Object.hash(entry.key, entry.value)),
        ),
        paneHeightFactor,
      );
}
