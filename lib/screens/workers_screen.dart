import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../database/database_helper.dart';
import '../models/attendance_record.dart';
import '../models/worker.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar.dart';
import 'add_worker_screen.dart';
import 'worker_history_screen.dart';

class WorkersScreen extends StatefulWidget {
  const WorkersScreen({super.key});

  @override
  State<WorkersScreen> createState() => _WorkersScreenState();
}

class _WorkersScreenState extends State<WorkersScreen> {
  String _query = '';
  _Filter _filter = _Filter.all;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final workers = state.workers;
    final today = state.todayRecords;

    final presentIds = today.entries
        .where((e) => e.value.isPresent > 0)
        .map((e) => e.key)
        .toSet();

    Iterable<Worker> filtered = workers;
    if (_filter == _Filter.present) {
      filtered = filtered.where((w) => presentIds.contains(w.id));
    } else if (_filter == _Filter.absent) {
      filtered = filtered.where(
        (w) => !presentIds.contains(w.id) || (today[w.id]?.isPresent ?? 1) == 0,
      );
    }
    if (_query.trim().isNotEmpty) {
      final q = _query.toLowerCase();
      filtered = filtered.where(
        (w) =>
            w.name.toLowerCase().contains(q) ||
            w.role.toLowerCase().contains(q),
      );
    }
    final list = filtered.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Worker Management')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () async {
          await Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const AddWorkerScreen()));
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                hintText: 'Search by name, site, or skill...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _chip('All Workers (${workers.length})', _Filter.all),
                _chip('Present (${presentIds.length})', _Filter.present),
                _chip(
                  'Absent (${workers.length - presentIds.length})',
                  _Filter.absent,
                  isDanger: true,
                ),
              ],
            ),
          ),
          Expanded(
            child: list.isEmpty
                ? _EmptyState(hasAny: workers.isNotEmpty)
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _WorkerTile(
                      worker: list[i],
                      todayRecord: today[list[i].id],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, _Filter f, {bool isDanger = false}) {
    final selected = _filter == f;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _filter = f),
        selectedColor: isDanger ? AppColors.dangerBg : AppColors.primary,
        backgroundColor: isDanger
            ? AppColors.dangerBg.withOpacity(0.4)
            : AppColors.primaryLight,
        labelStyle: TextStyle(
          color: selected
              ? (isDanger ? AppColors.danger : Colors.white)
              : (isDanger ? AppColors.danger : AppColors.primary),
          fontWeight: FontWeight.w700,
        ),
        side: BorderSide.none,
      ),
    );
  }
}

enum _Filter { all, present, absent }

class _WorkerTile extends StatelessWidget {
  final Worker worker;
  final AttendanceRecord? todayRecord;
  const _WorkerTile({required this.worker, this.todayRecord});

  @override
  Widget build(BuildContext context) {
    final rupee = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );
    final hasUpadToday = (todayRecord?.upadAmount ?? 0) > 0;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => WorkerHistoryScreen(worker: worker),
            ),
          );
        },
        onLongPress: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AddWorkerScreen(existing: worker),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InitialsAvatar(initials: worker.initials, size: 52),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            worker.name.toUpperCase(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (hasUpadToday)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.dangerBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'PENDING UPAD',
                              style: TextStyle(
                                color: AppColors.danger,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ID: LT-${worker.id?.toString().padLeft(4, '0') ?? '----'} • ${worker.role.isEmpty ? 'WORKER' : worker.role.toUpperCase()}',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Base: ${rupee.format(worker.baseDailyRate)}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const Text(
                            '   |   ',
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                          Text(
                            'OT: ${rupee.format(worker.otHourlyRate)}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const Spacer(),
                          _SparkBar(workerId: worker.id!),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SparkBar extends StatelessWidget {
  final int workerId;
  const _SparkBar({required this.workerId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AttendanceRecord>>(
      future: DatabaseHelper.instance.getRecordsForWorker(workerId),
      builder: (_, snap) {
        final recs = snap.data ?? [];
        final now = DateTime.now();
        final byDate = {for (final r in recs) r.date: r.isPresent};
        final dots = <Widget>[];
        for (int i = 6; i >= 0; i--) {
          final d = AppState.normalizeDate(
            DateTime(now.year, now.month, now.day - i),
          );
          final v = byDate[d];
          Color c;
          if (v == null) {
            c = AppColors.primaryLight;
          } else if (v >= 1) {
            c = AppColors.success;
          } else if (v >= 0.5) {
            c = AppColors.amber;
          } else {
            c = AppColors.danger;
          }
          dots.add(
            Container(
              width: 6,
              height: 14,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: c,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }
        return Row(children: dots);
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasAny;
  const _EmptyState({required this.hasAny});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasAny ? Icons.search_off : Icons.engineering,
            size: 72,
            color: AppColors.primary,
          ),
          const SizedBox(height: 14),
          Text(
            hasAny ? 'No matching workers' : 'No workers yet',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tap + to add your first worker and start tracking attendance.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
