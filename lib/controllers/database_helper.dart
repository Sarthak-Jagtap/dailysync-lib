// database_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/material.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('todo.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2, // Incremented version for priority column
      onCreate: _createDB,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Migration: Add priority column to existing tasks table
          await db.execute('ALTER TABLE tasks ADD COLUMN priority INTEGER DEFAULT 3');
        }
      },
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';
    const textTypeNull = 'TEXT';

    // Create Tasks Table with priority column
    await db.execute('''
    CREATE TABLE tasks (
      id $idType,
      title $textType,
      description $textTypeNull,
      completed $intType,
      date $textType,
      category $textType,
      color $intType,
      priority $intType DEFAULT 3
    )
    ''');

    // Create Categories Table
    await db.execute('''
    CREATE TABLE categories (
      id $idType,
      name $textType UNIQUE
    )
    ''');

    // Insert default categories
    await db.insert('categories', {'name': 'All'});
    await db.insert('categories', {'name': 'Home'});
    await db.insert('categories', {'name': 'Work'});
    await db.insert('categories', {'name': 'Personal'});
    await db.insert('categories', {'name': 'Study'});
  }

  // --- Task Methods ---

  Future<int> insertTask(Map<String, dynamic> task) async {
    try {
      final db = await instance.database;
      
      // Create a copy without id to avoid conflicts
      final taskToInsert = Map<String, dynamic>.from(task);
      taskToInsert.remove('id');
      
      // Ensure priority has a default value if not provided
      if (!taskToInsert.containsKey('priority')) {
        taskToInsert['priority'] = 3;
      }
      
      final id = await db.insert('tasks', taskToInsert);
      return id;
    } catch (e) {
      debugPrint('Error inserting task: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getTask(int id) async {
    try {
      final db = await instance.database;
      final result = await db.query(
        'tasks',
        where: 'id = ?',
        whereArgs: [id],
      );
      return result.isNotEmpty ? result.first : null;
    } catch (e) {
      debugPrint('Error getting task: $e');
      return null;
    }
  }

  Future<int> updateTask(Map<String, dynamic> task) async {
    try {
      final db = await instance.database;
      final id = task['id'];
      if (id == null) {
        throw Exception('Task ID is null for update');
      }
      
      // Create a copy to avoid modifying original
      final taskToUpdate = Map<String, dynamic>.from(task);
      
      return await db.update(
        'tasks',
        taskToUpdate,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      debugPrint('Error updating task: $e');
      rethrow;
    }
  }

  Future<int> deleteTask(int id) async {
    try {
      final db = await instance.database;
      return await db.delete(
        'tasks',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      debugPrint('Error deleting task: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getTasks() async {
    try {
      final db = await instance.database;
      final result = await db.query('tasks', orderBy: 'id DESC');
      return result;
    } catch (e) {
      debugPrint('Error getting tasks: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getTasksByCategory(String category) async {
    try {
      final db = await instance.database;
      if (category == 'All') {
        return await db.query('tasks', orderBy: 'id DESC');
      }
      return await db.query(
        'tasks',
        where: 'category = ?',
        whereArgs: [category],
        orderBy: 'id DESC',
      );
    } catch (e) {
      debugPrint('Error getting tasks by category: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getCompletedTasks() async {
    try {
      final db = await instance.database;
      return await db.query(
        'tasks',
        where: 'completed = ?',
        whereArgs: [1],
        orderBy: 'id DESC',
      );
    } catch (e) {
      debugPrint('Error getting completed tasks: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getPendingTasks() async {
    try {
      final db = await instance.database;
      return await db.query(
        'tasks',
        where: 'completed = ?',
        whereArgs: [0],
        orderBy: 'id DESC',
      );
    } catch (e) {
      debugPrint('Error getting pending tasks: $e');
      return [];
    }
  }

  Future<int> toggleTaskCompletion(int id, int completed) async {
    try {
      final db = await instance.database;
      return await db.update(
        'tasks',
        {'completed': completed},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      debugPrint('Error toggling task completion: $e');
      rethrow;
    }
  }

  Future<int> updateTaskPriority(int id, int priority) async {
    try {
      final db = await instance.database;
      return await db.update(
        'tasks',
        {'priority': priority},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      debugPrint('Error updating task priority: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getTasksByPriority(int priority) async {
    try {
      final db = await instance.database;
      return await db.query(
        'tasks',
        where: 'priority = ?',
        whereArgs: [priority],
        orderBy: 'id DESC',
      );
    } catch (e) {
      debugPrint('Error getting tasks by priority: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> searchTasks(String query) async {
    try {
      final db = await instance.database;
      return await db.query(
        'tasks',
        where: 'title LIKE ? OR description LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
        orderBy: 'id DESC',
      );
    } catch (e) {
      debugPrint('Error searching tasks: $e');
      return [];
    }
  }

  // --- Category Methods ---

  Future<int> insertCategory(String name) async {
    try {
      final db = await instance.database;
      return await db.insert(
        'categories', 
        {'name': name},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    } catch (e) {
      debugPrint('Error inserting category: $e');
      return -1;
    }
  }

  Future<int> deleteCategory(String name) async {
    try {
      final db = await instance.database;
      
      if (name == 'All') {
        throw Exception('Cannot delete the "All" category');
      }

      // 1. Move tasks from this category to 'All'
      await db.update(
        'tasks',
        {'category': 'All'},
        where: 'category = ?',
        whereArgs: [name],
      );

      // 2. Delete the category
      return await db.delete(
        'categories',
        where: 'name = ?',
        whereArgs: [name],
      );
    } catch (e) {
      debugPrint('Error deleting category: $e');
      rethrow;
    }
  }

  Future<List<String>> getCategories() async {
    try {
      final db = await instance.database;
      final result = await db.query('categories', orderBy: 'id ASC');
      
      List<String> categories = result.map((e) => e['name'] as String).toList();
      
      // Ensure "All" is always first if it exists
      if (categories.contains("All")) {
        categories.remove("All");
        categories.insert(0, "All");
      }
      
      return categories;
    } catch (e) {
      debugPrint('Error getting categories: $e');
      return ['All', 'Home', 'Work', 'Personal', 'Study'];
    }
  }

  Future<int> updateTaskCategory(int taskId, String newCategory) async {
    try {
      final db = await instance.database;
      return await db.update(
        'tasks',
        {'category': newCategory},
        where: 'id = ?',
        whereArgs: [taskId],
      );
    } catch (e) {
      debugPrint('Error updating task category: $e');
      rethrow;
    }
  }

  // --- Statistics Methods ---

  Future<int> getTaskCount() async {
    try {
      final db = await instance.database;
      final result = await db.rawQuery('SELECT COUNT(*) FROM tasks');
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      debugPrint('Error getting task count: $e');
      return 0;
    }
  }

  Future<int> getCompletedTaskCount() async {
    try {
      final db = await instance.database;
      final result = await db.rawQuery('SELECT COUNT(*) FROM tasks WHERE completed = 1');
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      debugPrint('Error getting completed task count: $e');
      return 0;
    }
  }

  Future<int> getPendingTaskCount() async {
    try {
      final db = await instance.database;
      final result = await db.rawQuery('SELECT COUNT(*) FROM tasks WHERE completed = 0');
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      debugPrint('Error getting pending task count: $e');
      return 0;
    }
  }

  Future<Map<String, int>> getTasksCountByCategory() async {
    try {
      final db = await instance.database;
      final result = await db.rawQuery('''
        SELECT category, COUNT(*) as count 
        FROM tasks 
        GROUP BY category
      ''');
      
      Map<String, int> categoryCounts = {};
      for (var row in result) {
        categoryCounts[row['category'] as String] = row['count'] as int;
      }
      
      return categoryCounts;
    } catch (e) {
      debugPrint('Error getting tasks count by category: $e');
      return {};
    }
  }

  Future<Map<String, int>> getTasksCountByPriority() async {
    try {
      final db = await instance.database;
      final result = await db.rawQuery('''
        SELECT priority, COUNT(*) as count 
        FROM tasks 
        GROUP BY priority
      ''');
      
      Map<String, int> priorityCounts = {};
      for (var row in result) {
        priorityCounts[row['priority'].toString()] = row['count'] as int;
      }
      
      return priorityCounts;
    } catch (e) {
      debugPrint('Error getting tasks count by priority: $e');
      return {};
    }
  }

  // --- Database Maintenance Methods ---

  Future<void> clearDatabase() async {
    try {
      final db = await instance.database;
      await db.delete('tasks');
      await db.delete('categories');
      
      // Recreate default categories
      await db.insert('categories', {'name': 'All'});
      await db.insert('categories', {'name': 'Home'});
      await db.insert('categories', {'name': 'Work'});
      await db.insert('categories', {'name': 'Personal'});
      await db.insert('categories', {'name': 'Study'});
    } catch (e) {
      debugPrint('Error clearing database: $e');
      rethrow;
    }
  }

  Future<void> deleteAllTasks() async {
    try {
      final db = await instance.database;
      await db.delete('tasks');
    } catch (e) {
      debugPrint('Error deleting all tasks: $e');
      rethrow;
    }
  }

  Future<void> deleteAllCategories() async {
    try {
      final db = await instance.database;
      await db.delete('categories');
      
      // Recreate default categories
      await db.insert('categories', {'name': 'All'});
      await db.insert('categories', {'name': 'Home'});
      await db.insert('categories', {'name': 'Work'});
      await db.insert('categories', {'name': 'Personal'});
      await db.insert('categories', {'name': 'Study'});
    } catch (e) {
      debugPrint('Error deleting all categories: $e');
      rethrow;
    }
  }

  Future<void> close() async {
    final db = await instance.database;
    await db.close();
  }
}