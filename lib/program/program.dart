import '../models/exercise_def.dart';

/// Pull-up sessions done at bodyweight before adding load (the first week).
const pullupBodyweightSessions = 3;

const exercises = <String, ExerciseDef>{
  'belt_squat': ExerciseDef(
    id: 'belt_squat',
    name: 'Belt Squat',
    sets: 5,
    reps: 5,
    defaultIncrement: 10,
    defaultStartWeight: 90,
    loadType: LoadType.total,
  ),
  'db_chest_press': ExerciseDef(
    id: 'db_chest_press',
    name: 'DB Chest Press',
    sets: 5,
    reps: 5,
    defaultIncrement: 2.5,
    defaultStartWeight: 30,
    loadType: LoadType.perDumbbell,
  ),
  'pullup': ExerciseDef(
    id: 'pullup',
    name: 'Weighted Pull-up',
    sets: 5,
    reps: 5,
    defaultIncrement: 2.5,
    defaultStartWeight: 0,
    loadType: LoadType.added,
  ),
  'sled': ExerciseDef(
    id: 'sled',
    name: 'Sled',
    sets: 3,
    reps: 1,
    defaultIncrement: 10,
    defaultStartWeight: 90,
    loadType: LoadType.total,
    kind: SetKind.done,
  ),
  'dips': ExerciseDef(
    id: 'dips',
    name: 'Weighted Dips',
    sets: 5,
    reps: 5,
    defaultIncrement: 2.5,
    defaultStartWeight: 0,
    loadType: LoadType.added,
  ),
  'machine_deadlift': ExerciseDef(
    id: 'machine_deadlift',
    name: 'Machine Deadlift',
    sets: 1,
    reps: 5,
    defaultIncrement: 10,
    defaultStartWeight: 135,
    loadType: LoadType.total,
    optional: true,
  ),
  'db_ohp': ExerciseDef(
    id: 'db_ohp',
    name: 'DB Overhead Press',
    sets: 5,
    reps: 5,
    defaultIncrement: 2.5,
    defaultStartWeight: 20,
    loadType: LoadType.perDumbbell,
  ),
};

/// Exercise ids for each training day, rotated in order.
const programDays = <List<String>>[
  ['belt_squat', 'db_chest_press', 'pullup'],
  ['sled', 'dips', 'pullup', 'machine_deadlift'],
  ['belt_squat', 'db_ohp', 'pullup'],
];

/// The lifts this program is built around; shown first on the progress screen.
const focusExercises = ['pullup', 'belt_squat'];

String dayName(int day) => 'Day ${day + 1}';

String dayTitle(int day) => switch (day) {
      0 => 'Squat · Chest Press · Pull-ups',
      1 => 'Sled · Dips · Pull-ups',
      _ => 'Squat · Overhead Press · Pull-ups',
    };
