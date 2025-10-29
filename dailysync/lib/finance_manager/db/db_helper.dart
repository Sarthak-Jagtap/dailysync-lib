// lib/finance_manager/db/db_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/material.dart';
import '../models/expense_model.dart'; // Import the model

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();

  static Database? _db;
  static const String _dbName = 'finance_manager.db';
  static const String _tableName = 'expenses';
  static const int _dbVersion = 1;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    debugPrint('Database path: $path'); // Log path
    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        date TEXT NOT NULL,
        paymentType TEXT NOT NULL,
        description TEXT,
        merchant TEXT
      )
    ''');
    debugPrint('Expenses table created.'); // Log creation
  }

  // --- Expense Methods ---

  Future<int> insertExpense(Expense expense) async {
    try {
      final dbClient = await database;
      final map = expense.toMap();
      map.remove('id'); // Remove id for insertion
      final id = await dbClient.insert(_tableName, map,
          conflictAlgorithm: ConflictAlgorithm.replace);
      debugPrint('Inserted expense with ID: $id'); // Log insertion
      return id;
    } catch (e) {
      debugPrint('Error inserting expense: $e');
      rethrow;
    }
  }

  Future<List<Expense>> getExpenses() async {
    try {
      final dbClient = await database;
      final List<Map<String, dynamic>> maps = await dbClient.query(
        _tableName,
        orderBy: 'date DESC', // Order by date, newest first
      );
      debugPrint('Fetched ${maps.length} expenses.'); // Log fetch
      if (maps.isEmpty) {
        return [];
      }
      return List.generate(maps.length, (i) {
        return Expense.fromMap(maps[i]);
      });
    } catch (e) {
      debugPrint('Error getting expenses: $e');
      return [];
    }
  }

  Future<int> updateExpense(Expense expense) async {
    try {
      if (expense.id == null) {
        debugPrint('Error: Cannot update expense with null ID.');
        return 0;
      }
      final dbClient = await database;
      final map = expense.toMap();
      map.remove('id'); // Remove id from map for update
      final rowsAffected = await dbClient.update(
        _tableName,
        map,
        where: 'id = ?',
        whereArgs: [expense.id],
      );
      debugPrint('Updated expense ID: ${expense.id}, Rows affected: $rowsAffected'); // Log update
      return rowsAffected;
    } catch (e) {
      debugPrint('Error updating expense: $e');
      rethrow;
    }
  }

  Future<int> deleteExpense(int id) async {
    try {
      final dbClient = await database;
      final rowsAffected = await dbClient.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
      debugPrint('Deleted expense ID: $id, Rows affected: $rowsAffected'); // Log deletion
      return rowsAffected;
    } catch (e) {
      debugPrint('Error deleting expense: $e');
      rethrow;
    }
  }

  // --- Aggregation/Reporting Methods (Examples) ---

  Future<double> getTotalExpensesForPeriod(DateTime start, DateTime end) async {
    try {
      final dbClient = await database;
      final result = await dbClient.rawQuery(
        'SELECT SUM(amount) as total FROM $_tableName WHERE date BETWEEN ? AND ?',
        [start.toIso8601String(), end.toIso8601String()],
      );
      final total = result.first['total'] as double? ?? 0.0;
      debugPrint('Total expenses from $start to $end: $total'); // Log aggregation
      return total;
    } catch (e) {
      debugPrint('Error calculating total expenses: $e');
      return 0.0;
    }
  }

  Future<Map<String, double>> getExpensesByCategoryForPeriod(DateTime start, DateTime end) async {
    try {
        final dbClient = await database;
        final List<Map<String, dynamic>> result = await dbClient.rawQuery(
            'SELECT category, SUM(amount) as total FROM $_tableName WHERE date BETWEEN ? AND ? GROUP BY category',
            [start.toIso8601String(), end.toIso8601String()],
        );
        final Map<String, double> categoryTotals = {};
        for (var row in result) {
            categoryTotals[row['category'] as String] = (row['total'] as num?)?.toDouble() ?? 0.0;
        }
        debugPrint('Expenses by category: $categoryTotals'); // Log category totals
        return categoryTotals;
    } catch (e) {
        debugPrint('Error getting expenses by category: $e');
        return {};
    }
}


  Future<void> close() async {
    final dbClient = await database;
    await dbClient.close();
    _db = null; // Reset the static instance
    debugPrint('Database closed.'); // Log close
  }
}