// lib/health_manager/controllers/health_controller.dart
import 'package:flutter/material.dart';
import '../db/db_helper.dart';
import '../models/health_models.dart';

class HealthController extends ChangeNotifier {
  final DBHelper _db = DBHelper();

  // UI state
  DateTime selectedDate = DateTime.now();
  int stepTarget = 8000; // default target (user can change)

  // cached weekly data for UI
  Map<String, int> waterWeekly = {};
  Map<String, int> stepsWeekly = {};
  Map<String, int> sleepWeekly = {};
  Map<String, int> exerciseWeekly = {};

  Future<void> init() async {
    await _ensureDB();
    await loadWeekly();
  }

  Future<void> _ensureDB() async {
    await _db.db; // triggers DB init
  }

  // Add water entry (number of glasses). We store each call as a record.
  Future<void> addWater(int glasses, {DateTime? date}) async {
    final d = date ?? DateTime.now();
    final entry = WaterEntry(date: dateToKey(d), glasses: glasses);
    await _db.insertWater(entry);
    await loadWeekly();
    notifyListeners();
  }

  // Add or update diet for a date
  Future<void> addDiet({required DateTime date, required bool morningDryFruits, required bool breakfast, required bool lunch, required bool snacks, required bool dinner}) async {
    final entry = DietEntry(
      date: dateToKey(date),
      morningDryFruits: morningDryFruits,
      breakfast: breakfast,
      lunch: lunch,
      snacks: snacks,
      dinner: dinner,
    );
    await _db.insertDiet(entry);
    notifyListeners();
  }

  // Add steps - this appends (or updates aggregate) steps for date
  Future<void> addSteps(int steps, {DateTime? date}) async {
    final d = date ?? DateTime.now();
    final entry = StepsEntry(date: dateToKey(d), steps: steps, target: stepTarget);
    await _db.insertSteps(entry);
    await loadWeekly();
    notifyListeners();
  }

  Future<void> setStepTarget(int target) async {
    stepTarget = target;
    notifyListeners();
  }

  Future<void> addSleep(int minutes, {DateTime? date}) async {
    final d = date ?? DateTime.now();
    final entry = SleepEntry(date: dateToKey(d), minutes: minutes);
    await _db.insertSleep(entry);
    await loadWeekly();
    notifyListeners();
  }

  Future<void> addExercise(String type, int minutes, {DateTime? date}) async {
    final d = date ?? DateTime.now();
    final entry = ExerciseEntry(date: dateToKey(d), type: type, minutes: minutes);
    await _db.insertExercise(entry);
    await loadWeekly();
    notifyListeners();
  }

  Future<void> loadWeekly({DateTime? end}) async {
    final e = end ?? DateTime.now();
    waterWeekly = await _db.weeklyWaterSum(e);
    stepsWeekly = await _db.weeklyStepsSum(e);
    sleepWeekly = await _db.weeklySleepSum(e);
    exerciseWeekly = await _db.weeklyExerciseSum(e);
    notifyListeners();
  }

  // History fetch helpers
  Future<List<Map<String, dynamic>>> getHistoryFor(String table, {int lastNDays = 30}) async {
    return await _db.getAllRecordsForTableLastNDays(table, DateTime.now(), lastNDays);
  }

  Future<DietEntry?> getDietForDate(DateTime d) => _db.getDietByDate(dateToKey(d));
  Future<StepsEntry?> getStepsForDate(DateTime d) => _db.getStepsByDate(dateToKey(d));
  Future<List<WaterEntry>> getWaterForDate(DateTime d) => _db.getWaterByDate(dateToKey(d));
}
