import 'dart:async';

import 'package:flutter/material.dart';
import 'package:timefocus/core/utils/time_guard.dart';

/// Rebuilds once per second; elapsed is always recomputed from wall clock
/// (no background process): accumulated + (active ? now − startedAt : 0).
class TickingTimer extends StatefulWidget {
  const TickingTimer({
    required this.startedAt,
    required this.accumulatedSec,
    required this.isActive,
    this.style,
    super.key,
  });

  final DateTime startedAt;
  final int accumulatedSec;
  final bool isActive;
  final TextStyle? style;

  @override
  State<TickingTimer> createState() => _TickingTimerState();
}

class _TickingTimerState extends State<TickingTimer> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _syncTimer();
  }

  @override
  void didUpdateWidget(TickingTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncTimer();
  }

  void _syncTimer() {
    _timer?.cancel();
    if (widget.isActive) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  int get _elapsedSec {
    final live = widget.isActive ? DateTime.now().secondsSince(widget.startedAt) : 0;
    final total = widget.accumulatedSec + live;
    return total < 0 ? 0 : total;
  }

  @override
  Widget build(BuildContext context) {
    return Text(formatDuration(_elapsedSec), style: widget.style);
  }
}

/// h:mm:ss (or m:ss below an hour).
String formatDuration(int totalSec) {
  final h = totalSec ~/ 3600;
  final m = (totalSec % 3600) ~/ 60;
  final s = totalSec % 60;
  String two(int v) => v.toString().padLeft(2, '0');
  return '$h:${two(m)}:${two(s)}';
}
