import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/attendance_record.dart';
import '../models/worker.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static const _dbName = 'labortrack.db';
  static const _dbVersion = 2;

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final dir = await getDatabasesPath();
    final path = p.join(dir, _dbName);
    _db = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
    return _db!;
  }

  Future<void> _onUpgrade(Database db, int oldV, int newV) async {
    if (oldV < 2) {
      await db.execute(
        "ALTER TABLE attendance ADD COLUMN settledAt INTEGER NOT NULL DEFAULT 0",
      );
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE workers(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        role TEXT NOT NULL DEFAULT '',
        baseDailyRate REAL NOT NULL,
        otHourlyRate REAL NOT NULL,
        joiningDate INTEGER NOT NULL,
        isActive INTEGER NOT NULL DEFAULT 1
      );
    ''');
    await db.execute('''
      CREATE TABLE attendance(
        recordId INTEGER PRIMARY KEY AUTOINCREMENT,
        workerId INTEGER NOT NULL,
        date INTEGER NOT NULL,
        isPresent REAL NOT NULL,
        overTimeHours REAL NOT NULL,
        upadAmount REAL NOT NULL,
        paymentMethod TEXT NOT NULL DEFAULT '',
        remarks TEXT NOT NULL DEFAULT '',
        calculatedTotal REAL NOT NULL,
        settledAt INTEGER NOT NULL DEFAULT 0,
        UNIQUE(workerId, date),
        FOREIGN KEY(workerId) REFERENCES workers(id) ON DELETE CASCADE
      );
    ''');
    await db.execute(
      'CREATE INDEX idx_att_worker_date ON attendance(workerId, date);',
    );
  }

  // ===== Workers =====
  Future<int> insertWorker(Worker w) async {
    final db = await database;
    return db.insert('workers', w.toMap()..remove('id'));
  }

  Future<int> updateWorker(Worker w) async {
    final db = await database;
    return db.update('workers', w.toMap(), where: 'id = ?', whereArgs: [w.id]);
  }

  Future<int> deleteWorker(int id) async {
    final db = await database;
    return db.delete('workers', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Worker>> getWorkers({bool activeOnly = false}) async {
    final db = await database;
    final rows = await db.query(
      'workers',
      where: activeOnly ? 'isActive = 1' : null,
      orderBy: 'name COLLATE NOCASE',
    );
    return rows.map(Worker.fromMap).toList();
  }

  Future<Worker?> getWorker(int id) async {
    final db = await database;
    final rows = await db.query('workers', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Worker.fromMap(rows.first);
  }

  // ===== Attendance =====
  Future<int> upsertAttendance(AttendanceRecord r) async {
    final db = await database;
    return db.insert(
      'attendance',
      r.toMap()..remove('recordId'),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<AttendanceRecord?> getRecord(int workerId, int date) async {
    final db = await database;
    final rows = await db.query(
      'attendance',
      where: 'workerId = ? AND date = ?',
      whereArgs: [workerId, date],
    );
    if (rows.isEmpty) return null;
    return AttendanceRecord.fromMap(rows.first);
  }

  Future<List<AttendanceRecord>> getRecordsForDate(int date) async {
    final db = await database;
    final rows = await db.query(
      'attendance',
      where: 'date = ?',
      whereArgs: [date],
    );
    return rows.map(AttendanceRecord.fromMap).toList();
  }

  Future<List<AttendanceRecord>> getRecordsForWorker(int workerId) async {
    final db = await database;
    final rows = await db.query(
      'attendance',
      where: 'workerId = ?',
      whereArgs: [workerId],
      orderBy: 'date DESC',
    );
    return rows.map(AttendanceRecord.fromMap).toList();
  }

  Future<List<AttendanceRecord>> getAllRecords() async {
    final db = await database;
    final rows = await db.query(
      'attendance',
      orderBy: 'date DESC, workerId ASC',
    );
    return rows.map(AttendanceRecord.fromMap).toList();
  }

  Future<int> deleteRecord(int recordId) async {
    final db = await database;
    return db.delete(
      'attendance',
      where: 'recordId = ?',
      whereArgs: [recordId],
    );
  }

  /// Mark every unsettled record for [workerId] as settled (snapshot at now).
  /// Returns number of rows affected.
  Future<int> settleWorker(int workerId) async {
    final db = await database;
    return db.update(
      'attendance',
      {'settledAt': DateTime.now().millisecondsSinceEpoch},
      where: 'workerId = ? AND settledAt = 0',
      whereArgs: [workerId],
    );
  }

  /// Net pending across all workers from unsettled records only.
  Future<({double earned, double upad, double pending})>
  getUnsettledTotals() async {
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT IFNULL(SUM(calculatedTotal),0) AS e, IFNULL(SUM(upadAmount),0) AS u '
      'FROM attendance WHERE settledAt = 0',
    );
    final e = (rows.first['e'] as num).toDouble();
    final u = (rows.first['u'] as num).toDouble();
    return (earned: e, upad: u, pending: e - u);
  }
}
