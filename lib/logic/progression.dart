import '../models/exercise_def.dart';
import '../models/exercise_state.dart';
import '../models/session.dart';
import '../program/program.dart';

/// Failed sessions in a row at one weight before a deload.
const failuresBeforeDeload = 3;

/// Fraction of the weight kept after a deload.
const deloadFactor = 0.9;

/// What a rep circle shows after being tapped.
///
/// Reps: empty → target → target-1 → … → 0 → empty.
/// Done: empty → done → empty.
int? nextSetValue(int? current, ExerciseDef def) {
  if (current == null) return def.reps;
  if (def.kind == SetKind.done || current == 0) return null;
  return current - 1;
}

enum Outcome { success, failure, skipped, bodyweight }

/// An entry counts only if it wasn't skipped and at least one set was logged.
bool countsAsDone(SessionEntry e) => !e.skipped && e.anyLogged;

bool isSuccess(SessionEntry e, ExerciseDef def) =>
    countsAsDone(e) && e.sets.every((s) => s != null && s >= def.reps);

double deload(double weight, double increment) {
  final reduced = weight * deloadFactor;
  final stepped =
      increment > 0 ? (reduced / increment).floor() * increment : reduced;
  return stepped < 0 ? 0 : stepped;
}

/// Result of finishing one exercise in a session.
class ExerciseResult {
  const ExerciseResult(this.exerciseId, this.outcome, this.before, this.after);
  final String exerciseId;
  final Outcome outcome;
  final ExerciseState before;
  final ExerciseState after;

  bool get deloaded => after.weight < before.weight;
}

ExerciseResult progress(ExerciseState state, SessionEntry entry, ExerciseDef def) {
  if (!countsAsDone(entry)) {
    return ExerciseResult(def.id, Outcome.skipped, state, state);
  }
  if (state.bodyweightSessionsRemaining > 1) {
    final after = state.copyWith(
      bodyweightSessionsRemaining: state.bodyweightSessionsRemaining - 1,
      failStreak: 0,
    );
    return ExerciseResult(def.id, Outcome.bodyweight, state, after);
  }
  if (state.bodyweightSessionsRemaining == 1) {
    // Last bodyweight session: progress normally from here on.
    final r = progress(state.copyWith(bodyweightSessionsRemaining: 0), entry, def);
    return ExerciseResult(def.id, r.outcome, state, r.after);
  }
  // Progress from what was actually lifted today (it may have been overridden).
  final lifted = entry.weight;
  if (isSuccess(entry, def)) {
    final after = state.copyWith(weight: lifted + state.increment, failStreak: 0);
    return ExerciseResult(def.id, Outcome.success, state, after);
  }
  final fails = state.failStreak + 1;
  final after = fails >= failuresBeforeDeload
      ? state.copyWith(weight: deload(lifted, state.increment), failStreak: 0)
      : state.copyWith(weight: lifted, failStreak: fails);
  return ExerciseResult(def.id, Outcome.failure, state, after);
}

/// Applies a finished session to the exercise states.
({Map<String, ExerciseState> states, List<ExerciseResult> results}) applySession(
  Map<String, ExerciseState> states,
  Session session,
) {
  final next = {...states};
  final results = <ExerciseResult>[];
  for (final entry in session.entries) {
    final def = exercises[entry.exerciseId];
    final state = next[entry.exerciseId];
    if (def == null || state == null) continue;
    final r = progress(state, entry, def);
    next[entry.exerciseId] = r.after;
    results.add(r);
  }
  return (states: next, results: results);
}

/// The weight to load today for a given state.
double plannedWeight(ExerciseState state) =>
    state.bodyweightSessionsRemaining > 0 ? 0 : state.weight;

/// Initial states from the user's starting weights.
///
/// Pull-ups get a bodyweight week unless a starting load was entered.
Map<String, ExerciseState> initialStates(Map<String, double> startWeights) => {
      for (final def in exercises.values)
        def.id: () {
          final w = startWeights[def.id] ?? def.defaultStartWeight;
          return ExerciseState(
            weight: w,
            increment: def.defaultIncrement,
            bodyweightSessionsRemaining:
                def.id == 'pullup' && w == 0 ? pullupBodyweightSessions : 0,
          );
        }(),
    };
