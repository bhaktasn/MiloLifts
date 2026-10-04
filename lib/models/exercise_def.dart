/// How an exercise's weight is shown and understood.
enum LoadType {
  /// Total load on the machine / sled.
  total,

  /// Weight of each dumbbell.
  perDumbbell,

  /// Weight added on top of bodyweight (belt / vest).
  added,
}

/// What a single set records.
enum SetKind {
  /// A rep count; circles cycle target → target-1 … → 0 → empty.
  reps,

  /// A single push / length; circles toggle done ↔ empty.
  done,
}

class ExerciseDef {
  const ExerciseDef({
    required this.id,
    required this.name,
    required this.sets,
    required this.reps,
    required this.defaultIncrement,
    required this.defaultStartWeight,
    required this.loadType,
    this.kind = SetKind.reps,
    this.optional = false,
  });

  final String id;
  final String name;
  final int sets;
  final int reps;
  final double defaultIncrement;
  final double defaultStartWeight;
  final LoadType loadType;
  final SetKind kind;
  final bool optional;

  String get scheme => kind == SetKind.done ? '$sets pushes' : '$sets×$reps';
}
