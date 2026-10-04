import 'package:intl/intl.dart';

import '../models/exercise_def.dart';

String fmtNum(double w) =>
    w == w.roundToDouble() ? w.toStringAsFixed(0) : w.toStringAsFixed(1);

/// e.g. "135 lb", "25 lb / DB", "+10 lb", "Bodyweight".
String fmtWeight(double w, LoadType type) => switch (type) {
      LoadType.total => '${fmtNum(w)} lb',
      LoadType.perDumbbell => '${fmtNum(w)} lb / DB',
      LoadType.added => w == 0 ? 'Bodyweight' : '+${fmtNum(w)} lb',
    };

String fmtDuration(Duration d) {
  final m = d.inMinutes;
  final s = d.inSeconds % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
}

String fmtDate(DateTime d) => DateFormat('EEE, MMM d').format(d);
