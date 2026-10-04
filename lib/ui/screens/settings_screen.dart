import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../logic/format.dart';
import '../../logic/progression.dart';
import '../../models/exercise_def.dart';
import '../../models/exercise_state.dart';
import '../../program/program.dart';
import '../../state/app_controller.dart';
import '../brand.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appProvider);
    final controller = ref.read(appProvider.notifier);
    final settings = data.settings;
    final theme = Theme.of(context);

    Widget header(String text) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
          child: Eyebrow(text),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('SETTINGS')),
      body: ListView(
        children: [
          header('Current weights'),
          for (final def in exercises.values)
            ListTile(
              title: Text(def.name),
              subtitle: Text(_stateSummary(data.states[def.id]!)),
              trailing: Text(
                fmtWeight(plannedWeight(data.states[def.id]!), def.loadType),
                style: theme.textTheme.titleSmall,
              ),
              onTap: () async {
                final s = await showDialog<ExerciseState>(
                  context: context,
                  builder: (_) => _ExerciseStateDialog(
                      def: def, state: data.states[def.id]!),
                );
                if (s != null) controller.updateExerciseState(def.id, s);
              },
            ),
          header('Program'),
          ListTile(
            title: const Text('Next workout'),
            subtitle: Text(data.activeSession != null
                ? 'Finish or discard the current workout first'
                : dayTitle(data.nextDay)),
            trailing: SegmentedButton<int>(
              segments: [
                for (var d = 0; d < programDays.length; d++)
                  ButtonSegment(value: d, label: Text('${d + 1}')),
              ],
              selected: {data.nextDay},
              showSelectedIcon: false,
              onSelectionChanged: data.activeSession != null
                  ? null
                  : (s) => controller.setNextDay(s.first),
            ),
          ),
          SwitchListTile(
            title: const Text('Machine deadlift on sled day'),
            subtitle: const Text(
                'Optional 1×5. You can still toggle it during a workout.'),
            value: settings.includeDeadlift,
            onChanged: (v) => controller
                .updateSettings(settings.copyWith(includeDeadlift: v)),
          ),
          header('Rest timer'),
          ListTile(
            title: const Text('Short rest (last set easy)'),
            trailing: Text(fmtDuration(Duration(seconds: settings.restShortSec))),
            onTap: () async {
              final v = await _pickSeconds(
                  context, 'Short rest', settings.restShortSec);
              if (v != null) {
                controller.updateSettings(settings.copyWith(restShortSec: v));
              }
            },
          ),
          ListTile(
            title: const Text('Long rest (last set hard)'),
            trailing: Text(fmtDuration(Duration(seconds: settings.restLongSec))),
            onTap: () async {
              final v =
                  await _pickSeconds(context, 'Long rest', settings.restLongSec);
              if (v != null) {
                controller.updateSettings(settings.copyWith(restLongSec: v));
              }
            },
          ),
          SwitchListTile(
            title: const Text('Keep screen on during workouts'),
            value: settings.keepScreenOn,
            onChanged: (v) =>
                controller.updateSettings(settings.copyWith(keepScreenOn: v)),
          ),
          header('Backup'),
          ListTile(
            leading: const Icon(Icons.upload),
            title: const Text('Export to clipboard'),
            subtitle: const Text('Copies all data as JSON'),
            onTap: () async {
              await Clipboard.setData(
                  ClipboardData(text: controller.exportJson()));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Backup copied')));
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Import from clipboard'),
            subtitle: const Text('Replaces all data'),
            onTap: () => _import(context, controller),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  static String _stateSummary(ExerciseState s) => [
        '+${fmtNum(s.increment)} lb per session',
        if (s.bodyweightSessionsRemaining > 0)
          '${s.bodyweightSessionsRemaining} bodyweight sessions left',
        if (s.failStreak > 0) 'missed ${s.failStreak}/$failuresBeforeDeload',
      ].join(' · ');

  static Future<int?> _pickSeconds(
      BuildContext context, String title, int current) {
    const options = [60, 90, 120, 150, 180, 240, 300];
    return showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(title),
        children: [
          for (final o in options)
            ListTile(
              title: Text(fmtDuration(Duration(seconds: o))),
              trailing: o == current ? const Icon(Icons.check) : null,
              onTap: () => Navigator.pop(ctx, o),
            ),
        ],
      ),
    );
  }

  static Future<void> _import(
      BuildContext context, AppController controller) async {
    final clip = await Clipboard.getData(Clipboard.kTextPlain);
    final text = clip?.text?.trim() ?? '';
    if (!context.mounted) return;
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Clipboard is empty')));
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Replace all data?'),
        content: const Text(
            'Your current weights and history will be replaced with the backup.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Import')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      controller.importJson(text);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Backup imported')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Invalid backup: $e')));
    }
  }
}

class _ExerciseStateDialog extends StatefulWidget {
  const _ExerciseStateDialog({required this.def, required this.state});

  final ExerciseDef def;
  final ExerciseState state;

  @override
  State<_ExerciseStateDialog> createState() => _ExerciseStateDialogState();
}

class _ExerciseStateDialogState extends State<_ExerciseStateDialog> {
  late final _weight = TextEditingController(text: fmtNum(widget.state.weight));
  late final _increment =
      TextEditingController(text: fmtNum(widget.state.increment));
  late int _fails = widget.state.failStreak;
  late int _bw = widget.state.bodyweightSessionsRemaining;

  @override
  void dispose() {
    _weight.dispose();
    _increment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = double.tryParse(_weight.text.trim());
    final inc = double.tryParse(_increment.text.trim());
    final valid = w != null && w >= 0 && inc != null && inc >= 0;
    final weightLabel = switch (widget.def.loadType) {
      LoadType.perDumbbell => 'Weight per dumbbell',
      LoadType.added => 'Added weight',
      LoadType.total => 'Weight',
    };
    return AlertDialog(
      title: Text(widget.def.name),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _weight,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                  labelText: weightLabel, suffixText: 'lb'),
              onChanged: (_) => setState(() {}),
            ),
            TextField(
              controller: _increment,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                  labelText: 'Increase per successful session',
                  suffixText: 'lb'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            _Stepper(
              label: 'Missed sessions in a row',
              value: _fails,
              max: failuresBeforeDeload - 1,
              onChanged: (v) => setState(() => _fails = v),
            ),
            if (widget.def.loadType == LoadType.added)
              _Stepper(
                label: 'Bodyweight sessions left',
                value: _bw,
                max: 10,
                onChanged: (v) => setState(() => _bw = v),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(
          onPressed: !valid
              ? null
              : () => Navigator.pop(
                    context,
                    ExerciseState(
                      weight: w,
                      increment: inc,
                      failStreak: _fails,
                      bodyweightSessionsRemaining: _bw,
                    ),
                  ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.label,
    required this.value,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        IconButton(
          onPressed: value > 0 ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove),
        ),
        Text('$value'),
        IconButton(
          onPressed: value < max ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}
