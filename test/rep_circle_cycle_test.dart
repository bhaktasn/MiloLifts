import 'package:flutter_test/flutter_test.dart';
import 'package:milo_lifts/logic/progression.dart';
import 'package:milo_lifts/program/program.dart';

void main() {
  test('rep sets cycle empty → 5 → 4 … → 0 → empty', () {
    final def = exercises['belt_squat']!;
    int? v;
    final seen = <int?>[];
    for (var i = 0; i < 7; i++) {
      v = nextSetValue(v, def);
      seen.add(v);
    }
    expect(seen, [5, 4, 3, 2, 1, 0, null]);
  });

  test('sled pushes toggle done ↔ empty', () {
    final def = exercises['sled']!;
    expect(nextSetValue(null, def), 1);
    expect(nextSetValue(1, def), null);
  });
}
