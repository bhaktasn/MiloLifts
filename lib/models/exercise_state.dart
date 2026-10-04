class ExerciseState {
  const ExerciseState({
    required this.weight,
    required this.increment,
    this.failStreak = 0,
    this.bodyweightSessionsRemaining = 0,
  });

  /// Weight to use next session.
  final double weight;
  final double increment;

  /// Consecutive failed sessions at the current weight.
  final int failStreak;

  /// Sessions left that must be done with no added load and no progression.
  final int bodyweightSessionsRemaining;

  ExerciseState copyWith({
    double? weight,
    double? increment,
    int? failStreak,
    int? bodyweightSessionsRemaining,
  }) =>
      ExerciseState(
        weight: weight ?? this.weight,
        increment: increment ?? this.increment,
        failStreak: failStreak ?? this.failStreak,
        bodyweightSessionsRemaining:
            bodyweightSessionsRemaining ?? this.bodyweightSessionsRemaining,
      );

  Map<String, dynamic> toJson() => {
        'weight': weight,
        'increment': increment,
        'failStreak': failStreak,
        'bodyweightSessionsRemaining': bodyweightSessionsRemaining,
      };

  factory ExerciseState.fromJson(Map<String, dynamic> j) => ExerciseState(
        weight: (j['weight'] as num).toDouble(),
        increment: (j['increment'] as num).toDouble(),
        failStreak: j['failStreak'] as int? ?? 0,
        bodyweightSessionsRemaining:
            j['bodyweightSessionsRemaining'] as int? ?? 0,
      );

  @override
  bool operator ==(Object other) =>
      other is ExerciseState &&
      other.weight == weight &&
      other.increment == increment &&
      other.failStreak == failStreak &&
      other.bodyweightSessionsRemaining == bodyweightSessionsRemaining;

  @override
  int get hashCode =>
      Object.hash(weight, increment, failStreak, bodyweightSessionsRemaining);

  @override
  String toString() =>
      'ExerciseState(weight: $weight, inc: $increment, fails: $failStreak, bw: $bodyweightSessionsRemaining)';
}
