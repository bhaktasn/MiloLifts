import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../logic/format.dart';
import '../../logic/progression.dart';
import '../../program/program.dart';
import '../../state/app_controller.dart';
import '../widgets/exercise_card.dart';
import '../widgets/weight_dialog.dart';

/// View or correct a past workout. Edits don't recompute progression; adjust
/// the current weights in Settings if needed.
class SessionDetailScreen extends ConsumerWidget {
  const SessionDetailScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(appProvider
        .select((d) => d.sessions.where((s) => s.id == sessionId).firstOrNull));
    if (session == null) return const Scaffold();
    final controller = ref.read(appProvider.notifier);

    Future<void> delete() async {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete workout?'),
          content: const Text(
              'This removes it from history. Current weights are not changed.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete')),
          ],
        ),
      );
      if (ok == true && context.mounted) {
        Navigator.of(context).pop();
        controller.deleteSession(sessionId);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${dayName(session.day)} · ${fmtDate(session.date)}'),
        actions: [
          IconButton(
              tooltip: 'Delete',
              onPressed: delete,
              icon: const Icon(Icons.delete_outline)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 6),
        children: [
          for (var i = 0; i < session.entries.length; i++)
            Builder(builder: (context) {
              final entry = session.entries[i];
              final def = exercises[entry.exerciseId]!;
              return ExerciseCard(
                def: def,
                entry: entry,
                onTapSet: (s) {
                  final sets = [...entry.sets]
                    ..[s] = nextSetValue(entry.sets[s], def);
                  controller.updateSession(
                      session.updateEntry(i, entry.copyWith(sets: sets)));
                },
                onTapWeight: () async {
                  final w = await showWeightDialog(context,
                      title: def.name,
                      initial: entry.weight,
                      step: def.defaultIncrement);
                  if (w != null) {
                    controller.updateSession(
                        session.updateEntry(i, entry.copyWith(weight: w)));
                  }
                },
                onSkipChanged: (v) => controller.updateSession(
                    session.updateEntry(i, entry.copyWith(skipped: v))),
              );
            }),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Changes here fix the log only. To change upcoming weights, use Settings.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
