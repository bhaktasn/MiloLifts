import 'package:flutter/material.dart';

import '../../models/exercise_def.dart';
import '../brand.dart';

/// A StrongLifts-style set circle. Empty until tapped, then shows reps done.
class RepCircle extends StatelessWidget {
  const RepCircle({
    super.key,
    required this.value,
    required this.target,
    required this.kind,
    this.onTap,
    this.size = 56,
  });

  final int? value;
  final int target;
  final SetKind kind;
  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final v = value;
    final success = v != null && v >= target;
    final failed = v != null && v < target;

    final Color fill;
    final Color border;
    final Color textColor;
    if (success) {
      fill = scheme.primary;
      border = scheme.primary;
      textColor = scheme.onPrimary;
    } else if (failed) {
      fill = Colors.transparent;
      border = scheme.error;
      textColor = scheme.error;
    } else {
      fill = scheme.surfaceContainerHighest;
      border = scheme.surfaceContainerHighest;
      textColor = scheme.onSurfaceVariant.withValues(alpha: 0.45);
    }

    final Widget label = switch ((kind, v)) {
      (SetKind.done, null) => Icon(Icons.circle_outlined,
          size: size * 0.35, color: textColor),
      (SetKind.done, final int done) => Icon(
          done > 0 ? Icons.check_rounded : Icons.close_rounded,
          color: textColor,
          size: size * 0.5),
      (SetKind.reps, final int? reps) => Text(
          '${reps ?? target}',
          style: TextStyle(
            fontFamily: displayFont,
            fontSize: size * 0.44,
            fontWeight: FontWeight.w800,
            color: textColor,
          ),
        ),
    };

    return Semantics(
      button: true,
      label: v == null ? 'Set not logged' : '$v reps',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: fill,
            shape: BoxShape.circle,
            border: Border.all(color: border, width: 3),
          ),
          child: label,
        ),
      ),
    );
  }
}
