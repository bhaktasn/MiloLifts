import 'package:flutter/material.dart';

import '../../logic/format.dart';
import '../../models/exercise_def.dart';
import '../../models/session.dart';
import '../brand.dart';
import 'rep_circle.dart';

class ExerciseCard extends StatelessWidget {
  const ExerciseCard({
    super.key,
    required this.def,
    required this.entry,
    required this.onTapSet,
    this.onTapWeight,
    this.onSkipChanged,
    this.note,
  });

  final ExerciseDef def;
  final SessionEntry entry;
  final void Function(int setIndex) onTapSet;
  final VoidCallback? onTapWeight;

  /// Shown for optional exercises; receives the new "skipped" value.
  final ValueChanged<bool>? onSkipChanged;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final skipped = entry.skipped;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 10, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(def.name.toUpperCase(),
                          style: theme.textTheme.titleLarge?.copyWith(
                              fontSize: 21, letterSpacing: 0.8, height: 1.1)),
                      Text(
                        def.optional ? '${def.scheme} · optional' : def.scheme,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                if (onSkipChanged != null && def.optional)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Do it', style: theme.textTheme.bodySmall),
                      Switch(
                        value: !skipped,
                        onChanged: (v) => onSkipChanged!(!v),
                      ),
                    ],
                  ),
                TextButton(
                  onPressed: skipped ? null : onTapWeight,
                  child: Text(
                    fmtWeight(entry.weight, def.loadType),
                    style: TextStyle(
                      fontFamily: displayFont,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: skipped
                          ? theme.disabledColor
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            if (note != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(note!,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: MiloColors.ochre)),
              ),
            const SizedBox(height: 12),
            Opacity(
              opacity: skipped ? 0.35 : 1,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (var i = 0; i < entry.sets.length; i++)
                    RepCircle(
                      value: entry.sets[i],
                      target: def.reps,
                      kind: def.kind,
                      onTap: skipped ? null : () => onTapSet(i),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
