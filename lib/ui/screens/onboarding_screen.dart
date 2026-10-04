import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../logic/format.dart';
import '../../models/exercise_def.dart';
import '../../program/program.dart';
import '../../state/app_controller.dart';
import '../brand.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _controllers = {
    for (final def in exercises.values)
      def.id: TextEditingController(text: fmtNum(def.defaultStartWeight)),
  };

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  String _helper(ExerciseDef def) => switch (def.id) {
        'pullup' => 'Added weight. Leave at 0 for a bodyweight first week '
            '($pullupBodyweightSessions sessions), then +2.5 lb per session.',
        _ => switch (def.loadType) {
            LoadType.perDumbbell =>
              'Weight of each dumbbell. +${fmtNum(def.defaultIncrement)} lb per DB per session.',
            LoadType.added =>
              'Added weight (0 = bodyweight). +${fmtNum(def.defaultIncrement)} lb per session.',
            LoadType.total =>
              '+${fmtNum(def.defaultIncrement)} lb per session.',
          },
      };

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(appProvider.notifier).completeOnboarding({
      for (final e in _controllers.entries)
        e.key: double.parse(e.value.text.trim()),
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
              16, MediaQuery.paddingOf(context).top + 32, 16, 24),
          children: [
            const Center(child: MiloBadge(size: 112)),
            const SizedBox(height: 20),
            const Center(child: Wordmark(size: 36)),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                miloStory,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                    height: 1.45),
              ),
            ),
            const SizedBox(height: 28),
            const MeanderBand(height: 18),
            const SizedBox(height: 28),
            const Eyebrow('Starting weights'),
            const SizedBox(height: 6),
            Text(
              'Pick weights you can do for 5×5 with good form. Start light: '
              'weight goes up every time you complete all your sets.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            for (final def in exercises.values)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TextFormField(
                  controller: _controllers[def.id],
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: '${def.name} (${def.scheme})',
                    suffixText: 'lb',
                    helperText: _helper(def),
                    helperMaxLines: 3,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) {
                    final n = double.tryParse(v?.trim() ?? '');
                    return n == null || n < 0 ? 'Enter a weight' : null;
                  },
                ),
              ),
            FilledButton(
              onPressed: _submit,
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56)),
              child: const Text('START TRAINING'),
            ),
          ],
        ),
      ),
    );
  }
}
