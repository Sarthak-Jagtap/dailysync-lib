// lib/routine_manager/db/routine_db_helper.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:intl/intl.dart';
import '../models/routine_models.dart';

class RoutineDbHelper {
  static final RoutineDbHelper _instance = RoutineDbHelper._internal();
  factory RoutineDbHelper() => _instance;
  RoutineDbHelper._internal();

  static Database? _db;

  // --- Database Initialization ---

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'dailysync_routine.db');
    debugPrint("Database path (Routine): $path");
    // ****** INCREMENT VERSION FOR SCHEMA CHANGE ******
    return await openDatabase(path, version: 2, onCreate: _onCreate, onUpgrade: _onUpgrade);
  }

  Future _onCreate(Database db, int version) async {
    await _createV1Tables(db);
    // Apply V2 changes if creating from scratch (shouldn't happen if upgrading)
    if (version >= 2) {
        await _upgradeToV2(db);
    }
  }

  // Handle schema migration
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
     debugPrint("Upgrading routine database from $oldVersion to $newVersion");
     if (oldVersion < 2) {
       await _upgradeToV2(db);
     }
     // Add more upgrade steps here if needed in the future
  }

  // --- Schema Creation/Migration Helpers ---

  Future<void> _createV1Tables(Database db) async {
     // Master Template Table
    await db.execute('''
      CREATE TABLE routine_template (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        task_title TEXT NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT NOT NULL,
        category TEXT NOT NULL
      );
    ''');
    // Daily Log Table
    await db.execute('''
      CREATE TABLE routine_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        template_id INTEGER,
        date TEXT NOT NULL,
        task_title TEXT NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT NOT NULL,
        category TEXT NOT NULL,
        is_completed INTEGER NOT NULL DEFAULT 0
        /* Removed FOREIGN KEY constraint temporarily for easier template updates
           FOREIGN KEY (template_id) REFERENCES routine_template (id) ON DELETE CASCADE */
      );
    ''');
    await db.execute('CREATE INDEX idx_logs_date ON routine_logs (date)');
    debugPrint("Routine database V1 tables created.");
  }

  Future<void> _upgradeToV2(Database db) async {
      // Add the is_skipped column to routine_logs
      await db.execute('ALTER TABLE routine_logs ADD COLUMN is_skipped INTEGER NOT NULL DEFAULT 0');
      debugPrint("Routine database upgraded to V2 (added is_skipped column).");
  }

  // --- Template Methods ---

  Future<bool> hasMasterTemplate() async {
    final dbClient = await db;
    final count = Sqflite.firstIntValue(await dbClient.rawQuery(
      'SELECT COUNT(*) FROM routine_template'
    ));
    return (count ?? 0) > 0;
  }

  Future<void> saveNewTemplate(List<RoutineTask> tasks) async {
    final dbClient = await db;
    await dbClient.transaction((txn) async {
      await txn.delete('routine_template');
      await txn.delete('routine_logs');
      Batch batch = txn.batch();
      for (final task in tasks) {
        final taskJson = task.toJson();
        taskJson.remove('id');
        batch.insert('routine_template', taskJson);
      }
      await batch.commit(noResult: true);
    });
    debugPrint("New master routine template saved. All old logs cleared.");
  }

  /// Updates the master template. Clears only FUTURE logs. Used for manual edits.
  Future<void> updateTemplate(List<RoutineTask> tasks) async { // <-- DEFINED HERE
      final dbClient = await db;
      final todayString = DateFormat('yyyy-MM-dd').format(DateTime.now());

      await dbClient.transaction((txn) async {
        await txn.delete('routine_template');
        await txn.delete(
          'routine_logs',
          where: 'date >= ?',
          whereArgs: [todayString],
        );
        Batch batch = txn.batch();
        for (final task in tasks) {
           final taskJson = task.toJson();
           taskJson.remove('id');
           batch.insert('routine_template', taskJson);
        }
        await batch.commit(noResult: true);
      });
      debugPrint("Master routine template updated. Logs from $todayString onwards cleared.");
   }


  Future<List<RoutineTask>> getMasterTemplate() async {
    final dbClient = await db;
    final maps = await dbClient.query('routine_template', orderBy: 'substr(start_time, 1, 2), substr(start_time, 4, 2)');
    List<RoutineTask> tasks = [];
    for(int i = 0; i < maps.length; i++) {
        final taskMap = Map<String, dynamic>.from(maps[i]);
        tasks.add(RoutineTask.fromJson(taskMap));
    }
    return tasks;
  }

  // --- Daily Log Methods ---

  Future<List<DailyRoutineTask>> getDailyLog(DateTime date) async {
    final dbClient = await db;
    final dateString = DateFormat('yyyy-MM-dd').format(date);

    final logMaps = await dbClient.query(
      'routine_logs',
      where: 'date = ?',
      whereArgs: [dateString],
      orderBy: 'substr(start_time, 1, 2), substr(start_time, 4, 2)'
    );

    if (logMaps.isNotEmpty) {
      debugPrint("Loaded daily log for $dateString from DB.");
      return logMaps.map((json) => DailyRoutineTask.fromJson(json)).toList();
    }

    debugPrint("No log for $dateString. Creating from template...");
    final templateTasks = await getMasterTemplate();
    if (templateTasks.isEmpty) {
      debugPrint("Cannot create log: Master template is empty.");
      return [];
    }

    Batch batch = dbClient.batch();
    for (final task in templateTasks) {
      final logEntry = {
        'template_id': task.id,
        'date': dateString,
        'task_title': task.taskTitle,
        'start_time': task.startTime,
        'end_time': task.endTime,
        'category': task.category,
        'is_completed': 0,
        'is_skipped': 0,
      };
      batch.insert('routine_logs', logEntry);
    }

    await batch.commit(noResult: true);
    debugPrint("New log created for $dateString.");

    final newLogMaps = await dbClient.query(
      'routine_logs',
      where: 'date = ?',
      whereArgs: [dateString],
      orderBy: 'substr(start_time, 1, 2), substr(start_time, 4, 2)'
    );
    return newLogMaps.map((json) => DailyRoutineTask.fromJson(json)).toList();
  }

  Future<int> updateDailyTaskStatus(int logId, bool isCompleted) async {
    final dbClient = await db;
    debugPrint("Updating logId $logId completion to $isCompleted");
    return await dbClient.update(
      'routine_logs',
      {'is_completed': isCompleted ? 1 : 0},
      where: 'id = ?',
      whereArgs: [logId]
    );
  }

  /// Updates the skipped status of a single log item (New for V2)
  Future<int> updateDailyTaskSkipped(int logId, bool isSkipped) async { // <-- DEFINED HERE
    final dbClient = await db;
     debugPrint("Updating logId $logId skipped status to $isSkipped");
    return await dbClient.update(
        'routine_logs',
        {'is_skipped': isSkipped ? 1 : 0},
        where: 'id = ?',
        whereArgs: [logId]
    );
  }


  // --- Summary/Stats Methods ---

  Future<Map<String, double>> getCompletionSummary({int days = 7}) async {
    final dbClient = await db;
    final Map<String, double> summary = {};

    for (int i = 0; i < days; i++) {
      final day = DateTime.now().subtract(Duration(days: i));
      final dayString = DateFormat('yyyy-MM-dd').format(day);
      summary[dayString] = 0.0;
    }

    final startDate = DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(Duration(days: days - 1)));
    final endDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final result = await dbClient.rawQuery('''
      SELECT
        date,
        SUM(CASE WHEN is_completed = 1 AND is_skipped = 0 THEN 1 ELSE 0 END) as completed_count,
        SUM(CASE WHEN is_skipped = 0 THEN 1 ELSE 0 END) as total_relevant
      FROM routine_logs
      WHERE date BETWEEN ? AND ?
      GROUP BY date
    ''', [startDate, endDate]);

    for (var row in result) {
      final date = row['date'] as String;
      final completed = (row['completed_count'] as int?) ?? 0;
      final totalRelevant = (row['total_relevant'] as int?) ?? 0;

      if (summary.containsKey(date)) {
         summary[date] = (totalRelevant > 0) ? (completed / totalRelevant) : 0.0;
      }
    }
    debugPrint("Routine Summary: $summary");
    return summary;
  }

  // --- Close Database ---
  Future close() async {
    final dbClient = await db;
    _db = null;
    await dbClient.close();
    debugPrint("Routine database closed.");
  }
}

