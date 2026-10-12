import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/worker.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';

class AddWorkerScreen extends StatefulWidget {
  final Worker? existing;
  const AddWorkerScreen({super.key, this.existing});

  @override
  State<AddWorkerScreen> createState() => _AddWorkerScreenState();
}

class _AddWorkerScreenState extends State<AddWorkerScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _role;
  late final TextEditingController _base;
  late final TextEditingController _ot;
  late bool _active;

  @override
  void initState() {
    super.initState();
    final w = widget.existing;
    _name = TextEditingController(text: w?.name ?? '');
    _role = TextEditingController(text: w?.role ?? '');
    _base = TextEditingController(
      text: w?.baseDailyRate.toStringAsFixed(0) ?? '',
    );
    _ot = TextEditingController(text: w?.otHourlyRate.toStringAsFixed(2) ?? '');
    _active = w?.isActive ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _role.dispose();
    _base.dispose();
    _ot.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final state = context.read<AppState>();
    final base = double.parse(_base.text.trim());
    final ot = double.parse(_ot.text.trim());
    final w = Worker(
      id: widget.existing?.id,
      name: _name.text.trim(),
      role: _role.text.trim(),
      baseDailyRate: base,
      otHourlyRate: ot,
      joiningDate:
          widget.existing?.joiningDate ?? DateTime.now().millisecondsSinceEpoch,
      isActive: _active,
    );
    if (widget.existing == null) {
      await state.addWorker(w);
    } else {
      await state.updateWorker(w);
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete worker?'),
        content: const Text(
          'This removes the worker and all their attendance records.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await context.read<AppState>().deleteWorker(widget.existing!.id!);
    if (mounted) Navigator.of(context).pop();
  }

  void _suggestOt() {
    final v = double.tryParse(_base.text.trim());
    if (v == null) return;
    // Heuristic from the RAJU sheet: OT hourly ≈ base / 8.
    _ot.text = (v / 8).toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.existing != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'Edit Worker' : 'Add Worker'),
        actions: [
          if (editing)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.danger),
              onPressed: _delete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Full Name'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _role,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Role / Skill (e.g. Mason, Helper)',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _base,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Base Daily Rate (₹)',
                    ),
                    onChanged: (_) {
                      if (_ot.text.trim().isEmpty) _suggestOt();
                    },
                    validator: (v) {
                      final d = double.tryParse(v?.trim() ?? '');
                      if (d == null || d <= 0) return 'Invalid';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _ot,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'OT Hourly Rate (₹)',
                    ),
                    validator: (v) {
                      final d = double.tryParse(v?.trim() ?? '');
                      if (d == null || d < 0) return 'Invalid';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            TextButton.icon(
              onPressed: _suggestOt,
              icon: const Icon(Icons.auto_fix_high, size: 18),
              label: const Text('Suggest OT rate = base / 8'),
            ),
            const SizedBox(height: 4),
            SwitchListTile(
              title: const Text('Active'),
              value: _active,
              onChanged: (v) => setState(() => _active = v),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: Text(editing ? 'Save Changes' : 'Add Worker'),
            ),
          ],
        ),
      ),
    );
  }
}
