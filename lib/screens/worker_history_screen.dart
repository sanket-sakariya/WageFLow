import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../database/database_helper.dart';
import '../models/attendance_record.dart';
import '../models/worker.dart';
import '../services/app_state.dart';
import '../services/csv_service.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar.dart';
import '../widgets/edit_record_sheet.dart';

/// Month filter selector. `null` = All Time, otherwise a (year, month) pair.
class _MonthKey {
  final int year;
  final int month;
  const _MonthKey(this.year, this.month);
  @override
  bool operator ==(Object o) =>
      o is _MonthKey && o.year == year && o.month == month;
  @override
  int get hashCode => Object.hash(year, month);
  static _MonthKey ofDate(int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    return _MonthKey(d.year, d.month);
  }

  String get label =>
      DateFormat('MMM yyyy').format(DateTime(year, month, 1));
  String get shortLabel => DateFormat('MMM').format(DateTime(year, month, 1));
}

class WorkerHistoryScreen extends StatefulWidget {
  final Worker worker;
  const WorkerHistoryScreen({super.key, required this.worker});

  @override
  State<WorkerHistoryScreen> createState() => _WorkerHistoryScreenState();
}

class _WorkerHistoryScreenState extends State<WorkerHistoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  late Future<List<AttendanceRecord>> _future;
  _MonthKey? _selectedMonth; // null = All Time

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _reload();
  }

  void _reload() {
    setState(() {
      _future = DatabaseHelper.instance.getRecordsForWorker(widget.worker.id!);
    });
  }

  Future<void> _openEditor(AttendanceRecord r) async {
    final changed = await EditRecordSheet.show(
      context,
      worker: widget.worker,
      record: r,
    );
    if (changed) {
      _reload();
      if (mounted) await context.read<AppState>().refresh();
    }
  }

  Future<void> _confirmDelete(AttendanceRecord r) async {
    final d = DateTime.fromMillisecondsSinceEpoch(r.date);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete this record?'),
        content: Text(
          'This will permanently remove the entry for '
          '${DateFormat('MMM d, y').format(d)}.',
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
    await DatabaseHelper.instance.deleteRecord(r.recordId!);
    _reload();
    if (mounted) await context.read<AppState>().refresh();
  }

  Future<void> _settleAndReset(List<AttendanceRecord> all) async {
    final rupee = NumberFormat.currency(
        locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final unsettled = all.where((r) => !r.isSettled).toList();
    if (unsettled.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nothing to settle — balance is already ₹0.')),
      );
      return;
    }
    final earned = unsettled.fold<double>(0, (a, r) => a + r.calculatedTotal);
    final upad = unsettled.fold<double>(0, (a, r) => a + r.upadAmount);
    final balance = earned - upad;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Settle & Reset?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This marks all ${unsettled.length} unsettled entries as paid '
              'and resets the balance to ₹0 for next month.\n\n'
              'Records stay in history (and CSV exports) but stop counting '
              'towards "Balance Payable".',
            ),
            const SizedBox(height: 12),
            Text('Earned: ${rupee.format(earned)}'),
            Text('Upad:   ${rupee.format(upad)}'),
            Text('Paying out: ${rupee.format(balance)}',
                style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Settle'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await DatabaseHelper.instance.settleWorker(widget.worker.id!);
    _reload();
    if (mounted) {
      await context.read<AppState>().refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Settled ${unsettled.length} records.')),
      );
    }
  }

  List<AttendanceRecord> _filterByMonth(List<AttendanceRecord> all) {
    if (_selectedMonth == null) return all;
    return all.where((r) {
      final k = _MonthKey.ofDate(r.date);
      return k == _selectedMonth;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final rupee = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('LabourTracker'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) async {
              final all = await _future;
              if (v == 'settle') await _settleAndReset(all);
              if (v == 'export') {
                try {
                  await CsvService.exportWorkerCsv(widget.worker);
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Export failed: $e')),
                    );
                  }
                }
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'settle',
                child: ListTile(
                  leading: Icon(Icons.task_alt, color: AppColors.success),
                  title: Text('Settle & Reset'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.download, color: AppColors.primary),
                  title: Text('Export CSV'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: FutureBuilder<List<AttendanceRecord>>(
        future: _future,
        builder: (_, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final all = snap.data!;
          final available = <_MonthKey>{
            for (final r in all) _MonthKey.ofDate(r.date),
          }.toList()
            ..sort((a, b) {
              final c = b.year.compareTo(a.year);
              return c != 0 ? c : b.month.compareTo(a.month);
            });

          // Reset selectedMonth if it no longer exists in data
          if (_selectedMonth != null && !available.contains(_selectedMonth)) {
            WidgetsBinding.instance.addPostFrameCallback(
                (_) => setState(() => _selectedMonth = null));
          }

          final filtered = _filterByMonth(all);

          // Pending = unsettled across all-time (independent of filter)
          final unsettled = all.where((r) => !r.isSettled).toList();
          final pendingEarned = unsettled.fold<double>(
              0, (a, r) => a + r.calculatedTotal);
          final pendingUpad =
              unsettled.fold<double>(0, (a, r) => a + r.upadAmount);
          final pendingBalance = pendingEarned - pendingUpad;

          final filteredEarned =
              filtered.fold<double>(0, (a, r) => a + r.calculatedTotal);
          final filteredUpad =
              filtered.fold<double>(0, (a, r) => a + r.upadAmount);
          final filteredBalance = filteredEarned - filteredUpad;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            InitialsAvatar(
                                initials: widget.worker.initials, size: 56),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(widget.worker.name.toUpperCase(),
                                      style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800)),
                                  const SizedBox(height: 4),
                                  Row(children: [
                                    const Icon(Icons.payments_outlined,
                                        size: 16,
                                        color: AppColors.textMuted),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Base: ${rupee.format(widget.worker.baseDailyRate)} / day',
                                      style: const TextStyle(
                                          color: AppColors.textMuted),
                                    ),
                                  ]),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _MonthDropdown(
                          available: available,
                          selected: _selectedMonth,
                          onChanged: (v) =>
                              setState(() => _selectedMonth = v),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TabBar(
                  controller: _tab,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textMuted,
                  indicatorColor: AppColors.primary,
                  tabs: const [
                    Tab(text: 'History'),
                    Tab(text: 'Summary'),
                    Tab(text: 'Months'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tab,
                  children: [
                    _historyTab(filtered, rupee),
                    _summaryTab(filtered, filteredEarned, filteredUpad,
                        filteredBalance, rupee),
                    _monthsTab(all, rupee),
                  ],
                ),
              ),
              _Footer(
                earned: pendingEarned,
                upad: pendingUpad,
                balance: pendingBalance,
              ),
            ],
          );
        },
      ),
    );
  }

  // ===== HISTORY TAB =====
  Widget _historyTab(List<AttendanceRecord> records, NumberFormat rupee) {
    if (records.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            _selectedMonth == null
                ? 'No entries yet for this worker.'
                : 'No entries for ${_selectedMonth!.label}.',
            style: const TextStyle(color: AppColors.textMuted),
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: records.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final r = records[i];
        final d = DateTime.fromMillisecondsSinceEpoch(r.date);
        final isAdvance = r.upadAmount > 0 && r.isPresent == 0;
        return Dismissible(
          key: ValueKey('rec-${r.recordId}'),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 22),
            decoration: BoxDecoration(
              color: AppColors.danger,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.delete, color: Colors.white),
                SizedBox(width: 6),
                Text('Delete',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          confirmDismiss: (_) async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Delete this record?'),
                content: Text(
                  'This will permanently remove the entry for '
                  '${DateFormat('MMM d, y').format(d)}.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: TextButton.styleFrom(
                        foregroundColor: AppColors.danger),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            );
            return ok ?? false;
          },
          onDismissed: (_) async {
            await DatabaseHelper.instance.deleteRecord(r.recordId!);
            _reload();
            if (mounted) await context.read<AppState>().refresh();
          },
          child: Card(
            color: isAdvance ? AppColors.dangerBg : null,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _openEditor(r),
              onLongPress: () => _confirmDelete(r),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isAdvance
                            ? AppColors.danger.withOpacity(0.1)
                            : AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Text(DateFormat('MMM').format(d).toUpperCase(),
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isAdvance
                                      ? AppColors.danger
                                      : AppColors.primary)),
                          Text(DateFormat('d').format(d),
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: isAdvance
                                      ? AppColors.danger
                                      : AppColors.primary)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Expanded(
                              child: Text(
                                isAdvance
                                    ? 'Advance Payment (Upad)'
                                    : '${r.isPresent >= 1 ? '1 Day Full' : r.isPresent >= 0.5 ? '0.5 Day Half' : 'Absent'} Shift',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: isAdvance
                                      ? AppColors.danger
                                      : Colors.black87,
                                ),
                              ),
                            ),
                            if (r.isSettled)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.successBg,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text('SETTLED',
                                    style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.success)),
                              ),
                          ]),
                          const SizedBox(height: 2),
                          if (!isAdvance)
                            Row(children: [
                              const Icon(Icons.schedule,
                                  size: 14, color: AppColors.textMuted),
                              const SizedBox(width: 4),
                              Text('${r.overTimeHours.toStringAsFixed(1)}h OT',
                                  style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 12)),
                              if (r.paymentMethod.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Text('• ${r.paymentMethod}',
                                    style: const TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 12)),
                              ],
                            ])
                          else if (r.remarks.isNotEmpty)
                            Text(r.remarks,
                                style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 12)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          isAdvance
                              ? '- ${rupee.format(r.upadAmount)}'
                              : rupee.format(r.calculatedTotal),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: isAdvance
                                ? AppColors.danger
                                : AppColors.primary,
                          ),
                        ),
                        if (!isAdvance && r.upadAmount > 0)
                          Text('↓ ${rupee.format(r.upadAmount)} Upad',
                              style: const TextStyle(
                                  color: AppColors.danger, fontSize: 12))
                        else if (!isAdvance)
                          const Text('No Deductions',
                              style: TextStyle(
                                  color: AppColors.textMuted, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ===== SUMMARY TAB =====
  Widget _summaryTab(List<AttendanceRecord> records, double earned,
      double upad, double balance, NumberFormat rupee) {
    final totalDays = records.fold<double>(0, (a, r) => a + r.isPresent);
    final totalOt = records.fold<double>(0, (a, r) => a + r.overTimeHours);
    final cashCount = records.where((r) => r.paymentMethod == 'CASH').length;
    final gpayCount = records.where((r) => r.paymentMethod == 'GPAY').length;
    final scopeLabel =
        _selectedMonth == null ? 'All Time' : _selectedMonth!.label;

    Widget tile(String label, String value, {Color? color}) => Card(
          child: ListTile(
            title: Text(label,
                style: const TextStyle(color: AppColors.textMuted)),
            trailing: Text(value,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: color ?? AppColors.primary)),
          ),
        );
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Text('Showing: $scopeLabel',
              style: const TextStyle(
                  color: AppColors.textMuted, fontWeight: FontWeight.w700)),
        ),
        tile('Total Earned', rupee.format(earned)),
        tile('Total Upad (Advance)', rupee.format(upad),
            color: AppColors.danger),
        tile('Final Payout (Earned − Upad)', rupee.format(balance)),
        const SizedBox(height: 8),
        tile('Total Days Worked', totalDays.toStringAsFixed(1)),
        tile('Total OT Hours', totalOt.toStringAsFixed(1)),
        tile('Paid via CASH (entries)', cashCount.toString()),
        tile('Paid via GPAY (entries)', gpayCount.toString()),
      ],
    );
  }

  // ===== MONTHS TAB =====
  Widget _monthsTab(List<AttendanceRecord> all, NumberFormat rupee) {
    if (all.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('No entries yet.',
              style: TextStyle(color: AppColors.textMuted)),
        ),
      );
    }
    final byMonth = <_MonthKey, List<AttendanceRecord>>{};
    for (final r in all) {
      byMonth.putIfAbsent(_MonthKey.ofDate(r.date), () => []).add(r);
    }
    final keys = byMonth.keys.toList()
      ..sort((a, b) {
        final c = b.year.compareTo(a.year);
        return c != 0 ? c : b.month.compareTo(a.month);
      });
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: keys.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final k = keys[i];
        final list = byMonth[k]!;
        final earned =
            list.fold<double>(0, (a, r) => a + r.calculatedTotal);
        final upad = list.fold<double>(0, (a, r) => a + r.upadAmount);
        final bal = earned - upad;
        final unsettledCount = list.where((r) => !r.isSettled).length;
        return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() {
              _selectedMonth = k;
              _tab.animateTo(0);
            }),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(k.label,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w800)),
                    ),
                    Text('${list.length} entries',
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 12)),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    _kv('Earned', rupee.format(earned), AppColors.primary),
                    _kv('Upad', rupee.format(upad), AppColors.danger),
                    _kv('Balance', rupee.format(bal),
                        bal >= 0 ? AppColors.success : AppColors.danger,
                        highlight: true),
                  ]),
                  if (unsettledCount == 0) ...[
                    const SizedBox(height: 8),
                    const Row(children: [
                      Icon(Icons.check_circle,
                          size: 14, color: AppColors.success),
                      SizedBox(width: 4),
                      Text('All settled',
                          style: TextStyle(
                              color: AppColors.success,
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                    ]),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _kv(String label, String value, Color color,
      {bool highlight = false}) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: highlight
              ? AppColors.primaryLight
              : AppColors.background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4)),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value,
                  style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthDropdown extends StatelessWidget {
  final List<_MonthKey> available;
  final _MonthKey? selected;
  final ValueChanged<_MonthKey?> onChanged;
  const _MonthDropdown({
    required this.available,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final thisMonth = _MonthKey(now.year, now.month);
    final hasThisMonth = available.contains(thisMonth);
    return SizedBox(
      width: double.infinity,
      child: InputDecorator(
        decoration: const InputDecoration(
          isDense: true,
          labelText: 'Month',
          prefixIcon: Icon(Icons.event, color: AppColors.primary),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<_MonthKey?>(
            value: selected,
            isExpanded: true,
            onChanged: onChanged,
            items: [
              const DropdownMenuItem<_MonthKey?>(
                value: null,
                child: Text('All Time'),
              ),
              if (hasThisMonth)
                DropdownMenuItem<_MonthKey?>(
                  value: thisMonth,
                  child: Text('This Month  •  ${thisMonth.label}'),
                ),
              for (final k in available)
                if (k != thisMonth)
                  DropdownMenuItem<_MonthKey?>(
                    value: k,
                    child: Text(k.label),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  final double earned;
  final double upad;
  final double balance;
  const _Footer(
      {required this.earned, required this.upad, required this.balance});

  @override
  Widget build(BuildContext context) {
    final rupee = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border:
              Border(top: BorderSide(color: Color(0xFFE6E7EC), width: 1)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text('PENDING (UNSETTLED)',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textMuted,
                      letterSpacing: 0.5)),
            ),
            const SizedBox(height: 4),
            Row(children: [
              _stat('EARNED', rupee.format(earned), AppColors.primary),
              _stat('UPAD', rupee.format(upad), AppColors.danger),
              _stat('BALANCE', rupee.format(balance), AppColors.primary,
                  highlight: true),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value, Color color,
      {bool highlight = false}) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: highlight ? AppColors.primaryLight : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5)),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value,
                  style: TextStyle(
                      color: color,
                      fontSize: 16,
                      fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }
}
