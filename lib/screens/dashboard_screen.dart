import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../database/database_helper.dart';
import '../services/app_state.dart';
import '../services/csv_service.dart';
import '../theme/app_theme.dart';
import 'daily_entry_screen.dart';
import 'worker_history_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final rupee = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    if (state.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final workers = state.activeWorkers;
    final today = state.todayRecords;
    final present = today.values.where((r) => r.isPresent > 0).length;
    final totalUpad = today.values.fold<double>(0, (a, r) => a + r.upadAmount);

    return FutureBuilder<_OverallSummary>(
      future: _OverallSummary.compute(),
      builder: (context, snap) {
        final summary = snap.data;
        return Scaffold(
          appBar: AppBar(
            title: const Text('LaborTrack Pro'),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Chip(
                  backgroundColor: AppColors.primaryLight,
                  side: BorderSide.none,
                  avatar: const Icon(
                    Icons.groups,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  label: Text(
                    '${workers.length}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Backup',
                icon: const Icon(Icons.backup_outlined),
                onPressed: () async {
                  try {
                    await CsvService.exportFullBackup();
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Backup failed: $e')),
                      );
                    }
                  }
                },
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () => context.read<AppState>().refresh(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _StatusCard(present: present, total: workers.length),
                const SizedBox(height: 12),
                _MetricCard(
                  title: 'NET PENDING',
                  value: rupee.format(summary?.netPending ?? 0),
                  icon: Icons.account_balance_wallet_outlined,
                  bg: AppColors.surface,
                  accent: AppColors.primaryLight,
                ),
                const SizedBox(height: 12),
                _MetricCard(
                  title: 'TOTAL UPAD (TODAY)',
                  value: rupee.format(totalUpad),
                  icon: Icons.south_east,
                  bg: AppColors.dangerBg,
                  accent: Colors.white,
                  valueColor: AppColors.danger,
                ),
                const SizedBox(height: 12),
                _MetricCard(
                  title: 'TOTAL UPAD (ALL-TIME)',
                  value: rupee.format(summary?.totalUpad ?? 0),
                  icon: Icons.summarize_outlined,
                  bg: AppColors.surface,
                  accent: AppColors.primaryLight,
                ),
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            const DailyEntryScreen(fromDashboard: true),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit_calendar),
                  label: const Text('Mark Attendance'),
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      'Recent Activity',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (summary == null)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (summary.recent.isEmpty)
                  _EmptyHint(
                    icon: Icons.fact_check_outlined,
                    title: 'No activity yet',
                    subtitle: 'Add workers and start marking daily attendance.',
                  )
                else
                  ...summary.recent.map((e) => _ActivityTile(entry: e)),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OverallSummary {
  final double totalEarned;
  final double totalUpad;
  final double netPending;
  final List<_ActivityEntry> recent;

  _OverallSummary({
    required this.totalEarned,
    required this.totalUpad,
    required this.netPending,
    required this.recent,
  });

  static Future<_OverallSummary> compute() async {
    final db = DatabaseHelper.instance;
    final workers = await db.getWorkers();
    final workerById = {for (final w in workers) w.id: w};
    final records = await db.getAllRecords();
    double earned = 0, upad = 0;
    for (final r in records) {
      earned += r.calculatedTotal;
      upad += r.upadAmount;
    }
    final unsettled = await db.getUnsettledTotals();
    final recent = records
        .take(8)
        .map(
          (r) => _ActivityEntry(
            workerName: workerById[r.workerId]?.name ?? 'Unknown',
            workerId: r.workerId,
            date: DateTime.fromMillisecondsSinceEpoch(r.date),
            presentLabel: r.isPresent >= 1
                ? 'Full Day'
                : r.isPresent >= 0.5
                ? 'Half Day'
                : 'Absent',
            upad: r.upadAmount,
            total: r.calculatedTotal,
          ),
        )
        .toList();
    return _OverallSummary(
      totalEarned: earned,
      totalUpad: upad,
      netPending: unsettled.pending,
      recent: recent,
    );
  }
}

class _ActivityEntry {
  final String workerName;
  final int workerId;
  final DateTime date;
  final String presentLabel;
  final double upad;
  final double total;
  _ActivityEntry({
    required this.workerName,
    required this.workerId,
    required this.date,
    required this.presentLabel,
    required this.upad,
    required this.total,
  });
}

class _StatusCard extends StatelessWidget {
  final int present;
  final int total;
  const _StatusCard({required this.present, required this.total});

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : present / total;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            const Text(
              "Today's Status",
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 120,
              width: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: 120,
                    width: 120,
                    child: CircularProgressIndicator(
                      value: pct,
                      strokeWidth: 10,
                      backgroundColor: AppColors.primaryLight,
                      color: AppColors.primary,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$present/$total',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      const Text(
                        'Active',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Workers Present',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color bg;
  final Color accent;
  final Color? valueColor;
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.bg,
    required this.accent,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: bg,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      letterSpacing: 0.5,
                      color: valueColor ?? AppColors.textMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: valueColor ?? AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: valueColor ?? AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final _ActivityEntry entry;
  const _ActivityTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );
    final timeFmt = DateFormat('MMM d');
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          final w = await DatabaseHelper.instance.getWorker(entry.workerId);
          if (w == null || !context.mounted) return;
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => WorkerHistoryScreen(worker: w)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: AppColors.primaryLight,
                child: Icon(Icons.person, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.workerName,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Marked ${entry.presentLabel}',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    timeFmt.format(entry.date),
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.upad > 0
                        ? '- ${fmt.format(entry.upad)}'
                        : fmt.format(entry.total),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: entry.upad > 0
                          ? AppColors.danger
                          : AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _EmptyHint({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(icon, size: 44, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
