// lib/routine_manager/controllers/routine_controller.dart
import 'package:flutter/material.dart';
import '../db/routine_db_helper.dart';
import '../models/routine_models.dart';
import 'dart:convert'; // For JSON
// Removed http and math imports as DEV_MODE_NO_AI is true

class RoutineController extends ChangeNotifier {
  final RoutineDbHelper _db = RoutineDbHelper();

  // --- State ---
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _hasMasterTemplate = false;
  bool get hasMasterTemplate => _hasMasterTemplate;

  List<DailyRoutineTask> _todayLog = [];
  List<DailyRoutineTask> get todayLog => _todayLog;

  Map<String, double> _summary = {}; // DateString -> Completion % (0.0 to 1.0)
  Map<String, double> get summary => _summary;

  // --- Developer Flag ---
  static const bool DEV_MODE_NO_AI = true;

  // --- Initialization ---
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    await _db.db; // Ensure DB is initialized
    await checkTemplateExists();
    await loadTodayLog();
    await loadSummary(); // Load summary on init

    _isLoading = false;
    notifyListeners();
  }

  // --- Data Loading Methods ---

  Future<void> checkTemplateExists() async {
    _hasMasterTemplate = await _db.hasMasterTemplate();
    notifyListeners();
  }

  Future<void> loadTodayLog() async {
    _todayLog = await _db.getDailyLog(DateTime.now());
    notifyListeners();
  }

  Future<void> loadSummary() async {
    _summary = await _db.getCompletionSummary(days: 7); // Fetch summary
    notifyListeners();
  }

  // --- AI Schedule Generation (Using Mock Data) ---
  Future<List<RoutineTask>?> generateScheduleFromInput(
    List<FixedTaskInput> fixedTasks,
    TimeOfDay wakeUp,
    TimeOfDay sleep,
    String goals,
  ) async {
    _isLoading = true;
    notifyListeners();

    if (DEV_MODE_NO_AI) {
      debugPrint("--- USING MOCK DATA (DEV_MODE_NO_AI = true) ---");
      await Future.delayed(const Duration(seconds: 1));
      const mockJsonResponse = '''
      [
        {"task_title": "Wake Up & Hydrate", "start_time": "07:00", "end_time": "07:30", "category": "Health"},
        {"task_title": "Morning Exercise", "start_time": "07:30", "end_time": "08:00", "category": "Health"},
        {"task_title": "Shower & Get Ready", "start_time": "08:00", "end_time": "08:30", "category": "Personal"},
        {"task_title": "Breakfast", "start_time": "08:30", "end_time": "09:00", "category": "Meal"},
        {"task_title": "School/Work", "start_time": "09:00", "end_time": "13:00", "category": "Work"},
        {"task_title": "Lunch Break", "start_time": "13:00", "end_time": "14:00", "category": "Meal"},
        {"task_title": "School/Work", "start_time": "14:00", "end_time": "17:00", "category": "Work"},
        {"task_title": "Commute/Break", "start_time": "17:00", "end_time": "17:30", "category": "Personal"},
        {"task_title": "Study/Goals", "start_time": "17:30", "end_time": "19:00", "category": "Focus"},
        {"task_title": "Dinner", "start_time": "19:00", "end_time": "19:30", "category": "Meal"},
        {"task_title": "Personal Time/Hobbies", "start_time": "19:30", "end_time": "21:30", "category": "Personal"},
        {"task_title": "Wind Down/Read", "start_time": "21:30", "end_time": "22:30", "category": "Personal"},
        {"task_title": "Prepare for Sleep", "start_time": "22:30", "end_time": "23:00", "category": "Personal"}
      ]
      ''';
      try {
        final parsedJson = jsonDecode(mockJsonResponse) as List;
        final tasks = parsedJson.map((t) => RoutineTask.fromJson(t as Map<String, dynamic>)).toList();
        _isLoading = false;
        notifyListeners();
        return tasks;
      } catch (e) {
         debugPrint("Error parsing mock JSON: $e");
         _isLoading = false;
         notifyListeners();
         throw Exception("Error parsing mock JSON: $e");
      }
    } else {
      _isLoading = false;
      notifyListeners();
      throw Exception("Live AI generation is currently disabled.");
    }
  }

  // --- Database Actions ---

  Future<void> saveNewMasterTemplate(List<RoutineTask> tasks) async {
    _isLoading = true;
    notifyListeners();
    await _db.saveNewTemplate(tasks);
    await checkTemplateExists();
    await loadTodayLog();
    await loadSummary();
    _isLoading = false;
    notifyListeners();
  }

  /// Updates the master schedule from the edit screen. Clears FUTURE logs.
  Future<void> updateMasterTemplate(List<RoutineTask> tasks) async {
    _isLoading = true;
    notifyListeners();
    // *** CORRECTED LINE ***
    await _db.updateTemplate(tasks);
    await loadTodayLog();
    await loadSummary();
    _isLoading = false;
    notifyListeners();
  }


  /// Gets the master template for editing.
  Future<List<RoutineTask>> getMasterTemplate() async {
    return await _db.getMasterTemplate();
  }

  /// Toggles completion status for today's task.
  Future<void> toggleTaskStatus(int logId, bool newStatus) async {
    final index = _todayLog.indexWhere((task) => task.logId == logId);
    if (index != -1) {
      final bool shouldBeSkipped = newStatus ? false : _todayLog[index].isSkipped;
      _todayLog[index] = _todayLog[index].copyWith(isCompleted: newStatus, isSkipped: shouldBeSkipped);
      notifyListeners();
    }
    try {
      // *** CORRECTED LINE ***
      await _db.updateDailyTaskStatus(logId, newStatus);
       if (newStatus) {
         // *** CORRECTED LINE ***
          await _db.updateDailyTaskSkipped(logId, false);
       }
      await loadSummary();
    } catch (e) {
       if (index != -1) {
          _todayLog[index] = _todayLog[index].copyWith(isCompleted: !newStatus);
          notifyListeners();
       }
      debugPrint("Error updating task status: $e");
    }
  }

  /// Toggles skipped status for today's task. (New)
  Future<void> toggleTaskSkipped(int logId, bool newStatus) async {
     final index = _todayLog.indexWhere((task) => task.logId == logId);
     if (index != -1) {
       final bool shouldBeCompleted = newStatus ? false : _todayLog[index].isCompleted;
       _todayLog[index] = _todayLog[index].copyWith(isSkipped: newStatus, isCompleted: shouldBeCompleted);
       notifyListeners();
     }
     try {
       // *** CORRECTED LINE ***
       await _db.updateDailyTaskSkipped(logId, newStatus);
        if (newStatus) {
           // *** CORRECTED LINE ***
           await _db.updateDailyTaskStatus(logId, false);
        }
       await loadSummary();
     } catch (e) {
        if (index != -1) {
           _todayLog[index] = _todayLog[index].copyWith(isSkipped: !newStatus);
           notifyListeners();
        }
       debugPrint("Error updating task skipped status: $e");
     }
  }

}

