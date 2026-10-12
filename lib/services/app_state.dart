import 'package:flutter/foundation.dart';

import '../database/database_helper.dart';
import '../models/attendance_record.dart';
import '../models/worker.dart';

/// Simple app-wide state: workers list + today's attendance for the dashboard.
class AppState extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<Worker> _workers = [];
  List<Worker> get workers => _workers;
  List<Worker> get activeWorkers => _workers.where((w) => w.isActive).toList();

  Map<int, AttendanceRecord> _todayRecords = {};
  Map<int, AttendanceRecord> get todayRecords => _todayRecords;

  bool _loading = true;
  bool get loading => _loading;

  static int normalizeDate(DateTime d) =>
      DateTime(d.year, d.month, d.day).millisecondsSinceEpoch;

  Future<void> init() async {
    _loading = true;
    notifyListeners();
    await refresh();
    _loading = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    _workers = await _db.getWorkers();
    final today = normalizeDate(DateTime.now());
    final recs = await _db.getRecordsForDate(today);
    _todayRecords = {for (final r in recs) r.workerId: r};
    notifyListeners();
  }

  Future<void> addWorker(Worker w) async {
    await _db.insertWorker(w);
    await refresh();
  }

  Future<void> updateWorker(Worker w) async {
    await _db.updateWorker(w);
    await refresh();
  }

  Future<void> deleteWorker(int id) async {
    await _db.deleteWorker(id);
    await refresh();
  }

  Future<void> saveAttendance(AttendanceRecord r) async {
    await _db.upsertAttendance(r);
    await refresh();
  }
}
