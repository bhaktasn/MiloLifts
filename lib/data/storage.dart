import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/app_data.dart';

/// Persists all app data as a single JSON file.
class Storage {
  Storage(this.file);

  final File file;
  Future<void> _pending = Future.value();

  static Future<Storage> open() async {
    final dir = await getApplicationDocumentsDirectory();
    return Storage(File('${dir.path}/milo_lifts.json'));
  }

  Future<AppData> load() async {
    if (!await file.exists()) return const AppData();
    final text = await file.readAsString();
    if (text.trim().isEmpty) return const AppData();
    return AppData.fromJson(jsonDecode(text) as Map<String, dynamic>);
  }

  /// Writes are serialized and atomic (temp file + rename).
  Future<void> save(AppData data) {
    final json = const JsonEncoder.withIndent(' ').convert(data.toJson());
    return _pending = _pending.then((_) async {
      final tmp = File('${file.path}.tmp');
      await tmp.writeAsString(json, flush: true);
      await tmp.rename(file.path);
    });
  }
}
