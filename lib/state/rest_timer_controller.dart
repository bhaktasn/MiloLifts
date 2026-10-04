import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/notifications.dart';
import 'app_controller.dart';

class RestTimerState {
  const RestTimerState({this.startedAt, this.setKey, this.lastSetFailed = false});

  final DateTime? startedAt;

  /// Which set started the timer, so re-tapping it (5 → 4) keeps the clock.
  final String? setKey;
  final bool lastSetFailed;

  bool get running => startedAt != null;
}

final restTimerProvider =
    NotifierProvider<RestTimerController, RestTimerState>(
        RestTimerController.new);

/// Count-up rest timer. Runs until the next set is logged or it is dismissed.
class RestTimerController extends Notifier<RestTimerState> {
  @override
  RestTimerState build() => const RestTimerState();

  void start({required String setKey, required bool lastSetFailed}) {
    final now = DateTime.now();
    final keep = state.running && state.setKey == setKey;
    final startedAt = keep ? state.startedAt! : now;
    state = RestTimerState(
        startedAt: startedAt, setKey: setKey, lastSetFailed: lastSetFailed);

    final settings = ref.read(appProvider).settings;
    final elapsed = now.difference(startedAt);
    Duration remaining(int sec) {
      final d = Duration(seconds: sec) - elapsed;
      return d.isNegative ? Duration.zero : d;
    }

    RestNotifications.instance.schedule(
      short: remaining(settings.restShortSec),
      long: remaining(settings.restLongSec),
      shortLabel: Duration(seconds: settings.restShortSec),
      longLabel: Duration(seconds: settings.restLongSec),
      lastSetFailed: lastSetFailed,
    );
  }

  void stop() {
    state = const RestTimerState();
    RestNotifications.instance.cancel();
  }
}
