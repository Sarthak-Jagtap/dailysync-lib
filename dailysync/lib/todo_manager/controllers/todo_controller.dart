// lib/todo_manager/controllers/todo_controller.dart
import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/task_model.dart'; // Import the Task model

class TodoController extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  List<Task> _tasks = [];
  List<String> _categories = ["All"];
  String _selectedCategory = "All";
  bool _isLoading = false;

  List<Task> get tasks => _tasks;
  List<String> get categories => _categories;
  String get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;

  List<Task> get filteredTasks {
    if (_selectedCategory == "All") {
      return _tasks;
    }
    return _tasks.where((task) => task.category == _selectedCategory).toList();
  }

  TodoController() {
    refreshData();
  }

  Future<void> refreshData() async {
    _setLoading(true);
    try {
      final catData = await _dbHelper.getCategories();
      final taskDataMaps = await _dbHelper.getTasks();
      _categories = catData;
      _tasks = taskDataMaps.map((map) => Task.fromMap(map)).toList();

      // Reset selected category if it no longer exists
      if (!_categories.contains(_selectedCategory)) {
        _selectedCategory = "All";
      }
    } catch (e) {
      debugPrint("Error refreshing data: $e");
      // Handle error appropriately, maybe show a message to the user
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addTask(Task newTask) async {
    try {
      // Convert Task object to Map for DB insertion
      final taskMap = newTask.toMap();
      await _dbHelper.insertTask(taskMap);
      await refreshData(); // Refresh list after adding
    } catch (e) {
      debugPrint("Error adding task: $e");
    }
  }

   Future<void> updateTask(Task task) async {
    try {
      await _dbHelper.updateTask(task.toMap());
      // Find the task in the local list and update it
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = task;
        notifyListeners(); // Update UI immediately
      } else {
        await refreshData(); // Fallback to full refresh if not found locally
      }
    } catch (e) {
      debugPrint("Error updating task: $e");
      await refreshData(); // Refresh data on error to ensure consistency
    }
  }


 Future<void> deleteTask(int id) async {
    try {
      await _dbHelper.deleteTask(id);
      // Remove from local list optimistically
      _tasks.removeWhere((task) => task.id == id);
      notifyListeners(); // Update UI immediately
    } catch (e) {
      debugPrint("Error deleting task: $e");
      await refreshData(); // Refresh data on error to ensure consistency
    }
  }


  Future<void> toggleTaskCompletion(Task task) async {
    final updatedTask = task.copyWith(isCompleted: !task.isCompleted);
    await updateTask(updatedTask); // Use the existing updateTask method
  }

  void selectCategory(String category) {
    if (_categories.contains(category)) {
      _selectedCategory = category;
      notifyListeners();
    }
  }

   Future<void> addCategory(String name) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty || _categories.any((cat) => cat.toLowerCase() == trimmedName.toLowerCase())) {
      // Optionally show feedback that category is empty or already exists
      return;
    }
    await _dbHelper.insertCategory(trimmedName);
    await refreshData(); // Refresh categories and potentially tasks
  }

  Future<void> deleteCategory(String name) async {
    if (name == "All") return; // Prevent deleting "All"
    await _dbHelper.deleteCategory(name);
    await refreshData(); // Refresh categories and tasks
  }


  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }
}