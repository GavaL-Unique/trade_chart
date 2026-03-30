import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models/chart_timeframe.dart';
import 'models/drawing_tool.dart';
import 'models/fullscreen_behavior.dart';
import 'models/indicator_config.dart';
import 'models/trade_chart_ui_state.dart';
import 'trade_chart_config.dart';
import 'trade_chart_controller.dart';
import 'trade_chart_theme.dart';
import 'trade_chart_widget.dart';

class TradeChartWidget extends StatefulWidget {
  const TradeChartWidget({
    super.key,
    required this.controller,
    this.theme = const TradeChartTheme.dark(),
    this.config = const TradeChartConfig(),
    this.fullscreenBehavior = const FullscreenBehavior(),
    this.marketTitle = 'BTC/USDT',
    this.marketStats = const <String>['24h High', '24h Low', '24h Turnover'],
    this.availableTimeframes = const <ChartTimeframe>[
      ChartTimeframe.m1,
      ChartTimeframe.m5,
      ChartTimeframe.m15,
      ChartTimeframe.h1,
      ChartTimeframe.h4,
      ChartTimeframe.d1,
    ],
    this.onChartReady,
    this.onViewportChange,
    this.onCrosshairUpdate,
    this.onTimeframeSelected,
    this.routeMode = false,
  });

  final TradeChartController controller;
  final TradeChartTheme theme;
  final TradeChartConfig config;
  final FullscreenBehavior fullscreenBehavior;
  final String marketTitle;
  final List<String> marketStats;
  final List<ChartTimeframe> availableTimeframes;
  final VoidCallback? onChartReady;
  final ValueChanged<dynamic>? onViewportChange;
  final ValueChanged<dynamic>? onCrosshairUpdate;
  final ValueChanged<ChartTimeframe>? onTimeframeSelected;
  final bool routeMode;

  @override
  State<TradeChartWidget> createState() => _TradeChartWidgetState();
}

class _TradeChartWidgetState extends State<TradeChartWidget> {
  StreamSubscription<bool>? _fullscreenSubscription;
  bool _fullscreenRouteActive = false;

  @override
  void initState() {
    super.initState();
    widget.controller.setInitialPresentation(
      config: widget.config,
      theme: widget.theme,
      fullscreenBehavior: widget.fullscreenBehavior,
    );
    _fullscreenSubscription = widget.controller.fullscreenRequests.listen(
      _handleFullscreenRequest,
    );
  }

