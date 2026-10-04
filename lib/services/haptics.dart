import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

class Haptics {
  static Future<void> tap() => HapticFeedback.lightImpact();

  static Future<void> restShort() => _vibrate([0, 300, 150, 300]);

  static Future<void> restLong() => _vibrate([0, 700, 200, 700, 200, 700]);

  static Future<void> _vibrate(List<int> pattern) async {
    try {
      if (await Vibration.hasVibrator()) {
        await Vibration.vibrate(pattern: pattern);
      }
    } catch (_) {}
  }
}
