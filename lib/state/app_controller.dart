import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/storage.dart';
import '../logic/progression.dart';
import '../models/app_data.dart';
import '../models/exercise_state.dart';
import '../models/session.dart';
import '../program/program.dart';

/// Overridden in `main` once the storage file is opened.
final storageProvider = Provider<Storage>((ref) => throw UnimplementedError());

/// Overridden in `main` with the data loaded from disk.
final initialDataProvider =
    Provider<AppData>((ref) => throw UnimplementedError());

final appProvider = NotifierProvider<AppController, AppData>(AppController.new);

class AppController extends Notifier<AppData> {
  @override
  AppData build() => ref.read(initialDataProvider);

  void _set(AppData data) {
    state = data;
    ref.read(storageProvider).save(data);
  }

  void completeOnboarding(Map<String, double> startWeights) {
    _set(state.copyWith(onboarded: true, states: initialStates(startWeights)));
  }

  // ---- Active workout ----

  Session startWorkout() {
    final existing = state.activeSession;
    if (existing != null) return existing;
    final day = state.nextDay;
    final session = Session(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      date: DateTime.now(),
      day: day,
      entries: [
        for (final id in programDays[day])
          SessionEntry(
            exerciseId: id,
            weight: plannedWeight(state.states[id]!),
            sets: List.filled(exercises[id]!.sets, null),
            skipped: exercises[id]!.optional && !state.settings.includeDeadlift,
          ),
      ],
    );
    _set(state.copyWith(activeSession: session));
    return session;
  }

  void _updateActive(Session Function(Session) f) {
    final s = state.activeSession;
    if (s == null) return;
    _set(state.copyWith(activeSession: f(s)));
  }

  /// Cycles a rep circle and returns its new value.
  int? tapSet(int entryIndex, int setIndex) {
    final entry = state.activeSession!.entries[entryIndex];
    final value =
        nextSetValue(entry.sets[setIndex], exercises[entry.exerciseId]!);
    final sets = [...entry.sets]..[setIndex] = value;
    _updateActive((s) => s.updateEntry(entryIndex, entry.copyWith(sets: sets)));
    return value;
  }

  void setEntryWeight(int entryIndex, double weight) => _updateActive((s) =>
      s.updateEntry(entryIndex, s.entries[entryIndex].copyWith(weight: weight)));

  void setSkipped(int entryIndex, bool skipped) => _updateActive((s) => s
      .updateEntry(entryIndex, s.entries[entryIndex].copyWith(skipped: skipped)));

  void setNote(String note) => _updateActive((s) => s.copyWith(note: note));

  void discardWorkout() => _set(state.copyWith(clearActiveSession: true));

  /// Saves the active workout and applies progression.
  List<ExerciseResult> finishWorkout() {
    final session = state.activeSession!.copyWith(date: DateTime.now());
    final applied = applySession(state.states, session);
    _set(state.copyWith(
      states: applied.states,
      sessions: [...state.sessions, session],
      nextDay: (session.day + 1) % programDays.length,
      clearActiveSession: true,
    ));
    return applied.results;
  }

  // ---- History ----

  /// Edits a past session. Progression is not recomputed.
  void updateSession(Session session) => _set(state.copyWith(sessions: [
        for (final s in state.sessions) s.id == session.id ? session : s,
      ]));

  void deleteSession(String id) => _set(state.copyWith(
      sessions: state.sessions.where((s) => s.id != id).toList()));

  // ---- Settings ----

  void updateExerciseState(String id, ExerciseState s) =>
      _set(state.copyWith(states: {...state.states, id: s}));

  void updateSettings(AppSettings settings) =>
      _set(state.copyWith(settings: settings));

  void setNextDay(int day) => _set(state.copyWith(nextDay: day));

  String exportJson() =>
      const JsonEncoder.withIndent(' ').convert(state.toJson());

  /// Replaces all data with a backup. Throws if the JSON is invalid.
  void importJson(String json) {
    final data = AppData.fromJson(jsonDecode(json) as Map<String, dynamic>);
    _set(data);
  }
}
