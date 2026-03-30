#!/bin/bash
set -euo pipefail

dart run pigeon \
  --input pigeons/chart_api.dart \
  --dart_out lib/src/bridge/generated/chart_api.g.dart \
  --kotlin_out android/src/main/kotlin/com/tradechart/plugin/bridge/generated/ChartApi.g.kt \
  --kotlin_package com.tradechart.plugin.bridge.generated \
  --swift_out ios/Classes/Bridge/Generated/ChartApi.g.swift

echo "Pigeon code generated."
