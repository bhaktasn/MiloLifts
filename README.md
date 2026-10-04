# MiloLifts

A personal StrongLifts-style 5×5 tracker for Android, built with Flutter.

## Program

Workouts rotate Day 1 → Day 2 → Day 3, regardless of calendar day.

| Day | Exercises |
|---|---|
| 1 | Belt Squat 5×5 · DB Chest Press 5×5 · Weighted Pull-up 5×5 |
| 2 | Sled 3 pushes · Weighted Dips 5×5 · Weighted Pull-up 5×5 · Machine Deadlift 1×5 (optional) |
| 3 | Belt Squat 5×5 · DB Overhead Press 5×5 · Weighted Pull-up 5×5 |

Progression (all sets hit = success):

- Belt squat, sled, deadlift: +10 lb
- DB presses: +2.5 lb per dumbbell
- Pull-ups, dips: +2.5 lb added weight. Pull-ups start with 3 bodyweight sessions.
- Missed reps: repeat the weight. Three misses in a row: deload 10%.

The program table lives in `lib/program/program.dart` and the rules in `lib/logic/progression.dart`.

## Using it

- Tap a circle when you finish a set to log full reps. Tap again to lower the count (5 → 4 → … → 0 → empty).
- Logging a set starts the rest timer. It vibrates and notifies at 1:30 ("go if easy") and 3:00 ("go if hard"), even with the phone locked.
- Tap an exercise's weight to change it for today only. Settings changes the ongoing weights.

## Brand

The mark is a calf-bearer (after the Moschophoros statue and Milo of Croton, who carried a calf every day as it grew into a bull). It's drawn in black-figure pottery colours: terracotta `#D2693C` on warm black `#121110`, with bone `#EDE4D6` text.

- `assets/brand/milo_badge.svg`: primary badge, also used for the launcher icon and splash
- `assets/brand/milo_badge_ink.svg`: inverse badge for quiet placements
- `lib/ui/brand.dart`: palette, theme, wordmark and the Greek-key band
- Fonts: Barlow and Barlow Condensed (SIL OFL, `assets/fonts/OFL.txt`)

## Development

```sh
flutter test
flutter build apk --debug    # build/app/outputs/flutter-apk/app-debug.apk
flutter run                  # with the phone connected over USB debugging
```
