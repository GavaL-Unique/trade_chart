import 'package:flutter/foundation.dart';

@immutable
class FullscreenBehavior {
  const FullscreenBehavior({
    this.enabled = true,
    this.rotateToLandscape = true,
    this.showTopToolbar = true,
    this.showTimeframeRow = true,
    this.showIndicatorRow = true,
    this.showDrawingToolbar = true,
  });

  final bool enabled;
  final bool rotateToLandscape;
  final bool showTopToolbar;
  final bool showTimeframeRow;
  final bool showIndicatorRow;
  final bool showDrawingToolbar;

  FullscreenBehavior copyWith({
    bool? enabled,
    bool? rotateToLandscape,
    bool? showTopToolbar,
    bool? showTimeframeRow,
    bool? showIndicatorRow,
    bool? showDrawingToolbar,
  }) {
    return FullscreenBehavior(
      enabled: enabled ?? this.enabled,
      rotateToLandscape: rotateToLandscape ?? this.rotateToLandscape,
      showTopToolbar: showTopToolbar ?? this.showTopToolbar,
      showTimeframeRow: showTimeframeRow ?? this.showTimeframeRow,
      showIndicatorRow: showIndicatorRow ?? this.showIndicatorRow,
      showDrawingToolbar: showDrawingToolbar ?? this.showDrawingToolbar,
    );
  }
}
