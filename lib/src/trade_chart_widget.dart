import 'dart:async';

import 'package:flutter/material.dart';

import 'bridge/chart_bridge.dart';
import 'events/crosshair_event.dart';
import 'events/viewport_event.dart';
import 'gestures/chart_gesture_handler.dart';
import 'gestures/gesture_state.dart';
import 'trade_chart_config.dart';
import 'trade_chart_controller.dart';
import 'trade_chart_theme.dart';

class TradeChart extends StatefulWidget {
  /// Renders a native trading chart via a Flutter [Texture].
  ///
  /// The widget must be placed in bounded layout constraints such as a
  /// [SizedBox], [AspectRatio], or an [Expanded] child.
  const TradeChart({
    super.key,
    required this.controller,
    this.theme = const TradeChartTheme.dark(),
    this.config = const TradeChartConfig(),
    this.onChartReady,
    this.onViewportChange,
    this.onCrosshairUpdate,
  });

  final TradeChartController controller;
  final TradeChartTheme theme;
  final TradeChartConfig config;
  final VoidCallback? onChartReady;
  final ValueChanged<ViewportChangeEvent>? onViewportChange;
  final ValueChanged<CrosshairEvent>? onCrosshairUpdate;

  @override
  State<TradeChart> createState() => _TradeChartState();
}

class _TradeChartState extends State<TradeChart> {
  late final ChartBridge _bridge;
  late final ChartGestureHandler _gestureHandler;

  Size? _lastSize;
  int? _textureId;
  bool _initializing = false;

  @override
  void initState() {
    super.initState();
    _bridge = ChartBridge();
    _gestureHandler = ChartGestureHandler(_bridge);
    widget.controller.setInitialPresentation(
      config: widget.config,
      theme: widget.theme,
    );
    widget.controller.attachBridge(_bridge);
  }

  @override
  void didUpdateWidget(covariant TradeChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.detachBridge(_bridge);
      widget.controller.attachBridge(_bridge);
    }
    if (oldWidget.theme != widget.theme && _textureId != null) {
      widget.controller.setInitialPresentation(
        config: widget.config,
        theme: widget.theme,
      );
      unawaited(_bridge.setTheme(widget.theme));
    }
    if (oldWidget.config != widget.config && _textureId != null) {
      widget.controller.setInitialPresentation(
        config: widget.config,
        theme: widget.theme,
      );
      unawaited(_bridge.setConfig(widget.config));
    }
    if (oldWidget.onChartReady != widget.onChartReady ||
        oldWidget.onViewportChange != widget.onViewportChange ||
        oldWidget.onCrosshairUpdate != widget.onCrosshairUpdate) {
      _bridge.updateCallbacks(
        onChartReady: widget.onChartReady,
        onViewportChanged: widget.onViewportChange,
        onCrosshairData: widget.onCrosshairUpdate,
      );
    }
  }

  @override
  void dispose() {
    widget.controller.detachBridge(_bridge);
    unawaited(_bridge.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.hasBoundedWidth || !constraints.hasBoundedHeight) {
          throw FlutterError.fromParts(<DiagnosticsNode>[
            ErrorSummary('TradeChart requires bounded width and height.'),
            ErrorDescription(
              'Place TradeChart inside a widget with finite constraints such '
              'as SizedBox, AspectRatio, Expanded, or a constrained parent.',
            ),
          ]);
        }
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        if (size.width > 0 && size.height > 0) {
          _scheduleInitializationIfNeeded(size);
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onScaleStart: (_) {
                // Mode is determined by the first onScaleUpdate
                // based on pointerCount. No action needed here.
              },
              onScaleUpdate: (details) {
                if (details.pointerCount >= 2 ||
                    _gestureHandler.mode == GestureMode.zooming) {
                  unawaited(
                    _gestureHandler.handleScaleUpdate(
                      details.scale,
                      details.localFocalPoint.dx,
                    ),
                  );
                } else {
                  unawaited(
                    _gestureHandler
                        .handlePanUpdate(details.focalPointDelta.dx),
                  );
                }
              },
              onScaleEnd: (details) {
                final mode = _gestureHandler.mode;
                if (mode == GestureMode.zooming) {
                  unawaited(_gestureHandler.handleScaleEnd());
                } else if (mode == GestureMode.panning) {
                  unawaited(
                    _gestureHandler
                        .handlePanEnd(details.velocity.pixelsPerSecond.dx),
                  );
                }
              },
              onLongPressStart: widget.config.enableCrosshair
                  ? (details) {
                      unawaited(
                        _gestureHandler.handleCrosshairStart(
                          details.localPosition.dx,
                          details.localPosition.dy,
                        ),
                      );
                    }
                  : null,
              onLongPressMoveUpdate: widget.config.enableCrosshair
                  ? (details) {
                      unawaited(
                        _gestureHandler.handleCrosshairMove(
                          details.localPosition.dx,
                          details.localPosition.dy,
                        ),
                      );
                    }
                  : null,
              onLongPressEnd: widget.config.enableCrosshair
                  ? (_) {
                      unawaited(_gestureHandler.handleCrosshairEnd());
                    }
                  : null,
              child: _textureId == null
                  ? ColoredBox(color: widget.theme.backgroundColor)
                  : Texture(textureId: _textureId!),
            ),
          ],
        );
      },
    );
  }

  void _scheduleInitializationIfNeeded(Size size) {
    if (_lastSize == size && (_textureId != null || _initializing)) {
      return;
    }
    _lastSize = size;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (_textureId == null) {
        _initialize(size);
      } else {
        unawaited(_bridge.onSizeChanged(size.width, size.height));
      }
    });
  }

  Future<void> _initialize(Size size) async {
    if (_initializing) {
      return;
    }
    _initializing = true;
    try {
      final textureId = await _bridge.initialize(
        width: size.width,
        height: size.height,
        devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
        theme: widget.theme,
        config: widget.config,
        onChartReady: widget.onChartReady,
        onViewportChanged: widget.onViewportChange,
        onCrosshairData: widget.onCrosshairUpdate,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _textureId = textureId;
      });
    } finally {
      _initializing = false;
    }
  }
}