  @override
  void didUpdateWidget(covariant TradeChartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _fullscreenSubscription?.cancel();
      _fullscreenSubscription = widget.controller.fullscreenRequests.listen(
        _handleFullscreenRequest,
      );
    }
    widget.controller.setInitialPresentation(
      config: widget.config,
      theme: widget.theme,
      fullscreenBehavior: widget.fullscreenBehavior,
    );
  }

  @override
  void dispose() {
    _fullscreenSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TradeChartUiState>(
      valueListenable: widget.controller.uiStateListenable,
      builder: (context, state, _) {
        final selectedTimeframe =
            state.selectedTimeframe ?? widget.availableTimeframes.first;
        final showRawChart = !state.isFullscreen || widget.routeMode;
        return DecoratedBox(
          decoration: BoxDecoration(
            color: widget.theme.backgroundColor,
            borderRadius: BorderRadius.circular(widget.routeMode ? 0 : 18),
            border: widget.routeMode
                ? null
                : Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            children: [
              _buildHeader(state, selectedTimeframe),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          _buildTimeframeRow(selectedTimeframe),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                              child: ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(widget.routeMode ? 0 : 14),
                                child: showRawChart
                                    ? TradeChart(
                                        controller: widget.controller,
                                        theme: widget.theme,
                                        config: widget.config.copyWith(
                                          enableCrosshair:
                                              state.crosshairEnabled,
                                        ),
                                        onChartReady: widget.onChartReady,
                                        onViewportChange:
                                            widget.onViewportChange == null
                                                ? null
                                                : (event) => widget
                                                    .onViewportChange!(event),
                                        onCrosshairUpdate:
                                            widget.onCrosshairUpdate == null
                                                ? null
                                                : (event) => widget
                                                    .onCrosshairUpdate!(event),
                                      )
                                    : ColoredBox(
                                        color: widget.theme.backgroundColor,
                                      ),
                              ),
                            ),
                          ),
                          _buildIndicatorRow(state),
                        ],
                      ),
                    ),
                    if (state.isDrawingMode || widget.routeMode)
                      _buildDrawingToolbar(state),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(
    TradeChartUiState state,
    ChartTimeframe selectedTimeframe,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                widget.marketTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '+1.02%',
                style: TextStyle(
                  color: widget.theme.bullColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              _toolbarButton(
                icon: state.isDrawingMode ? Icons.edit_off : Icons.edit_outlined,
                onTap: widget.controller.toggleDrawingMode,
              ),
              const SizedBox(width: 8),
              _toolbarButton(
                icon: widget.routeMode
                    ? Icons.fullscreen_exit
                    : Icons.fullscreen,
                onTap: widget.routeMode
                    ? widget.controller.exitFullscreen
                    : widget.controller.enterFullscreen,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                'Time',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
              ),
              const SizedBox(width: 18),
              ...widget.availableTimeframes.take(4).map(
                    (timeframe) => Padding(
                      padding: const EdgeInsets.only(right: 18),
                      child: GestureDetector(
                        onTap: () => _selectTimeframe(timeframe),
                        child: Text(
                          _labelForTimeframe(timeframe),
                          style: TextStyle(
                            color: timeframe == selectedTimeframe
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.52),
                            fontWeight: timeframe == selectedTimeframe
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
              GestureDetector(
                onTap: () => _selectTimeframe(widget.availableTimeframes.last),
                child: Text(
                  'More',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                ),
              ),
              const SizedBox(width: 20),
              Text(
                'Depth',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.38)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeframeRow(ChartTimeframe selectedTimeframe) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Text(
            'Live',
            style: TextStyle(color: widget.theme.bullColor, fontSize: 12),
          ),
          const SizedBox(width: 8),
          Text(
            _labelForTimeframe(selectedTimeframe),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            '67,332.4',
            style: TextStyle(
              color: widget.theme.bullColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicatorRow(TradeChartUiState state) {
    final defaults = <IndicatorConfig>[
      const IndicatorConfig.overlay(IndicatorKind.ma),
      const IndicatorConfig.overlay(IndicatorKind.ema),
      const IndicatorConfig.overlay(IndicatorKind.boll),
      const IndicatorConfig.overlay(IndicatorKind.sar),
      const IndicatorConfig.pane(IndicatorKind.mavol),
      const IndicatorConfig.pane(IndicatorKind.macd),
      const IndicatorConfig.pane(IndicatorKind.kdj),
    ];
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final indicator = defaults[index];
          final enabled = state.indicators.any((item) => item.kind == indicator.kind);
          return TextButton(
            onPressed: () {
              if (enabled) {
                widget.controller.removeIndicator(indicator.kind);
              } else {
                widget.controller.addIndicator(indicator);
              }
            },
            child: Text(
              indicator.kind.name.toUpperCase(),
              style: TextStyle(
                color: enabled ? Colors.white : Colors.white.withValues(alpha: 0.45),
                fontWeight: enabled ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 2),
        itemCount: defaults.length,
      ),
    );
  }

  Widget _buildDrawingToolbar(TradeChartUiState state) {
    const tools = <DrawingTool>[
      DrawingTool.trendLine,
      DrawingTool.arrow,
      DrawingTool.horizontalLine,
      DrawingTool.verticalLine,
      DrawingTool.ray,
      DrawingTool.parallelChannel,
      DrawingTool.brush,
      DrawingTool.eraser,
    ];
    return Container(
      width: 70,
      color: Colors.white.withValues(alpha: 0.06),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 18),
        children: [
          for (final tool in tools)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: InkWell(
                onTap: () => widget.controller.setDrawingTool(tool),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: state.activeDrawingTool == tool
                        ? Colors.white.withValues(alpha: 0.12)
                        : Colors.transparent,
                  ),
                  child: Icon(
                    _iconForTool(tool),
                    color: Colors.white.withValues(alpha: 0.82),
                    size: 21,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _toolbarButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white70, size: 18),
      ),
    );
  }

  Future<void> _handleFullscreenRequest(bool fullscreen) async {
    if (!mounted) {
      return;
    }
    if (fullscreen && !widget.routeMode && !_fullscreenRouteActive) {
      _fullscreenRouteActive = true;
      if (widget.fullscreenBehavior.rotateToLandscape) {
        await SystemChrome.setPreferredOrientations(
          const [
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
          ],
        );
      }
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      if (!mounted) {
        return;
      }
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => Scaffold(
            backgroundColor: widget.theme.backgroundColor,
            body: SafeArea(
              child: TradeChartWidget(
                controller: widget.controller,
                theme: widget.theme,
                config: widget.config,
                fullscreenBehavior: widget.fullscreenBehavior,
                marketTitle: widget.marketTitle,
                marketStats: widget.marketStats,
                availableTimeframes: widget.availableTimeframes,
                onChartReady: widget.onChartReady,
                onViewportChange: widget.onViewportChange,
                onCrosshairUpdate: widget.onCrosshairUpdate,
                onTimeframeSelected: widget.onTimeframeSelected,
                routeMode: true,
              ),
            ),
          ),
          fullscreenDialog: true,
        ),
      );
      _fullscreenRouteActive = false;
      await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      if (widget.controller.isFullscreen) {
        widget.controller.exitFullscreen();
      }
      return;
    }
    if (!fullscreen && widget.routeMode && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void _selectTimeframe(ChartTimeframe timeframe) {
    final callback = widget.onTimeframeSelected;
    if (callback != null) {
      callback(timeframe);
      return;
    }
    widget.controller.setTimeframe(timeframe);
  }

  static String _labelForTimeframe(ChartTimeframe timeframe) {
    switch (timeframe) {
      case ChartTimeframe.m1:
        return '1m';
      case ChartTimeframe.m3:
        return '3m';
      case ChartTimeframe.m5:
        return '5m';
      case ChartTimeframe.m15:
        return '15m';
      case ChartTimeframe.m30:
        return '30m';
      case ChartTimeframe.h1:
        return '1h';
      case ChartTimeframe.h4:
        return '4h';
      case ChartTimeframe.d1:
        return '1D';
      case ChartTimeframe.w1:
        return '1W';
      case ChartTimeframe.M1:
        return '1M';
    }
  }

  static IconData _iconForTool(DrawingTool tool) {
    switch (tool) {
      case DrawingTool.none:
        return Icons.edit_off;
      case DrawingTool.trendLine:
        return Icons.show_chart;
      case DrawingTool.arrow:
        return Icons.north_east;
      case DrawingTool.horizontalLine:
        return Icons.horizontal_rule;
      case DrawingTool.verticalLine:
        return Icons.swap_vert;
      case DrawingTool.ray:
        return Icons.trending_flat;
      case DrawingTool.parallelChannel:
        return Icons.view_stream;
      case DrawingTool.brush:
        return Icons.brush_outlined;
      case DrawingTool.eraser:
        return Icons.cleaning_services_outlined;
    }
  }
}
