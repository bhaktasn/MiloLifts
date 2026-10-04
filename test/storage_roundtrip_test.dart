import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:milo_lifts/data/storage.dart';
import 'package:milo_lifts/logic/progression.dart';
import 'package:milo_lifts/models/app_data.dart';
import 'package:milo_lifts/models/session.dart';

void main() {
  test('app data survives a save/load round trip', () async {
    final dir = await Directory.systemTemp.createTemp('milo');
    addTearDown(() => dir.delete(recursive: true));
    final storage = Storage(File('${dir.path}/data.json'));

    expect((await storage.load()).onboarded, isFalse);

    final session = Session(
      id: '1',
      date: DateTime(2026, 10, 3, 18),
      day: 1,
      entries: const [
        SessionEntry(exerciseId: 'pullup', weight: 2.5, sets: [5, 5, 4, null, 0]),
        SessionEntry(
            exerciseId: 'machine_deadlift', weight: 135, sets: [null], skipped: true),
      ],
    );
    final data = AppData(
      onboarded: true,
      settings: const AppSettings(restShortSec: 120, keepScreenOn: false),
      states: initialStates({'belt_squat': 95}),
      sessions: [session],
      nextDay: 2,
      activeSession: session,
    );
    await storage.save(data);
    final loaded = await storage.load();

    expect(loaded.toJson(), data.toJson());
    expect(loaded.sessions.single.entries.first.sets, [5, 5, 4, null, 0]);
    expect(loaded.states['belt_squat']!.weight, 95);
    expect(loaded.settings.restShortSec, 120);
  });
}
