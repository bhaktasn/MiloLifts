import 'exercise_state.dart';
import 'session.dart';

class AppSettings {
  const AppSettings({
    this.restShortSec = 90,
    this.restLongSec = 180,
    this.keepScreenOn = true,
    this.includeDeadlift = true,
  });

  final int restShortSec;
  final int restLongSec;
  final bool keepScreenOn;

  /// Whether the optional machine deadlift starts un-skipped on sled day.
  final bool includeDeadlift;

  AppSettings copyWith({
    int? restShortSec,
    int? restLongSec,
    bool? keepScreenOn,
    bool? includeDeadlift,
  }) =>
      AppSettings(
        restShortSec: restShortSec ?? this.restShortSec,
        restLongSec: restLongSec ?? this.restLongSec,
        keepScreenOn: keepScreenOn ?? this.keepScreenOn,
        includeDeadlift: includeDeadlift ?? this.includeDeadlift,
      );

  Map<String, dynamic> toJson() => {
        'restShortSec': restShortSec,
        'restLongSec': restLongSec,
        'keepScreenOn': keepScreenOn,
        'includeDeadlift': includeDeadlift,
      };

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
        restShortSec: j['restShortSec'] as int? ?? 90,
        restLongSec: j['restLongSec'] as int? ?? 180,
        keepScreenOn: j['keepScreenOn'] as bool? ?? true,
        includeDeadlift: j['includeDeadlift'] as bool? ?? true,
      );
}

class AppData {
  const AppData({
    this.onboarded = false,
    this.settings = const AppSettings(),
    this.states = const {},
    this.sessions = const [],
    this.nextDay = 0,
    this.activeSession,
  });

  final bool onboarded;
  final AppSettings settings;
  final Map<String, ExerciseState> states;

  /// Finished sessions, oldest first.
  final List<Session> sessions;
  final int nextDay;
  final Session? activeSession;

  AppData copyWith({
    bool? onboarded,
    AppSettings? settings,
    Map<String, ExerciseState>? states,
    List<Session>? sessions,
    int? nextDay,
    Session? activeSession,
    bool clearActiveSession = false,
  }) =>
      AppData(
        onboarded: onboarded ?? this.onboarded,
        settings: settings ?? this.settings,
        states: states ?? this.states,
        sessions: sessions ?? this.sessions,
        nextDay: nextDay ?? this.nextDay,
        activeSession:
            clearActiveSession ? null : activeSession ?? this.activeSession,
      );

  static const schemaVersion = 1;

  Map<String, dynamic> toJson() => {
        'version': schemaVersion,
        'onboarded': onboarded,
        'settings': settings.toJson(),
        'states': states.map((k, v) => MapEntry(k, v.toJson())),
        'sessions': sessions.map((s) => s.toJson()).toList(),
        'nextDay': nextDay,
        'activeSession': activeSession?.toJson(),
      };

  factory AppData.fromJson(Map<String, dynamic> j) => AppData(
        onboarded: j['onboarded'] as bool? ?? false,
        settings: AppSettings.fromJson(
            (j['settings'] as Map<String, dynamic>?) ?? const {}),
        states: ((j['states'] as Map<String, dynamic>?) ?? const {}).map(
            (k, v) => MapEntry(k, ExerciseState.fromJson(v as Map<String, dynamic>))),
        sessions: ((j['sessions'] as List?) ?? const [])
            .map((e) => Session.fromJson(e as Map<String, dynamic>))
            .toList(),
        nextDay: j['nextDay'] as int? ?? 0,
        activeSession: j['activeSession'] == null
            ? null
            : Session.fromJson(j['activeSession'] as Map<String, dynamic>),
      );
}
