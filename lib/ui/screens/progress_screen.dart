import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../logic/format.dart';
import '../../logic/progression.dart';
import '../../models/exercise_def.dart';
import '../../models/session.dart';
import '../../program/program.dart';
import '../../state/app_controller.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appProvider);
    final order = [
      ...focusExercises,
      ...exercises.keys.where((id) => !focusExercises.contains(id)),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('PROGRESS')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 6),
        children: [
          for (final id in order)
            _ExerciseProgress(
              def: exercises[id]!,
              sessions: data.sessions,
              next: plannedWeight(data.states[id]!),
              focus: focusExercises.contains(id),
            ),
        ],
      ),
    );
  }
}

class _ExerciseProgress extends StatelessWidget {
  const _ExerciseProgress({
    required this.def,
    required this.sessions,
    required this.next,
    required this.focus,
  });

  final ExerciseDef def;
  final List<Session> sessions;
  final double next;
  final bool focus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final points = <({DateTime date, double weight, bool ok})>[
      for (final s in sessions)
        for (final e in s.entries)
          if (e.exerciseId == def.id && countsAsDone(e))
            (date: s.date, weight: e.weight, ok: isSuccess(e, def)),
    ];
    final best = points.where((p) => p.ok).map((p) => p.weight).fold<double?>(
        null, (a, b) => a == null || b > a ? b : a);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(def.name,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ),
                Text('Next: ${fmtWeight(next, def.loadType)}',
                    style: theme.textTheme.bodyMedium),
              ],
            ),
            Text(
              [
                '${points.length} sessions',
                if (best != null) 'best ${fmtWeight(best, def.loadType)}',
              ].join(' · '),
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: focus ? 200 : 130,
              child: points.length < 2
                  ? Center(
                      child: Text('Log a couple of sessions to see a chart.',
                          style: theme.textTheme.bodySmall))
                  : _Chart(points: points),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chart extends StatelessWidget {
  const _Chart({required this.points});

  final List<({DateTime date, double weight, bool ok})> points;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final spots = [
      for (var i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), points[i].weight),
    ];
    final labelStyle = Theme.of(context).textTheme.labelSmall;
    final dateFmt = DateFormat('M/d');
    final step = ((points.length - 1) / 3).ceil().clamp(1, 1000);
    return LineChart(
      LineChartData(
        minY: 0,
        gridData: const FlGridData(drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (v, meta) => SideTitleWidget(
                  meta: meta, child: Text(fmtNum(v), style: labelStyle)),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              reservedSize: 22,
              getTitlesWidget: (v, meta) {
                final i = v.round();
                if (i < 0 ||
                    i >= points.length ||
                    v != i.toDouble() ||
                    i % step != 0) {
                  return const SizedBox.shrink();
                }
                return SideTitleWidget(
                    meta: meta,
                    child: Text(dateFmt.format(points[i].date),
                        style: labelStyle));
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            color: scheme.primary,
            barWidth: 3,
            dotData: FlDotData(
              getDotPainter: (spot, _, _, i) => FlDotCirclePainter(
                radius: 3.5,
                color: points[i].ok ? scheme.primary : scheme.surface,
                strokeColor: points[i].ok ? scheme.primary : scheme.error,
                strokeWidth: 2,
              ),
            ),
            belowBarData: BarAreaData(
                show: true, color: scheme.primary.withValues(alpha: 0.12)),
          ),
        ],
      ),
    );
  }
}
