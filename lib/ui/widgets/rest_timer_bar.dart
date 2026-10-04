import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../logic/format.dart';
import '../../services/haptics.dart';
import '../../services/notifications.dart';
import '../../state/app_controller.dart';
import '../../state/rest_timer_controller.dart';
import '../brand.dart';

/// Count-up rest timer pinned to the bottom of the workout screen.
class RestTimerBar extends ConsumerStatefulWidget {
  const RestTimerBar({super.key});

  @override
  ConsumerState<RestTimerBar> createState() => _RestTimerBarState();
}

class _RestTimerBarState extends ConsumerState<RestTimerBar> {
  Timer? _ticker;

  /// Highest threshold (in seconds) already alerted for the current rest.
  int _alerted = 0;
  DateTime? _alertedFor;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(milliseconds: 500), (_) => _tick());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _tick() {
    final timer = ref.read(restTimerProvider);
    if (!timer.running) return;
    if (_alertedFor != timer.startedAt) {
      _alertedFor = timer.startedAt;
      _alerted = 0;
    }
    final settings = ref.read(appProvider).settings;
    final elapsed = DateTime.now().difference(timer.startedAt!).inSeconds;
    // OS notifications vibrate on their own; only buzz here as a fallback.
    if (!RestNotifications.instance.enabled) {
      if (elapsed >= settings.restLongSec && _alerted < settings.restLongSec) {
        Haptics.restLong();
        _alerted = settings.restLongSec;
      } else if (!timer.lastSetFailed &&
          elapsed >= settings.restShortSec &&
          _alerted < settings.restShortSec) {
        Haptics.restShort();
        _alerted = settings.restShortSec;
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final timer = ref.watch(restTimerProvider);
    if (!timer.running) return const SizedBox.shrink();
    final settings = ref.watch(appProvider).settings;
    final elapsed = DateTime.now().difference(timer.startedAt!);
    final short = Duration(seconds: settings.restShortSec);
    final long = Duration(seconds: settings.restLongSec);
    final scheme = Theme.of(context).colorScheme;

    final (String message, Color color) = switch (elapsed) {
      _ when timer.lastSetFailed && elapsed < long => (
          'Failed set. Rest ${fmtDuration(long)}–5:00.',
          scheme.error
        ),
      _ when elapsed >= long => (
          '${fmtDuration(long)} up. Go time.',
          MiloColors.olive
        ),
      _ when elapsed >= short => (
          '${fmtDuration(short)} up. Go now if the last set was easy.',
          MiloColors.ochre
        ),
      _ => (
          'Rest ${fmtDuration(short)} if easy, ${fmtDuration(long)} if hard.',
          MiloColors.boneMuted
        ),
    };
    final onColor = scheme.onSurface;

    return Material(
      color: Color.alphaBlend(
          color.withValues(alpha: 0.14), scheme.surfaceContainerHigh),
      shape: Border(top: BorderSide(color: color, width: 3)),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
          child: Row(
            children: [
              Text(
                fmtDuration(elapsed),
                style: TextStyle(
                  fontFamily: displayFont,
                  fontSize: 40,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  color: color,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(message,
                    style: TextStyle(
                        color: onColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
              ),
              IconButton(
                tooltip: 'Dismiss timer',
                onPressed: () => ref.read(restTimerProvider.notifier).stop(),
                icon: Icon(Icons.close, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
