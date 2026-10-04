import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../logic/progression.dart';
import '../../models/exercise_state.dart';
import '../../program/program.dart';
import '../../services/haptics.dart';
import '../../state/app_controller.dart';
import '../../state/rest_timer_controller.dart';
import '../widgets/exercise_card.dart';
import '../widgets/rest_timer_bar.dart';
import '../widgets/weight_dialog.dart';
import 'summary_screen.dart';

String? exerciseNote(ExerciseState state) {
  if (state.bodyweightSessionsRemaining > 0) {
    final n = state.bodyweightSessionsRemaining;
    return 'Bodyweight week: $n session${n == 1 ? '' : 's'} left before adding load';
  }
  if (state.failStreak > 0) {
    return 'Missed reps ${state.failStreak}× in a row. '
        '$failuresBeforeDeload in a row deloads 10%.';
  }
  return null;
}

class WorkoutScreen extends ConsumerStatefulWidget {
  const WorkoutScreen({super.key});

  @override
  ConsumerState<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends ConsumerState<WorkoutScreen> {
  @override
  void initState() {
    super.initState();
    if (ref.read(appProvider).settings.keepScreenOn) {
      WakelockPlus.enable().catchError((_) {});
    }
  }

  @override
  void dispose() {
    WakelockPlus.disable().catchError((_) {});
    super.dispose();
  }

  void _tapSet(int entryIndex, int setIndex) {
    final controller = ref.read(appProvider.notifier);
    final entry = ref.read(appProvider).activeSession!.entries[entryIndex];
    final def = exercises[entry.exerciseId]!;
    final value = controller.tapSet(entryIndex, setIndex);
    Haptics.tap();
    if (value != null) {
      ref.read(restTimerProvider.notifier).start(
            setKey: '$entryIndex-$setIndex',
            lastSetFailed: value < def.reps,
          );
    }
  }

  Future<void> _editWeight(int entryIndex) async {
    final data = ref.read(appProvider);
    final entry = data.activeSession!.entries[entryIndex];
    final def = exercises[entry.exerciseId]!;
    final w = await showWeightDialog(
      context,
      title: def.name,
      initial: entry.weight,
      step: data.states[def.id]!.increment,
      helper: "Today's weight only",
    );
    if (w != null) {
      ref.read(appProvider.notifier).setEntryWeight(entryIndex, w);
    }
  }

  Future<bool> _confirm(String title, String body, String action) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true), child: Text(action)),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<void> _finish() async {
    final session = ref.read(appProvider).activeSession!;
    final done = session.entries.where((e) => !e.skipped);
    if (!done.any((e) => e.anyLogged)) {
      if (await _confirm('Nothing logged',
          'No sets were logged. Discard this workout?', 'Discard')) {
        _discard(confirmed: true);
      }
      return;
    }
    final missing = done.any((e) => e.anyLogged && e.sets.contains(null));
    final untouched = done.where((e) => !e.anyLogged).map(
        (e) => exercises[e.exerciseId]!.name);
    if (missing || untouched.isNotEmpty) {
      final lines = [
        if (missing) 'Some sets aren\'t logged and will count as missed.',
        if (untouched.isNotEmpty)
          '${untouched.join(', ')} not started; '
              '${untouched.length == 1 ? 'it' : 'they'} will be skipped.',
      ];
      if (!await _confirm('Finish workout?', lines.join('\n\n'), 'Finish')) {
        return;
      }
    }
    final finished = session;
    final results = ref.read(appProvider.notifier).finishWorkout();
    ref.read(restTimerProvider.notifier).stop();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => SummaryScreen(session: finished, results: results),
    ));
  }

  Future<void> _discard({bool confirmed = false}) async {
    if (!confirmed &&
        !await _confirm('Discard workout?',
            'This workout will be deleted and not count.', 'Discard')) {
      return;
    }
    ref.read(restTimerProvider.notifier).stop();
    ref.read(appProvider.notifier).discardWorkout();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(appProvider);
    final session = data.activeSession;
    if (session == null) return const Scaffold();

    return Scaffold(
      appBar: AppBar(
        title: Text(dayName(session.day).toUpperCase()),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'discard') _discard();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'discard', child: Text('Discard workout')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: 6, bottom: 24),
        children: [
          for (var i = 0; i < session.entries.length; i++)
            ExerciseCard(
              def: exercises[session.entries[i].exerciseId]!,
              entry: session.entries[i],
              note: exerciseNote(data.states[session.entries[i].exerciseId]!),
              onTapSet: (s) => _tapSet(i, s),
              onTapWeight: () => _editWeight(i),
              onSkipChanged: (v) =>
                  ref.read(appProvider.notifier).setSkipped(i, v),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Tap a circle when you finish a set. Tap again to lower the reps.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const RestTimerBar(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: FilledButton(
                onPressed: _finish,
                style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52)),
                child: const Text('FINISH WORKOUT'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
