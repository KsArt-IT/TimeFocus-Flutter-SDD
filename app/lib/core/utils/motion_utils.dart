import 'package:flutter/widgets.dart';

/// Whether decorative motion (pulsing/blinking indicators) should play.
/// Respects the OS-level reduce-motion accessibility setting (FR-047).
bool shouldAnimate(BuildContext context) => !MediaQuery.of(context).disableAnimations;
