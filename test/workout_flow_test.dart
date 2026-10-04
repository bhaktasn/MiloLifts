import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milo_lifts/data/storage.dart';
import 'package:milo_lifts/logic/progression.dart';
import 'package:milo_lifts/main.dart';
import 'package:milo_lifts/models/app_data.dart';
import 'package:milo_lifts/state/app_controller.dart';
import 'package:milo_lifts/state/rest_timer_controller.dart';
import 'package:milo_lifts/ui/widgets/rep_circle.dart';

void main() {
  testWidgets('start a workout, tap circles, timer runs, finish progresses',
      (tester) async {
    // Phone-sized viewport (Pixel-like).
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    final dir = Directory.systemTemp.createTempSync('milo');
    addTearDown(() => dir.deleteSync(recursive: true));
    final container = ProviderContainer(overrides: [
      storageProvider.overrideWithValue(Storage(File('${dir.path}/d.json'))),
      initialDataProvider.overrideWithValue(AppData(
        onboarded: true,
        states: initialStates({'belt_squat': 100}),
      )),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
        container: container, child: const MiloLiftsApp()));
    expect(find.text('DAY 1'), findsOneWidget);
    expect(find.text('100 lb'), findsWidgets); // planned row + focus tile

    await tester.tap(find.text('START WORKOUT'));
    await tester.pumpAndSettle();

    // First circle of the belt squat: empty → 5 → 4.
    final firstCircle = find.byType(RepCircle).first;
    await tester.tap(firstCircle);
    await tester.pump();
    var sets = container.read(appProvider).activeSession!.entries[0].sets;
    expect(sets.first, 5);
    expect(container.read(restTimerProvider).running, isTrue);
    expect(container.read(restTimerProvider).lastSetFailed, isFalse);

    await tester.tap(firstCircle);
    await tester.pump();
    sets = container.read(appProvider).activeSession!.entries[0].sets;
    expect(sets.first, 4);
    expect(container.read(restTimerProvider).lastSetFailed, isTrue);
    expect(find.textContaining('Failed set'), findsOneWidget);

    // Mark every set of every exercise as a full set via the controller.
    final controller = container.read(appProvider.notifier);
    final entries = container.read(appProvider).activeSession!.entries;
    for (var i = 0; i < entries.length; i++) {
      for (var j = 0; j < entries[i].sets.length; j++) {
        while (container.read(appProvider).activeSession!.entries[i].sets[j] !=
            5) {
          controller.tapSet(i, j);
        }
      }
    }
    await tester.pump();

    await tester.tap(find.text('FINISH WORKOUT'));
    await tester.pumpAndSettle();
    expect(find.text('WORKOUT COMPLETE'), findsOneWidget);
    expect(find.text('110 lb'), findsOneWidget);
    expect(container.read(restTimerProvider).running, isFalse);

    final data = container.read(appProvider);
    expect(data.sessions, hasLength(1));
    expect(data.nextDay, 1);
    expect(data.activeSession, isNull);
    expect(data.states['pullup']!.bodyweightSessionsRemaining, 2);

    await tester.scrollUntilVisible(find.text('DONE'), 300);
    await tester.ensureVisible(find.text('DONE'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('DONE'));
    await tester.pumpAndSettle();
    expect(find.text('DAY 2'), findsOneWidget);

    // Let the rest-timer ticker be disposed.
    await tester.pumpWidget(const SizedBox());
  });
}
