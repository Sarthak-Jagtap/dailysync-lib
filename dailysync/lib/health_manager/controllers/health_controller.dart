// lib/health_manager/controllers/health_controller.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/db_helper.dart';
import '../models/health_models.dart';

// Helper function to format date keys consistently
String dateToKey(DateTime dt) => DateFormat('yyyy-MM-dd').format(dt);

class HealthController extends ChangeNotifier {
  // Instance of the DBHelper
  final DBHelper _db = DBHelper();

  // UI state
  DateTime selectedDate = DateTime.now();
  int stepTarget = 8000;

  // Cached weekly data for UI
  Map<String, int> waterWeekly = {};
  Map<String, int> stepsWeekly = {};
  Map<String, int> sleepWeekly = {};
  Map<String, int> exerciseWeekly = {};
  int dietLoggedDaysWeekly = 0;
  List<DietEntry> dietEntriesWeekly = []; // For the diet table

  DateTime currentWeekStart = DateTime.now();
  DateTime currentWeekEnd = DateTime.now();

  Future<void> init() async {
    await _ensureDB();
    _updateWeekDates();
    await loadWeekly();
  }

  // Ensures the database is initialized
  Future<void> _ensureDB() async {
    await _db.db; // Accessing the getter initializes the DB if needed
  }

  // Calculates the Sunday (start) and Saturday (end) of the week for a given date
  void _updateWeekDates([DateTime? date]) {
      final today = date ?? DateTime.now();
      // Sunday is 7, Monday is 1. `today.weekday % 7` gives 0 for Sun, 1 for Mon, ..., 6 for Sat.
      int daysToSubtract = today.weekday % 7;
      currentWeekStart = DateTime(today.year, today.month, today.day - daysToSubtract, 0, 0, 0); // Start of Sunday
      currentWeekEnd = currentWeekStart.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59)); // End of Saturday
  }

  // --- Add/Update Methods ---

  Future<void> addWater(int glasses, {DateTime? date}) async {
    final d = date ?? DateTime.now();
    final entry = WaterEntry(date: dateToKey(d), glasses: glasses);
    await _db.insertWater(entry); // Call on _db instance
    await loadWeekly();
    notifyListeners();
  }

   Future<void> addDiet({
      required DateTime date,
      required bool morningDryFruits,
      required bool breakfast,
      required bool lunch,
      required bool snacks,
      required bool dinner}) async {
    final entry = DietEntry(
      date: dateToKey(date),
      morningDryFruits: morningDryFruits,
      breakfast: breakfast,
      lunch: lunch,
      snacks: snacks,
      dinner: dinner,
    );
    await _db.insertDiet(entry); // Call on _db instance
    await loadWeekly();
    notifyListeners();
  }

   Future<void> addSteps(int steps, {DateTime? date}) async {
    final d = date ?? DateTime.now();
    final entry = StepsEntry(date: dateToKey(d), steps: steps, target: stepTarget);
    await _db.insertSteps(entry); // Call on _db instance
    await loadWeekly();
    notifyListeners();
  }

   Future<void> setStepTarget(int target) async {
      stepTarget = target > 0 ? target : 1;
      final todayKey = dateToKey(DateTime.now());
      // Update DB if needed (optional based on your logic)
      await (await _db.db).update('steps', {'target': stepTarget}, where: 'date = ?', whereArgs: [todayKey]);
      await loadWeekly(); // Reload weekly data might be needed if chart uses target dynamically per day
      notifyListeners();
    }

   Future<void> addExercise(String type, int minutes, {DateTime? date}) async {
    final d = date ?? DateTime.now();
    final entry = ExerciseEntry(date: dateToKey(d), type: type, minutes: minutes);
    await _db.insertExercise(entry); // Call on _db instance
    await loadWeekly();
    notifyListeners();
  }

  Future<void> addSleep(int minutes, {required DateTime date}) async {
    final entry = SleepEntry(date: dateToKey(date), minutes: minutes);
    await _db.insertSleep(entry); // Call on _db instance
    await loadWeekly();
    notifyListeners();
  }

  // --- Load Weekly Data ---
  Future<void> loadWeekly() async {
    _updateWeekDates(); // Ensure week dates are current before fetching
    // All these call methods on the _db instance
    waterWeekly = await _db.weeklyWaterSum(currentWeekStart, currentWeekEnd);
    stepsWeekly = await _db.weeklyStepsSum(currentWeekStart, currentWeekEnd);
    sleepWeekly = await _db.weeklySleepSum(currentWeekStart, currentWeekEnd);
    exerciseWeekly = await _db.weeklyExerciseSum(currentWeekStart, currentWeekEnd);
    dietLoggedDaysWeekly = await _db.countWeeklyDietLogs(currentWeekStart, currentWeekEnd);
    dietEntriesWeekly = await _db.getWeeklyDietEntries(currentWeekStart, currentWeekEnd);
    notifyListeners(); // Notify listeners after all data is fetched
  }

  // --- History/Single Day Fetch Helpers ---
  // getHistoryFor remains the same
  Future<List<Map<String, dynamic>>> getHistoryFor(String table,
      {int lastNDays = 30}) async {
    // Calls getAllRecordsForTableLastNDays(String, DateTime, int) in DBHelper
    return await _db.getAllRecordsForTableLastNDays( // Call on _db instance
        table, DateTime.now(), lastNDays);
  }

  // Fetches DietEntry for a specific date.
  // Calls getDietByDate(String) in DBHelper.
  // This structure IS CORRECT - calling the method on the _db instance.
  Future<DietEntry?> getDietForDate(DateTime d) => _db.getDietByDate(dateToKey(d));

  // Fetches StepsEntry for a specific date.
  // Calls getStepsByDate(String) in DBHelper.
  // This structure IS CORRECT - calling the method on the _db instance.
  Future<StepsEntry?> getStepsForDate(DateTime d) => _db.getStepsByDate(dateToKey(d));

  // Fetches a list of WaterEntry for a specific date.
  // Calls getWaterByDate(String) in DBHelper.
  // This structure IS CORRECT - calling the method on the _db instance.
  Future<List<WaterEntry>> getWaterForDate(DateTime d) => _db.getWaterByDate(dateToKey(d));

  // Fetches SleepEntry for a specific date.
  // Calls getSleepByDate(String) in DBHelper.
  // This structure IS CORRECT - calling the method on the _db instance.
  Future<SleepEntry?> getSleepForDate(DateTime d) => _db.getSleepByDate(dateToKey(d));
}

