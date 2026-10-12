import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../database/database_helper.dart';
import '../models/attendance_record.dart';
import '../models/worker.dart';
import '../services/salary_calculator.dart';
import '../theme/app_theme.dart';

/// Modal sheet to edit or delete an existing AttendanceRecord.
/// Returns `true` when changes (update or delete) were saved.
class EditRecordSheet extends StatefulWidget {
  final Worker worker;
  final AttendanceRecord record;
  const EditRecordSheet({
    super.key,
    required this.worker,
    required this.record,
  });

  static Future<bool> show(
    BuildContext context, {
    required Worker worker,
    required AttendanceRecord record,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: EditRecordSheet(worker: worker, record: record),
      ),
    );
    return result ?? false;
  }

  @override
  State<EditRecordSheet> createState() => _EditRecordSheetState();
}

class _EditRecordSheetState extends State<EditRecordSheet> {
  late double _isPresent;
  late double _otHours;
  late String _paymentMethod;
  late final TextEditingController _upad;
  late final TextEditingController _remarks;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _isPresent = widget.record.isPresent;
    _otHours = widget.record.overTimeHours;
    _paymentMethod = widget.record.paymentMethod;
    _upad = TextEditingController(
      text: widget.record.upadAmount == 0
          ? ''
          : widget.record.upadAmount.toStringAsFixed(0),
    );
    _remarks = TextEditingController(text: widget.record.remarks);
  }

  @override
  void dispose() {
    _upad.dispose();
    _remarks.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final upad = double.tryParse(_upad.text.trim()) ?? 0;
    final total = SalaryCalculator.dailyTotal(
      worker: widget.worker,
      isPresent: _isPresent,
      overTimeHours: _otHours,
    );
    final updated = widget.record.copyWith(
      isPresent: _isPresent,
      overTimeHours: _otHours,
      upadAmount: upad,
      paymentMethod: _paymentMethod,
      remarks: _remarks.text.trim(),
      calculatedTotal: total,
    );
    await DatabaseHelper.instance.upsertAttendance(updated);
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete this record?'),
        content: Text(
          'This will permanently remove the entry for '
          '${DateFormat('MMM d, y').format(DateTime.fromMillisecondsSinceEpoch(widget.record.date))}.',
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
    setState(() => _saving = true);
    await DatabaseHelper.instance.deleteRecord(widget.record.recordId!);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final rupee = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );
    final d = DateTime.fromMillisecondsSinceEpoch(widget.record.date);
    final preview = SalaryCalculator.dailyTotal(
      worker: widget.worker,
      isPresent: _isPresent,
      overTimeHours: _otHours,
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E1E6),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Edit Entry',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        DateFormat('EEEE, MMM d, y').format(d),
                        style: const TextStyle(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Delete',
                  onPressed: _saving ? null : _delete,
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.danger,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _PresentToggle(
              value: _isPresent,
              onChanged: (v) => setState(() => _isPresent = v),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _RoundButton(
                  icon: Icons.remove,
                  onTap: () {
                    if (_otHours <= 0) return;
                    setState(() => _otHours -= 0.5);
                  },
                ),
                const SizedBox(width: 16),
                Text(
                  '${_otHours.toStringAsFixed(1)} hrs OT',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 16),
                _RoundButton(
                  icon: Icons.add,
                  onTap: () => setState(() => _otHours += 0.5),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _upad,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    decoration: const InputDecoration(
                      prefixText: '₹  ',
                      hintText: 'Upad (advance)',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                _PayMethodChip(
                  value: _paymentMethod,
                  onChanged: (m) => setState(() => _paymentMethod = m),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _remarks,
              decoration: const InputDecoration(hintText: 'Remarks'),
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Today: ${rupee.format(preview)}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving
                        ? null
                        : () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Save Changes'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PresentToggle extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  const _PresentToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _seg('Full', 1.0, AppColors.success),
          _seg('Half', 0.5, AppColors.amber),
          _seg('Absent', 0.0, AppColors.danger),
        ],
      ),
    );
  }

  Widget _seg(String label, double v, Color color) {
    final selected = value == v;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(v),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: selected ? color : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE0E1E6)),
        ),
        child: Icon(icon, color: AppColors.primary),
      ),
    );
  }
}

class _PayMethodChip extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _PayMethodChip({required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: onChanged,
      itemBuilder: (_) => const [
        PopupMenuItem(value: '', child: Text('—')),
        PopupMenuItem(value: 'CASH', child: Text('CASH')),
        PopupMenuItem(value: 'GPAY', child: Text('GPAY')),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.payments_outlined,
              size: 18,
              color: AppColors.primary,
            ),
            const SizedBox(width: 6),
            Text(
              value.isEmpty ? 'Pay' : value,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
