import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../logic/format.dart';
import '../../logic/progression.dart';
import '../../models/exercise_def.dart';
import '../../models/session.dart';
import '../../program/program.dart';
import '../../state/app_controller.dart';
import 'session_detail_screen.dart';

String setsSummary(SessionEntry e, ExerciseDef def) {
  if (e.skipped || !e.anyLogged) return 'skipped';
  if (def.kind == SetKind.done) {
    return '${e.sets.where((s) => s != null && s > 0).length}/${e.sets.length} pushes';
  }
  return e.sets.map((s) => s?.toString() ?? '–').join('/');
}

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(appProvider.select((d) => d.sessions));
    return Scaffold(
      appBar: AppBar(title: const Text('HISTORY')),
      body: sessions.isEmpty
          ? const Center(child: Text('No workouts yet.'))
          : ListView.builder(
              itemCount: sessions.length,
              itemBuilder: (context, i) {
                final s = sessions[sessions.length - 1 - i];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: ListTile(
                    title: Text('${fmtDate(s.date)} · ${dayName(s.day)}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final e in s.entries)
                          _EntryLine(entry: e, def: exercises[e.exerciseId]!),
                      ],
                    ),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => SessionDetailScreen(sessionId: s.id))),
                  ),
                );
              },
            ),
    );
  }
}

class _EntryLine extends StatelessWidget {
  const _EntryLine({required this.entry, required this.def});

  final SessionEntry entry;
  final ExerciseDef def;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final done = countsAsDone(entry);
    final ok = isSuccess(entry, def);
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Icon(
            !done ? Icons.remove : (ok ? Icons.check : Icons.close),
            size: 14,
            color: !done
                ? theme.disabledColor
                : ok
                    ? theme.colorScheme.primary
                    : theme.colorScheme.error,
          ),
          const SizedBox(width: 6),
          Expanded(child: Text(def.name)),
          if (done) Text(fmtWeight(entry.weight, def.loadType)),
          const SizedBox(width: 8),
          SizedBox(
            width: 90,
            child: Text(setsSummary(entry, def),
                textAlign: TextAlign.right,
                style: theme.textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}
