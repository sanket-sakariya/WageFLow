import 'dart:io';

import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../database/database_helper.dart';
import '../models/attendance_record.dart';
import '../models/worker.dart';

class CsvService {
  static final _dateFmt = DateFormat('yyyy-MM-dd');

  /// Export one worker's attendance log to CSV and share it.
  static Future<File> exportWorkerCsv(Worker w) async {
    final records = await DatabaseHelper.instance.getRecordsForWorker(w.id!);
    final rows = <List<dynamic>>[
      [
        'DATE',
        'DAY',
        'PRESENT',
        'OVER TIME',
        'UPAD',
        'TOTAL',
        'CASH OR GPAY',
        'REMARKS',
      ],
      ...records.map((r) {
        final d = DateTime.fromMillisecondsSinceEpoch(r.date);
        return [
          _dateFmt.format(d),
          DateFormat('EEE').format(d),
          _presentLabel(r.isPresent),
          r.overTimeHours,
          r.upadAmount,
          r.calculatedTotal,
          r.paymentMethod,
          r.remarks,
        ];
      }),
    ];
    final csv = const ListToCsvConverter().convert(rows);
    final dir = await getApplicationDocumentsDirectory();
    final safeName = w.name.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    final file = File(p.join(dir.path, '${safeName}_attendance.csv'));
    await file.writeAsString(csv);
    await Share.shareXFiles([
      XFile(file.path),
    ], subject: '${w.name} - Attendance');
    return file;
  }

  /// Full DB backup (all workers + all attendance) as CSV.
  static Future<File> exportFullBackup() async {
    final workers = await DatabaseHelper.instance.getWorkers();
    final records = await DatabaseHelper.instance.getAllRecords();
    final workerById = {for (final w in workers) w.id: w};

    final rows = <List<dynamic>>[
      [
        'WORKER',
        'ROLE',
        'BASE',
        'OT RATE',
        'DATE',
        'PRESENT',
        'OT',
        'UPAD',
        'TOTAL',
        'CASH OR GPAY',
        'REMARKS',
      ],
      ...records.map((r) {
        final w = workerById[r.workerId];
        final d = DateTime.fromMillisecondsSinceEpoch(r.date);
        return [
          w?.name ?? 'Unknown',
          w?.role ?? '',
          w?.baseDailyRate ?? 0,
          w?.otHourlyRate ?? 0,
          _dateFmt.format(d),
          _presentLabel(r.isPresent),
          r.overTimeHours,
          r.upadAmount,
          r.calculatedTotal,
          r.paymentMethod,
          r.remarks,
        ];
      }),
    ];

    final csv = const ListToCsvConverter().convert(rows);
    final dir = await getApplicationDocumentsDirectory();
    final stamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    final file = File(p.join(dir.path, 'labortrack_backup_$stamp.csv'));
    await file.writeAsString(csv);
    await Share.shareXFiles([XFile(file.path)], subject: 'LaborTrack Backup');
    return file;
  }

  static String _presentLabel(double v) {
    if (v >= 1.0) return 'Full';
    if (v >= 0.5) return 'Half';
    return 'Absent';
  }

  static String formatForRecord(AttendanceRecord r) =>
      _presentLabel(r.isPresent);
}
