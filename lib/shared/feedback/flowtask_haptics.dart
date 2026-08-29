import 'package:flutter/services.dart';

abstract final class FlowTaskHaptics {
  static Future<void> selection() {
    return HapticFeedback.selectionClick();
  }

  static Future<void> light() {
    return HapticFeedback.lightImpact();
  }

  static Future<void> medium() {
    return HapticFeedback.mediumImpact();
  }

  static Future<void> success() {
    return HapticFeedback.lightImpact();
  }

  static Future<void> destructive() {
    return HapticFeedback.mediumImpact();
  }
}
