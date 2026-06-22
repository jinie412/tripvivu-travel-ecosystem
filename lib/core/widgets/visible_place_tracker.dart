import 'dart:async';

import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'package:travel_advisor_mobile/core/di/injection_container.dart';
import 'package:travel_advisor_mobile/core/services/activity_service.dart';

/// Wrap bất kỳ card POI nào để tự động log `view`
/// khi >= 50% widget hiển thị trong viewport liên tục >= 2 giây.
class VisiblePlaceTracker extends StatefulWidget {
  final String placeId;
  final Widget child;

  const VisiblePlaceTracker({
    super.key,
    required this.placeId,
    required this.child,
  });

  @override
  State<VisiblePlaceTracker> createState() => _VisiblePlaceTrackerState();
}

class _VisiblePlaceTrackerState extends State<VisiblePlaceTracker> {
  Timer? _timer;
  bool _tracked = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    if (_tracked) return;

    if (info.visibleFraction >= 0.5) {
      _timer ??= Timer(const Duration(seconds: 2), () {
        if (!mounted || _tracked) return;
        sl<ActivityService>().trackView(widget.placeId);
        _tracked = true;
      });
    } else {
      _timer?.cancel();
      _timer = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key('vpt_${widget.placeId}'),
      onVisibilityChanged: _onVisibilityChanged,
      child: widget.child,
    );
  }
}
