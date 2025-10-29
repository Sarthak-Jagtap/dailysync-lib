// lib/health_manager/db/db_helper.dart
import 'dart:async';
import 'package:flutter/material.dart'; // Import for debugPrint
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:intl/intl.dart';
import '../models/health_models.dart';

// Helper function to format date keys consistently
String dateToKey(DateTime dt) => DateFormat('yyyy-MM-dd').format(dt);


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
    debugPrint("Database path: $path"); // Log DB path
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  // Define table creation queries
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
        date TEXT NOT NULL UNIQUE,
        morningDryFruits INTEGER DEFAULT 0,
        breakfast INTEGER DEFAULT 0,
        lunch INTEGER DEFAULT 0,
        snacks INTEGER DEFAULT 0,
        dinner INTEGER DEFAULT 0
      );
    ''');
    await db.execute('''
      CREATE TABLE steps (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL UNIQUE,
        steps INTEGER NOT NULL DEFAULT 0,
        target INTEGER
      );
    ''');
    await db.execute('''
      CREATE TABLE sleep (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL UNIQUE,
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
     debugPrint("Database tables created.");
  }

  // --- Insert/Update Methods ---

  Future<int> insertWater(WaterEntry w) async {
    try {
      final dbClient = await db;
      return await dbClient.insert('water', w.toMap());
    } catch (e) {
      debugPrint("Error inserting water: $e");
      rethrow;
    }
  }

  Future<int> insertDiet(DietEntry d) async {
     try {
        final dbClient = await db;
        // Use replace conflict algorithm since date is UNIQUE
        return await dbClient.insert('diet', d.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace);
     } catch (e) {
       debugPrint("Error inserting/updating diet: $e");
       rethrow;
     }
  }

  Future<int> insertSteps(StepsEntry s) async {
     try {
        final dbClient = await db;
        final existing = await dbClient
            .query('steps', where: 'date = ?', whereArgs: [s.date], limit: 1);
        if (existing.isNotEmpty) {
          // Update: Aggregate steps
          final prev = StepsEntry.fromMap(existing.first);
          final total = prev.steps + s.steps;
          debugPrint("Updating steps for ${s.date}: ${prev.steps} + ${s.steps} = $total");
          return await dbClient.update('steps',
              {'steps': total, 'target': s.target ?? prev.target}, // Update target if provided
              where: 'date = ?', whereArgs: [s.date]);
        } else {
          // Insert new entry
           debugPrint("Inserting new steps for ${s.date}: ${s.steps}");
           // Explicitly map fields for clarity
           final Map<String, dynamic> stepMap = {
              'date': s.date,
              'steps': s.steps,
              'target': s.target, // Will be null if not provided
           };
           return await dbClient.insert('steps', stepMap);
        }
     } catch (e) {
       debugPrint("Error inserting/updating steps: $e");
       rethrow;
     }
  }

  Future<int> insertSleep(SleepEntry s) async {
    try {
      final dbClient = await db;
      // Use replace conflict algorithm since date is UNIQUE
      return await dbClient.insert('sleep', s.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
       debugPrint("Error inserting/updating sleep: $e");
       rethrow;
    }
  }

  Future<int> insertExercise(ExerciseEntry e) async {
     try {
        final dbClient = await db;
        return await dbClient.insert('exercise', e.toMap());
     } catch (e) {
       debugPrint("Error inserting exercise: $e");
       rethrow;
     }
  }

  // --- Fetch Single Day ---

  // Fetches ALL water entries for a specific date (water isn't aggregated daily)
  Future<List<WaterEntry>> getWaterByDate(String date) async {
    try {
      final dbClient = await db;
      final rows = await dbClient.query('water', where: 'date = ?', whereArgs: [date]);
      return rows.map((r) => WaterEntry.fromMap(r)).toList();
    } catch (e) {
      debugPrint("Error fetching water for date $date: $e");
      return [];
    }
  }

  // Fetches the single diet entry for a specific date (date is UNIQUE)
  Future<DietEntry?> getDietByDate(String date) async {
     try {
        final dbClient = await db;
        final rows = await dbClient.query('diet', where: 'date = ?', whereArgs: [date], limit: 1);
        if (rows.isEmpty) return null;
        return DietEntry.fromMap(rows.first);
     } catch (e) {
       debugPrint("Error fetching diet for date $date: $e");
       return null;
     }
  }

  // Fetches the single aggregated steps entry for a specific date (date is UNIQUE)
  Future<StepsEntry?> getStepsByDate(String date) async {
    try {
      final dbClient = await db;
      final rows = await dbClient.query('steps', where: 'date = ?', whereArgs: [date], limit: 1);
      if (rows.isEmpty) return null;
      return StepsEntry.fromMap(rows.first);
    } catch (e) {
       debugPrint("Error fetching steps for date $date: $e");
       return null;
    }
  }

  // Fetches the single sleep entry for a specific date (date is UNIQUE)
  Future<SleepEntry?> getSleepByDate(String date) async {
    try {
      final dbClient = await db;
      final rows =
          await dbClient.query('sleep', where: 'date = ?', whereArgs: [date], limit: 1);
      if (rows.isEmpty) return null;
      return SleepEntry.fromMap(rows.first);
     } catch (e) {
       debugPrint("Error fetching sleep for date $date: $e");
       return null;
     }
  }

  // --- Weekly Aggregations ---

  // Generic helper to get SUM for a column over a date range, ensuring all days are present
  Future<Map<String, int>> getWeeklySum(String table, String valueColumn, DateTime startDate, DateTime endDate) async {
    try {
      final dbClient = await db;
      Map<String, int> result = {};

      // Initialize map with all days of the week set to 0
      for (int i = 0; i < 7; i++) {
          final currentDay = startDate.add(Duration(days: i));
          final key = dateToKey(currentDay);
          result[key] = 0;
      }

      final startKey = dateToKey(startDate);
      final endKey = dateToKey(endDate);

      final rows = await dbClient.rawQuery(
        'SELECT date, SUM($valueColumn) as total FROM $table WHERE date BETWEEN ? AND ? GROUP BY date',
        [startKey, endKey]
      );

      // Populate map with actual sums from the database
      for (var row in rows) {
          final date = row['date'] as String;
          final total = row['total'] as int? ?? 0;
          if (result.containsKey(date)) { // Should always be true due to initialization
              result[date] = total;
          }
      }

      // Sort the map by date key before returning
      var sortedResult = Map.fromEntries(
          result.entries.toList()..sort((a, b) => a.key.compareTo(b.key))
      );
      return sortedResult;
     } catch (e) {
       debugPrint("Error getting weekly sum for $table.$valueColumn: $e");
       return {}; // Return empty map on error
     }
  }

  // Specific weekly sum methods using the generic helper or custom logic
  Future<Map<String, int>> weeklyWaterSum(DateTime startDate, DateTime endDate) async {
      // Water entries are not aggregated daily, so SUM works correctly
      return await getWeeklySum('water', 'glasses', startDate, endDate);
  }

  Future<Map<String, int>> weeklyStepsSum(DateTime startDate, DateTime endDate) async {
      // Steps are already aggregated daily, so select 'steps' directly
      try {
        final dbClient = await db;
        Map<String, int> result = {};
        for (int i = 0; i < 7; i++) {
            final currentDay = startDate.add(Duration(days: i));
            result[dateToKey(currentDay)] = 0; // Initialize
        }
        final startKey = dateToKey(startDate);
        final endKey = dateToKey(endDate);
        final rows = await dbClient.rawQuery(
          'SELECT date, steps FROM steps WHERE date BETWEEN ? AND ?', // Select steps, not SUM(steps)
          [startKey, endKey]
        );
        for (var row in rows) {
             final date = row['date'] as String;
             final steps = row['steps'] as int? ?? 0;
             if (result.containsKey(date)) {
                 result[date] = steps;
             }
        }
        return Map.fromEntries(result.entries.toList()..sort((a,b)=>a.key.compareTo(b.key)));
      } catch (e) {
        debugPrint("Error getting weekly steps sum: $e");
        return {};
      }
  }

   Future<Map<String, int>> weeklyExerciseSum(DateTime startDate, DateTime endDate) async {
      // Exercise entries are not aggregated daily, so SUM works correctly
      return await getWeeklySum('exercise', 'minutes', startDate, endDate);
  }

  Future<Map<String, int>> weeklySleepSum(DateTime startDate, DateTime endDate) async {
      // Sleep is aggregated daily (UNIQUE date), so select 'minutes' directly
      try {
        final dbClient = await db;
        Map<String, int> result = {};
        for (int i = 0; i < 7; i++) {
            final currentDay = startDate.add(Duration(days: i));
            result[dateToKey(currentDay)] = 0; // Initialize
        }
        final startKey = dateToKey(startDate);
        final endKey = dateToKey(endDate);
        final rows = await dbClient.rawQuery(
          'SELECT date, minutes FROM sleep WHERE date BETWEEN ? AND ?', // Select minutes
          [startKey, endKey]
        );
        for (var row in rows) {
            final date = row['date'] as String;
            final minutes = row['minutes'] as int? ?? 0;
            if (result.containsKey(date)) {
                result[date] = minutes;
            }
        }
        return Map.fromEntries(result.entries.toList()..sort((a,b)=>a.key.compareTo(b.key)));
       } catch (e) {
         debugPrint("Error getting weekly sleep sum: $e");
         return {};
       }
  }

  // --- Weekly Diet Specific ---
  Future<List<DietEntry>> getWeeklyDietEntries(DateTime startDate, DateTime endDate) async {
    try {
      final dbClient = await db;
      final startKey = dateToKey(startDate);
      final endKey = dateToKey(endDate);
      final rows = await dbClient.rawQuery(
          'SELECT * FROM diet WHERE date BETWEEN ? AND ? ORDER BY date ASC',
          [startKey, endKey]);
      return rows.map((r) => DietEntry.fromMap(r)).toList();
    } catch (e) {
       debugPrint("Error fetching weekly diet entries: $e");
       return [];
    }
  }


  Future<int> countWeeklyDietLogs(DateTime startDate, DateTime endDate) async {
    try {
      final dbClient = await db;
      final startKey = dateToKey(startDate);
      final endKey = dateToKey(endDate);
      // COUNT(DISTINCT date) is appropriate here
      final result = await dbClient.rawQuery(
          'SELECT COUNT(DISTINCT date) as count FROM diet WHERE date BETWEEN ? AND ?',
          [startKey, endKey]);
      return Sqflite.firstIntValue(result) ?? 0;
     } catch (e) {
       debugPrint("Error counting weekly diet logs: $e");
       return 0;
     }
  }


  // --- History Fetch Helpers ---
  Future<List<Map<String, dynamic>>> getAllRecordsForTableLastNDays(
      String table, DateTime end, int n) async {
    try {
      final dbClient = await db;
      // Ensure n is positive
      final daysToSubtract = n > 0 ? n - 1 : 0;
      final start = end.subtract(Duration(days: daysToSubtract));
      final startKey = dateToKey(start);
      final endKey = dateToKey(end);
      return await dbClient.rawQuery(
          'SELECT * FROM $table WHERE date BETWEEN ? AND ? ORDER BY date DESC',
          [startKey, endKey]);
     } catch (e) {
       debugPrint("Error getting history for $table: $e");
       return [];
     }
  }

  // Method to close the database
  Future close() async {
    final dbClient = await db;
    _db = null; // Clear the static instance
    await dbClient.close();
    debugPrint("Database closed.");
  }
}

