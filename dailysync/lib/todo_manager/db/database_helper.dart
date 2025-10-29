// lib/todo_manager/db/database_helper.dart
// [Make sure to update any imports if necessary, e.g., if you use Task model here]
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/material.dart';
// import '../models/task_model.dart'; // Add if you use the Task model here

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
      // Ensure color has a default value if not provided
       if (!taskToInsert.containsKey('color')) {
        taskToInsert['color'] = Colors.blue.value; // Default color
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
        // Try to find task by other unique identifier or handle error
        debugPrint('Task ID is null for update. Cannot update task: $task');
        // Option 1: Find by title/date (less reliable)
        // Option 2: Throw an error or return an error code
        return -1; // Indicate error
      }

      // Create a copy to avoid modifying original, remove ID for update map
      final taskToUpdate = Map<String, dynamic>.from(task);
      taskToUpdate.remove('id'); // Remove id from the map used for updating columns

      return await db.update(
        'tasks',
        taskToUpdate,
        where: 'id = ?',
        whereArgs: [id], // Use the ID in the where clause
      );
    } catch (e) {
      debugPrint('Error updating task with ID $task["id"]: $e');
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
      final result = await db.query('tasks', orderBy: 'priority DESC, id DESC'); // Order by priority then ID
      return result;
    } catch (e) {
      debugPrint('Error getting tasks: $e');
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
        conflictAlgorithm: ConflictAlgorithm.ignore, // Ignore if category already exists
      );
    } catch (e) {
      debugPrint('Error inserting category: $e');
      return -1; // Return -1 or throw to indicate failure
    }
  }


  Future<int> deleteCategory(String name) async {
    try {
      final db = await instance.database;

      if (name == 'All') {
        // Optionally show a message to the user or simply return
        debugPrint('Cannot delete the "All" category');
        return 0; // Indicate no rows affected or handle as appropriate
      }

      // 1. Update tasks: Move tasks from the category being deleted to 'All'
      await db.update(
        'tasks',
        {'category': 'All'}, // Set category to 'All'
        where: 'category = ?',
        whereArgs: [name],
      );

      // 2. Delete the category itself
      return await db.delete(
        'categories',
        where: 'name = ?',
        whereArgs: [name],
      );
    } catch (e) {
      debugPrint('Error deleting category "$name": $e');
      rethrow; // Re-throw the exception to be handled by the caller
    }
  }


  Future<List<String>> getCategories() async {
    try {
      final db = await instance.database;
      final result = await db.query('categories', orderBy: 'id ASC'); // Ensure consistent order

      List<String> categories = result.map((e) => e['name'] as String).toList();

      // Ensure "All" is always first if it exists
      if (categories.contains("All")) {
        categories.remove("All");
        categories.insert(0, "All");
      } else {
        // If "All" somehow got deleted, add it back
        await insertCategory("All");
        categories.insert(0, "All");
      }

      return categories;
    } catch (e) {
      debugPrint('Error getting categories: $e');
      // Return default list only as a fallback in case of error
      return ['All', 'Home', 'Work', 'Personal', 'Study'];
    }
  }


  // --- Close DB ---
  Future close() async {
    final db = await instance.database;
    db.close();
  }

   // --- Add other methods from your original helper ---
   // getTasksByCategory, getCompletedTasks, getPendingTasks, toggleTaskCompletion,
   // updateTaskPriority, getTasksByPriority, searchTasks, updateTaskCategory,
   // getTaskCount, getCompletedTaskCount, getPendingTaskCount,
   // getTasksCountByCategory, getTasksCountByPriority,
   // clearDatabase, deleteAllTasks, deleteAllCategories etc.
   // Make sure their logic is sound and uses the correct table/column names.
}