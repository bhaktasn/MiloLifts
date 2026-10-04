import 'package:flutter/material.dart';

import '../../logic/format.dart';
import '../../logic/progression.dart';
import '../../models/session.dart';
import '../../program/program.dart';
import '../brand.dart';

class SummaryScreen extends StatelessWidget {
  const SummaryScreen({super.key, required this.session, required this.results});

  final Session session;
  final List<ExerciseResult> results;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gains = results.where((r) => r.outcome == Outcome.success).length;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 32, 16, 24),
          children: [
            const Center(child: MiloBadge(size: 96)),
            const SizedBox(height: 20),
            Center(child: Eyebrow(dayName(session.day))),
            const SizedBox(height: 4),
            Text('WORKOUT COMPLETE',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineLarge
                    ?.copyWith(letterSpacing: 1.5)),
            const SizedBox(height: 8),
            Text(
              gains > 0
                  ? 'The calf got heavier. So did you.'
                  : 'Same calf next time. Carry it again.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 20),
            const MeanderBand(height: 18),
            const SizedBox(height: 20),
            for (final r in results) _ResultTile(result: r),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56)),
              child: const Text('DONE'),
            ),
            const SizedBox(height: 12),
            Text(
                'Next up: ${dayName((session.day + 1) % programDays.length)} · '
                '${dayTitle((session.day + 1) % programDays.length)}',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({required this.result});

  final ExerciseResult result;

  @override
  Widget build(BuildContext context) {
    final def = exercises[result.exerciseId]!;
    final theme = Theme.of(context);
    final next = plannedWeight(result.after);
    final (IconData icon, Color color, String detail) = switch (result.outcome) {
      Outcome.skipped => (Icons.remove_circle_outline, theme.disabledColor,
          'Skipped. Weight unchanged.'),
      Outcome.bodyweight => (
          Icons.check_circle,
          theme.colorScheme.primary,
          'Bodyweight week: ${result.after.bodyweightSessionsRemaining} left.'
        ),
      Outcome.success => (Icons.check_circle, theme.colorScheme.primary,
          'Completed. +${fmtNum(result.after.increment)} lb.'),
      Outcome.failure when result.after.failStreak == 0 => (
          Icons.trending_down,
          theme.colorScheme.error,
          'Missed $failuresBeforeDeload sessions in a row: deload 10%.'
        ),
      Outcome.failure => (
          Icons.cancel,
          theme.colorScheme.error,
          'Missed reps (${result.after.failStreak}/$failuresBeforeDeload). Repeat this weight.'
        ),
    };
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(def.name, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(detail,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Eyebrow('Next', color: MiloColors.boneMuted),
                Text(fmtWeight(next, def.loadType),
                    style: const TextStyle(
                        fontFamily: displayFont,
                        fontWeight: FontWeight.w800,
                        fontSize: 22)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
