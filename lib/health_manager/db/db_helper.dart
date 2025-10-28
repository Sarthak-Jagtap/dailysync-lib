// lib/health_manager/db/db_helper.dart
import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/health_models.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();

  static Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'dailysync_health.db');

    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE water (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        glasses INTEGER NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE diet (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        morningDryFruits INTEGER,
        breakfast INTEGER,
        lunch INTEGER,
        snacks INTEGER,
        dinner INTEGER
      );
    ''');

    await db.execute('''
      CREATE TABLE steps (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        steps INTEGER NOT NULL,
        target INTEGER
      );
    ''');

    await db.execute('''
      CREATE TABLE sleep (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        minutes INTEGER NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE exercise (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        type TEXT NOT NULL,
        minutes INTEGER NOT NULL
      );
    ''');
  }

  // Generic insert helpers:
  Future<int> insertWater(WaterEntry w) async {
    final dbClient = await db;
    return await dbClient.insert('water', w.toMap());
  }

  Future<int> insertDiet(DietEntry d) async {
    final dbClient = await db;
    // If an entry for the same date exists, update instead of insert
    final existing = await dbClient.query('diet', where: 'date = ?', whereArgs: [d.date]);
    if (existing.isNotEmpty) {
      return await dbClient.update('diet', d.toMap()..remove('id'), where: 'date = ?', whereArgs: [d.date]);
    }
    return await dbClient.insert('diet', d.toMap());
  }

  Future<int> insertSteps(StepsEntry s) async {
    final dbClient = await db;
    final existing = await dbClient.query('steps', where: 'date = ?', whereArgs: [s.date]);
    if (existing.isNotEmpty) {
      // update: sum steps
      final prev = StepsEntry.fromMap(existing.first);
      final total = prev.steps + s.steps;
      return await dbClient.update('steps', {'steps': total, 'target': s.target ?? prev.target}, where: 'date = ?', whereArgs: [s.date]);
    }
    return await dbClient.insert('steps', s.toMap());
  }

  Future<int> insertSleep(SleepEntry s) async {
    final dbClient = await db;
    return await dbClient.insert('sleep', s.toMap());
  }

  Future<int> insertExercise(ExerciseEntry e) async {
    final dbClient = await db;
    return await dbClient.insert('exercise', e.toMap());
  }

  // Fetch single-day lists
  Future<List<WaterEntry>> getWaterByDate(String date) async {
    final dbClient = await db;
    final rows = await dbClient.query('water', where: 'date = ?', whereArgs: [date]);
    return rows.map((r) => WaterEntry.fromMap(r)).toList();
  }

  Future<DietEntry?> getDietByDate(String date) async {
    final dbClient = await db;
    final rows = await dbClient.query('diet', where: 'date = ?', whereArgs: [date]);
    if (rows.isEmpty) return null;
    return DietEntry.fromMap(rows.first);
  }

  Future<StepsEntry?> getStepsByDate(String date) async {
    final dbClient = await db;
    final rows = await dbClient.query('steps', where: 'date = ?', whereArgs: [date]);
    if (rows.isEmpty) return null;
    return StepsEntry.fromMap(rows.first);
  }

  // Weekly aggregations: returns Map<dateString, int>
  Future<Map<String, int>> weeklyWaterSum(DateTime endDate) async {
    final dbClient = await db;
    Map<String, int> result = {};
    for (int i = 6; i >= 0; i--) {
      final d = endDate.subtract(Duration(days: i));
      final key = dateToKey(d);
      final rows = await dbClient.rawQuery('SELECT SUM(glasses) as total FROM water WHERE date = ?', [key]);
      final total = rows.first['total'] as int? ?? 0;
      result[key] = total;
    }
    return result;
  }

  Future<Map<String, int>> weeklyStepsSum(DateTime endDate) async {
    final dbClient = await db;
    Map<String, int> result = {};
    for (int i = 6; i >= 0; i--) {
      final d = endDate.subtract(Duration(days: i));
      final key = dateToKey(d);
      final rows = await dbClient.rawQuery('SELECT steps as total FROM steps WHERE date = ?', [key]);
      final total = rows.isNotEmpty ? (rows.first['total'] as int? ?? 0) : 0;
      result[key] = total;
    }
    return result;
  }

  Future<Map<String, int>> weeklySleepSum(DateTime endDate) async {
    final dbClient = await db;
    Map<String, int> result = {};
    for (int i = 6; i >= 0; i--) {
      final d = endDate.subtract(Duration(days: i));
      final key = dateToKey(d);
      final rows = await dbClient.rawQuery('SELECT SUM(minutes) as total FROM sleep WHERE date = ?', [key]);
      final total = rows.first['total'] as int? ?? 0;
      result[key] = total;
    }
    return result;
  }

  Future<Map<String, int>> weeklyExerciseSum(DateTime endDate) async {
    final dbClient = await db;
    Map<String, int> result = {};
    for (int i = 6; i >= 0; i--) {
      final d = endDate.subtract(Duration(days: i));
      final key = dateToKey(d);
      final rows = await dbClient.rawQuery('SELECT SUM(minutes) as total FROM exercise WHERE date = ?', [key]);
      final total = rows.first['total'] as int? ?? 0;
      result[key] = total;
    }
    return result;
  }

  // Fetch diet history last 7 days
  Future<List<DietEntry>> getDietLastNDays(DateTime endDate, int n) async {
    final dbClient = await db;
    final start = endDate.subtract(Duration(days: n - 1));
    final startKey = dateToKey(start);
    final endKey = dateToKey(endDate);
    final rows = await dbClient.rawQuery('SELECT * FROM diet WHERE date BETWEEN ? AND ? ORDER BY date ASC', [startKey, endKey]);
    return rows.map((r) => DietEntry.fromMap(r)).toList();
  }

  // Generic history queries (last N days)
  Future<List<Map<String, dynamic>>> getAllRecordsForTableLastNDays(String table, DateTime end, int n) async {
    final dbClient = await db;
    final start = end.subtract(Duration(days: n - 1));
    final startKey = dateToKey(start);
    final endKey = dateToKey(end);
    return await dbClient.rawQuery('SELECT * FROM $table WHERE date BETWEEN ? AND ? ORDER BY date DESC', [startKey, endKey]);
  }
}
