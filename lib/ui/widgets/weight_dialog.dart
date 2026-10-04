import 'package:flutter/material.dart';

import '../../logic/format.dart';

/// Asks for a weight with ± step buttons. Returns null if cancelled.
Future<double?> showWeightDialog(
  BuildContext context, {
  required String title,
  required double initial,
  required double step,
  String? helper,
}) {
  return showDialog<double>(
    context: context,
    builder: (_) => _WeightDialog(
        title: title, initial: initial, step: step, helper: helper),
  );
}

class _WeightDialog extends StatefulWidget {
  const _WeightDialog({
    required this.title,
    required this.initial,
    required this.step,
    this.helper,
  });

  final String title;
  final double initial;
  final double step;
  final String? helper;

  @override
  State<_WeightDialog> createState() => _WeightDialogState();
}

class _WeightDialogState extends State<_WeightDialog> {
  late final _controller = TextEditingController(text: fmtNum(widget.initial));

  double? get _value => double.tryParse(_controller.text.trim());

  void _bump(double delta) {
    final v = ((_value ?? widget.initial) + delta).clamp(0, 2000).toDouble();
    setState(() => _controller.text = fmtNum(v));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Row(
        children: [
          IconButton.filledTonal(
            onPressed: () => _bump(-widget.step),
            icon: const Icon(Icons.remove),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _controller,
              autofocus: true,
              textAlign: TextAlign.center,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: Theme.of(context).textTheme.headlineSmall,
              decoration: InputDecoration(
                suffixText: 'lb',
                helperText: widget.helper,
                helperMaxLines: 2,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: 12),
          IconButton.filledTonal(
            onPressed: () => _bump(widget.step),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _value == null || _value! < 0
              ? null
              : () => Navigator.pop(context, _value),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
