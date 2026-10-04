import 'package:flutter_test/flutter_test.dart';
import 'package:milo_lifts/logic/progression.dart';
import 'package:milo_lifts/models/exercise_state.dart';
import 'package:milo_lifts/models/session.dart';
import 'package:milo_lifts/program/program.dart';

SessionEntry entry(String id, double weight, List<int?> sets,
        {bool skipped = false}) =>
    SessionEntry(exerciseId: id, weight: weight, sets: sets, skipped: skipped);

Session session(int day, List<SessionEntry> entries) =>
    Session(id: 'x', date: DateTime(2026), day: day, entries: entries);

const all5 = [5, 5, 5, 5, 5];
const missed = [5, 5, 5, 4, 3];

/// Runs a session with every exercise for [day] at its planned weight.
Map<String, ExerciseState> runDay(
  Map<String, ExerciseState> states,
  int day, {
  Map<String, List<int?>> sets = const {},
  Set<String> skip = const {},
}) {
  final s = session(day, [
    for (final id in programDays[day])
      entry(
        id,
        plannedWeight(states[id]!),
        sets[id] ??
            List.filled(exercises[id]!.sets, exercises[id]!.reps),
        skipped: skip.contains(id),
      ),
  ]);
  return applySession(states, s).states;
}

void main() {
  final start = initialStates({
    'belt_squat': 100,
    'db_chest_press': 30,
    'db_ohp': 20,
    'pullup': 0,
    'dips': 0,
    'sled': 90,
    'machine_deadlift': 135,
  });

  test('pull-ups: 3 bodyweight sessions, then +2.5 per session', () {
    var s = start;
    final planned = <double>[];
    for (var i = 0; i < 6; i++) {
      planned.add(plannedWeight(s['pullup']!));
      s = runDay(s, i % 3);
    }
    expect(planned, [0, 0, 0, 2.5, 5.0, 7.5]);
    expect(s['pullup']!.bodyweightSessionsRemaining, 0);
  });

  test('pull-ups with a starting load skip the bodyweight week', () {
    final s = initialStates({'pullup': 10});
    expect(s['pullup']!.bodyweightSessionsRemaining, 0);
    expect(plannedWeight(s['pullup']!), 10);
  });

  test('failing during the bodyweight week still counts the session', () {
    var s = runDay(start, 0, sets: {'pullup': missed});
    expect(s['pullup']!.bodyweightSessionsRemaining, 2);
    expect(s['pullup']!.failStreak, 0);
  });

  test('belt squat +10 shared between day 1 and day 3', () {
    var s = start;
    s = runDay(s, 0);
    expect(s['belt_squat']!.weight, 110);
    s = runDay(s, 1);
    expect(s['belt_squat']!.weight, 110, reason: 'not trained on day 2');
    s = runDay(s, 2);
    expect(s['belt_squat']!.weight, 120);
  });

  test('dumbbell presses add 2.5 per dumbbell, each tracked separately', () {
    var s = runDay(start, 0);
    expect(s['db_chest_press']!.weight, 32.5);
    expect(s['db_ohp']!.weight, 20);
    s = runDay(s, 2);
    expect(s['db_ohp']!.weight, 22.5);
  });

  test('missed reps repeat the weight, 3 in a row deload 10%', () {
    var s = start;
    for (var i = 0; i < 2; i++) {
      s = runDay(s, 0, sets: {'belt_squat': missed});
      expect(s['belt_squat']!.weight, 100);
      expect(s['belt_squat']!.failStreak, i + 1);
    }
    s = runDay(s, 0, sets: {'belt_squat': missed});
    expect(s['belt_squat']!.weight, 90);
    expect(s['belt_squat']!.failStreak, 0);
  });

  test('success resets the fail streak', () {
    var s = runDay(start, 0, sets: {'belt_squat': missed});
    s = runDay(s, 0);
    expect(s['belt_squat']!.failStreak, 0);
    expect(s['belt_squat']!.weight, 110);
  });

  test('unlogged sets count as missed', () {
    final s = runDay(start, 0, sets: {'belt_squat': [5, 5, 5, null, null]});
    expect(s['belt_squat']!.failStreak, 1);
  });

  test('deload rounds down to the increment step', () {
    expect(deload(32.5, 2.5), 27.5); // 29.25 -> 27.5
    expect(deload(2.5, 2.5), 0);
    expect(deload(135, 10), 120); // 121.5 -> 120
  });

  test('skipped deadlift is unchanged; done deadlift +10', () {
    var s = runDay(start, 1, skip: {'machine_deadlift'});
    expect(s['machine_deadlift'], start['machine_deadlift']);
    s = runDay(s, 1);
    expect(s['machine_deadlift']!.weight, 145);
  });

  test('exercise with no sets logged is treated as skipped', () {
    final s = runDay(start, 1, sets: {'dips': [null, null, null, null, null]});
    expect(s['dips'], start['dips']);
  });

  test('sled: 3 pushes done adds 10, a missed push repeats', () {
    var s = runDay(start, 1);
    expect(s['sled']!.weight, 100);
    s = runDay(s, 1, sets: {'sled': [1, 1, null]});
    expect(s['sled']!.weight, 100);
    expect(s['sled']!.failStreak, 1);
  });

  test('progression uses the weight actually lifted', () {
    final s = applySession(start, session(0, [
      entry('belt_squat', 150, all5),
    ])).states;
    expect(s['belt_squat']!.weight, 160);
  });
}
