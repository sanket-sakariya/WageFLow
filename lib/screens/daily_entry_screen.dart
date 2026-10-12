import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../database/database_helper.dart';
import '../models/attendance_record.dart';
import '../models/worker.dart';
import '../services/app_state.dart';
import '../services/salary_calculator.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar.dart';

class DailyEntryScreen extends StatefulWidget {
  final bool fromDashboard;
  const DailyEntryScreen({super.key, this.fromDashboard = false});

  @override
  State<DailyEntryScreen> createState() => _DailyEntryScreenState();
}

class _DailyEntryScreenState extends State<DailyEntryScreen> {
  DateTime _date = DateTime.now();
  bool _loading = true;
  final Map<int, _RowState> _rows = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadForDate());
  }

  Future<void> _loadForDate() async {
    setState(() => _loading = true);
    final state = context.read<AppState>();
    final workers = state.activeWorkers;
    final dateMs = AppState.normalizeDate(_date);
    final existing = await DatabaseHelper.instance.getRecordsForDate(dateMs);
    final byId = {for (final r in existing) r.workerId: r};
    _rows.clear();
    for (final w in workers) {
      final r = byId[w.id];
      _rows[w.id!] = _RowState(
        worker: w,
        isPresent: r?.isPresent ?? 1.0,
        otHours: r?.overTimeHours ?? 0,
        upadAmount: r?.upadAmount ?? 0,
        paymentMethod: r?.paymentMethod ?? '',
        remarks: r?.remarks ?? '',
        existingId: r?.recordId,
      );
    }
    setState(() => _loading = false);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      _date = picked;
      await _loadForDate();
    }
  }

  Future<void> _saveAll() async {
    final db = DatabaseHelper.instance;
    final dateMs = AppState.normalizeDate(_date);
    int saved = 0;
    for (final r in _rows.values) {
      final total = SalaryCalculator.dailyTotal(
        worker: r.worker,
        isPresent: r.isPresent,
        overTimeHours: r.otHours,
      );
      final record = AttendanceRecord(
        recordId: r.existingId,
        workerId: r.worker.id!,
        date: dateMs,
        isPresent: r.isPresent,
        overTimeHours: r.otHours,
        upadAmount: r.upadAmount,
        paymentMethod: r.paymentMethod,
        remarks: r.remarks.trim(),
        calculatedTotal: total,
      );
      await db.upsertAttendance(record);
      saved++;
    }
    if (!mounted) return;
    await context.read<AppState>().refresh();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Saved $saved records')));
    if (widget.fromDashboard) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final workers = state.activeWorkers;

    return Scaffold(
      appBar: AppBar(
        leading: widget.fromDashboard
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).maybePop(),
              )
            : null,
        title: const Text('LaborTrack Pro'),
        actions: [
          IconButton(
            tooltip: 'Pick date',
            icon: const Icon(Icons.calendar_today_outlined),
            onPressed: _pickDate,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : workers.isEmpty
          ? const _NoWorkers()
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Daily Attendance',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              DateFormat('EEEE, MMM d, y').format(_date),
                              style: const TextStyle(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
                    itemCount: workers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final w = workers[i];
                      final row = _rows[w.id]!;
                      return _EntryCard(
                        row: row,
                        onChanged: () => setState(() {}),
                      );
                    },
                  ),
                ),
              ],
            ),
      bottomSheet: _loading || workers.isEmpty
          ? null
          : SafeArea(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                child: ElevatedButton.icon(
                  onPressed: _saveAll,
                  icon: const Icon(Icons.save_outlined),
                  label: Text('Save ${_rows.length} Records'),
                ),
              ),
            ),
    );
  }
}

class _RowState {
  final Worker worker;
  double isPresent;
  double otHours;
  double upadAmount;
  String paymentMethod;
  String remarks;
  int? existingId;

  _RowState({
    required this.worker,
    required this.isPresent,
    required this.otHours,
    required this.upadAmount,
    required this.paymentMethod,
    required this.remarks,
    this.existingId,
  });
}

class _EntryCard extends StatefulWidget {
  final _RowState row;
  final VoidCallback onChanged;
  const _EntryCard({required this.row, required this.onChanged});

  @override
  State<_EntryCard> createState() => _EntryCardState();
}

class _EntryCardState extends State<_EntryCard> {
  late final TextEditingController _upad;
  late final TextEditingController _remarks;

  @override
  void initState() {
    super.initState();
    _upad = TextEditingController(
      text: widget.row.upadAmount == 0
          ? ''
          : widget.row.upadAmount.toStringAsFixed(0),
    );
    _remarks = TextEditingController(text: widget.row.remarks);
  }

  @override
  void dispose() {
    _upad.dispose();
    _remarks.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.row;
    final rupee = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );
    final today = SalaryCalculator.dailyTotal(
      worker: r.worker,
      isPresent: r.isPresent,
      overTimeHours: r.otHours,
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                InitialsAvatar(initials: r.worker.initials, size: 44),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.worker.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${r.worker.role.isEmpty ? 'Worker' : r.worker.role} • #WM-${r.worker.id?.toString().padLeft(3, '0') ?? '---'}',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _PresentToggle(
              value: r.isPresent,
              onChanged: (v) {
                setState(() => r.isPresent = v);
                widget.onChanged();
              },
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _RoundButton(
                  icon: Icons.remove,
                  onTap: () {
                    if (r.otHours <= 0) return;
                    setState(() => r.otHours = (r.otHours - 0.5));
                    widget.onChanged();
                  },
                ),
                const SizedBox(width: 16),
                Text(
                  '${r.otHours.toStringAsFixed(1)} hrs',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 16),
                _RoundButton(
                  icon: Icons.add,
                  onTap: () {
                    setState(() => r.otHours = (r.otHours + 0.5));
                    widget.onChanged();
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
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
                    decoration: InputDecoration(
                      prefixText: '₹  ',
                      hintText: 'Upad (advance)',
                      fillColor: r.upadAmount > 0 ? AppColors.dangerBg : null,
                    ),
                    style: TextStyle(
                      color: r.upadAmount > 0
                          ? AppColors.danger
                          : AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                    onChanged: (v) {
                      r.upadAmount = double.tryParse(v) ?? 0;
                      widget.onChanged();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                _PayMethodChip(
                  value: r.paymentMethod,
                  onChanged: (m) {
                    setState(() => r.paymentMethod = m);
                    widget.onChanged();
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _remarks,
              decoration: const InputDecoration(
                hintText: 'Remarks (e.g. BHARAT, RAMADHANI, GPAY 5000)',
              ),
              onChanged: (v) => r.remarks = v,
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Today: ${rupee.format(today)}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
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
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
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

class _NoWorkers extends StatelessWidget {
  const _NoWorkers();
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.engineering, size: 72, color: AppColors.primary),
            SizedBox(height: 12),
            Text(
              'Add a worker first',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            SizedBox(height: 6),
            Text(
              'Go to the Workers tab and tap + to add your first worker.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
