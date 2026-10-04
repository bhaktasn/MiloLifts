class SessionEntry {
  const SessionEntry({
    required this.exerciseId,
    required this.weight,
    required this.sets,
    this.skipped = false,
  });

  final String exerciseId;
  final double weight;

  /// Reps completed per set; `null` means the set hasn't been logged.
  final List<int?> sets;
  final bool skipped;

  bool get anyLogged => sets.any((s) => s != null);

  SessionEntry copyWith({double? weight, List<int?>? sets, bool? skipped}) =>
      SessionEntry(
        exerciseId: exerciseId,
        weight: weight ?? this.weight,
        sets: sets ?? this.sets,
        skipped: skipped ?? this.skipped,
      );

  Map<String, dynamic> toJson() => {
        'exerciseId': exerciseId,
        'weight': weight,
        'sets': sets,
        'skipped': skipped,
      };

  factory SessionEntry.fromJson(Map<String, dynamic> j) => SessionEntry(
        exerciseId: j['exerciseId'] as String,
        weight: (j['weight'] as num).toDouble(),
        sets: (j['sets'] as List).map((e) => e as int?).toList(),
        skipped: j['skipped'] as bool? ?? false,
      );
}

class Session {
  const Session({
    required this.id,
    required this.date,
    required this.day,
    required this.entries,
    this.note = '',
  });

  final String id;
  final DateTime date;

  /// 0-based index into the program's days.
  final int day;
  final List<SessionEntry> entries;
  final String note;

  Session copyWith({List<SessionEntry>? entries, String? note, DateTime? date}) =>
      Session(
        id: id,
        date: date ?? this.date,
        day: day,
        entries: entries ?? this.entries,
        note: note ?? this.note,
      );

  Session updateEntry(int index, SessionEntry entry) {
    final list = [...entries];
    list[index] = entry;
    return copyWith(entries: list);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'day': day,
        'entries': entries.map((e) => e.toJson()).toList(),
        'note': note,
      };

  factory Session.fromJson(Map<String, dynamic> j) => Session(
        id: j['id'] as String,
        date: DateTime.parse(j['date'] as String),
        day: j['day'] as int,
        entries: (j['entries'] as List)
            .map((e) => SessionEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
        note: j['note'] as String? ?? '',
      );
}
