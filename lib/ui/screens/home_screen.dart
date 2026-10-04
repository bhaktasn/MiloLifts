import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../logic/format.dart';
import '../../logic/progression.dart';
import '../../models/app_data.dart';
import '../../models/exercise_def.dart';
import '../../program/program.dart';
import '../../state/app_controller.dart';
import '../brand.dart';
import 'workout_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appProvider);
    final theme = Theme.of(context);
    final active = data.activeSession;
    final day = active?.day ?? data.nextDay;
    final last = data.sessions.isEmpty ? null : data.sessions.last;

    void openWorkout() {
      ref.read(appProvider.notifier).startWorkout();
      Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const WorkoutScreen()));
    }

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            const Row(
              children: [
                MiloBadge(size: 36),
                SizedBox(width: 12),
                Wordmark(size: 24),
              ],
            ),
            const SizedBox(height: 20),
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Eyebrow(active != null ? 'In progress' : 'Next workout'),
                        const SizedBox(height: 4),
                        Text(dayName(day).toUpperCase(),
                            style: theme.textTheme.displayMedium?.copyWith(
                                height: 1, letterSpacing: 1.5)),
                        const SizedBox(height: 4),
                        Text(dayTitle(day),
                            style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant)),
                        const SizedBox(height: 16),
                        for (final id in programDays[day])
                          _PlannedRow(exerciseId: id),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: openWorkout,
                          icon: Icon(active != null
                              ? Icons.play_arrow_rounded
                              : Icons.fitness_center),
                          label: Text(active != null
                              ? 'RESUME WORKOUT'
                              : 'START WORKOUT'),
                          style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(58)),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                  const MeanderBand(height: 18),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Eyebrow('Focus lifts', color: MiloColors.boneMuted),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final id in focusExercises) ...[
                  if (id != focusExercises.first) const SizedBox(width: 12),
                  Expanded(child: _FocusTile(exerciseId: id, data: data)),
                ],
              ],
            ),
            if (last != null) ...[
              const SizedBox(height: 20),
              const Eyebrow('Last workout', color: MiloColors.boneMuted),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${dayName(last.day)} · ${fmtDate(last.date)}',
                          style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final e in last.entries)
                            if (countsAsDone(e))
                              _ResultChip(
                                label: exercises[e.exerciseId]!.name,
                                ok: isSuccess(e, exercises[e.exerciseId]!),
                              ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const MiloBadge(size: 28, ink: true),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    miloStory,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                        height: 1.4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${data.sessions.length} workouts logged',
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _PlannedRow extends ConsumerWidget {
  const _PlannedRow({required this.exerciseId});

  final String exerciseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final def = exercises[exerciseId]!;
    final data = ref.watch(appProvider);
    final theme = Theme.of(context);
    final entry = data.activeSession?.entries
        .where((e) => e.exerciseId == exerciseId)
        .firstOrNull;
    final weight = entry?.weight ?? plannedWeight(data.states[exerciseId]!);
    final off =
        def.optional && (entry?.skipped ?? !data.settings.includeDeadlift);
    final dim = off ? theme.disabledColor : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(
            child: Text(def.optional ? '${def.name} (optional)' : def.name,
                style: theme.textTheme.bodyLarge?.copyWith(color: dim)),
          ),
          Text(def.scheme,
              style: theme.textTheme.bodySmall?.copyWith(
                  color: dim ?? theme.colorScheme.onSurfaceVariant)),
          SizedBox(
            width: 116,
            child: Text(
              fmtWeight(weight, def.loadType),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: displayFont,
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: dim,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Current weight for a focus lift and how far it has come.
class _FocusTile extends StatelessWidget {
  const _FocusTile({required this.exerciseId, required this.data});

  final String exerciseId;
  final AppData data;

  @override
  Widget build(BuildContext context) {
    final def = exercises[exerciseId]!;
    final theme = Theme.of(context);
    final next = plannedWeight(data.states[exerciseId]!);
    final first = data.sessions
        .expand((s) => s.entries)
        .where((e) => e.exerciseId == exerciseId && countsAsDone(e))
        .firstOrNull;
    final gained = first == null ? 0.0 : next - first.weight;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(def.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                fmtWeight(next, def.loadType),
                style: const TextStyle(
                  fontFamily: displayFont,
                  fontWeight: FontWeight.w800,
                  fontSize: 32,
                  height: 1.1,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              gained > 0
                  ? (first!.weight == 0 && def.loadType == LoadType.added
                      ? 'Up from bodyweight'
                      : '+${fmtNum(gained)} lb since day one')
                  : first == null
                      ? 'Starts next session'
                      : 'Building the base',
              style: theme.textTheme.labelSmall?.copyWith(
                color: gained > 0
                    ? MiloColors.terracotta
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultChip extends StatelessWidget {
  const _ResultChip({required this.label, required this.ok});

  final String label;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    final color = ok ? MiloColors.terracotta : MiloColors.fail;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: ok ? color.withValues(alpha: 0.15) : Colors.transparent,
        border: Border.all(color: color.withValues(alpha: ok ? 0 : 0.7)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ok ? Icons.check : Icons.close, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}
