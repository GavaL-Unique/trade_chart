import 'package:flutter/foundation.dart';

import '../models/viewport_state.dart';

@immutable
class ViewportChangeEvent {
  const ViewportChangeEvent({required this.viewport, this.isAtLatest});

  final ViewportState viewport;
  final bool? isAtLatest;
}
