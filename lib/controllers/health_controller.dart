import 'package:dailysync/services/database_service.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:sqflite/sqflite.dart';
import 'package:dailysync/models/waterlog.dart';
import 'package:dailysync/models/meal_model.dart';
import 'package:dailysync/models/exercise_model.dart';
import 'package:dailysync/models/goal_model.dart'; 
// import 'package:health/health.dart'; // Uncomment this when ready for live data

class HealthController extends ChangeNotifier {
  final _uuid = const Uuid();
  final DatabaseService _dbService = DatabaseService();

  // --- HEALTH METRICS AND DEFAULTS ---
  final int _calorieGoal = 2000;
  final int _waterGoalInMl = 2000;
  final int _stepsGoal = 10000;
  final int _weeklyWorkoutGoal = 4;
  
  // LIVE METRICS (Updated by sensors or calculated)
  int _currentSteps = 0; 
  double _sleepHours = 7.5; 
  int _activeCalories = 0; 

  // --- IN-MEMORY DATA STORES (Loaded from SQLite) ---
  final List<WaterLog> _waterLogs = []; 
  final List<Meal> _meals = []; 
  
  // Workouts kept in memory for simple toggling (can be integrated into SQLite/Firestore later)
  final List<Workout> _workouts = [
    Workout(title: 'Morning Run', duration: '30 min', calories: '320 cal', icon: Icons.directions_run, status: WorkoutStatus.pending),
    Workout(title: 'Strength Training', duration: '45 min', calories: '450 cal', icon: Icons.fitness_center, status: WorkoutStatus.pending),
    Workout(title: 'Yoga Session', duration: '20 min', calories: '150 cal', icon: Icons.self_improvement),
  ];
  
  // --- CONSTRUCTOR: Triggers database load ---
  HealthController() {
    _loadAllDataFromDB();
  }

  // ------------------------------------
  // DATA LOADING & PERSISTENCE (SQLite)
  // ------------------------------------

  Future<void> _loadAllDataFromDB() async {
    final db = await _dbService.database;
    
    // 1. Load Water Logs
    final waterMaps = await db.query('water_logs', orderBy: 'date DESC');
    _waterLogs.clear();
    _waterLogs.addAll(waterMaps.map((map) => WaterLog.fromMap(map)).toList());
    
    // 2. Load Meal Logs
    final mealMaps = await db.query('meal_logs', orderBy: 'time DESC');
    _meals.clear();
    _meals.addAll(mealMaps.map((map) => Meal.fromMap(map)).toList());
        
    notifyListeners();
    // Fetch initial sensor data after loading local logs
    fetchMobileSensorData();
  }
  
  // ------------------------------------
  // MOBILE SENSOR / API INTEGRATION (MOCK)
  // ------------------------------------

  Future<bool> requestHealthDataPermission() async {
    // This function must be configured to check for permission using the 'health' package
    // For now, we simulate success
    return true; 
  }

  Future<void> fetchMobileSensorData() async {
    final authorized = await requestHealthDataPermission();
    if (!authorized) {
      debugPrint("Health data permission denied.");
      return;
    }
    
    // --- MOCK VALUES (Simulating a data update from the phone sensor) ---
    _currentSteps = 9000; 
    _activeCalories = 480; 
    
    // In a real app, you would uncomment the following block:
    /*
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    HealthFactory health = HealthFactory();

    try {
      int steps = await health.getTotalStepsInInterval(todayStart, now) ?? 0;
      _currentSteps = steps;
      
      List<HealthDataPoint> caloriesData = await health.getHealthData(
        types: [HealthDataType.ACTIVE_ENERGY_BURNED],
        startTime: todayStart,
        endTime: now,
      );
      _activeCalories = caloriesData.fold(0, (sum, p) => sum + (p.value as num).toInt());
    } catch (e) {
      debugPrint("Error fetching sensor data: $e");
    }
    */

    debugPrint("Mobile Health data fetched and metrics updated.");
    notifyListeners();
  }
  
  // ------------------------------------
  // CORE LOGIC METHODS (CRUD Operations - Saves to SQLite)
  // ------------------------------------

  void addWaterLog(int amountInMl) async {
    final newLog = WaterLog(id: _uuid.v4(), amountInMl: amountInMl, date: DateTime.now());
    
    final db = await _dbService.database;
    await db.insert('water_logs', newLog.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    
    _waterLogs.insert(0, newLog); // Update in-memory list
    notifyListeners();
  }

  void addMeal(String name, String time, int calories) async {
      final newMeal = Meal(id: _uuid.v4(), name: name, time: time, calories: calories, isLogged: true);
      
      final db = await _dbService.database;
      await db.insert('meal_logs', newMeal.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      
      _meals.insert(0, newMeal); // Update in-memory list
      notifyListeners();
  }
  
  void toggleMealLogStatus(String mealId) async {
      final index = _meals.indexWhere((m) => m.id == mealId);
      if (index != -1) {
          final meal = _meals[index];
          final toggledMeal = meal.copyWith(isLogged: !meal.isLogged);
          
          final db = await _dbService.database;
          await db.update(
            'meal_logs',
            toggledMeal.toMap(),
            where: 'id = ?',
            whereArgs: [mealId],
          );
          
          _meals[index] = toggledMeal; 
          notifyListeners();
      }
  }

  void toggleWorkoutStatus(Workout workout) {
    final index = _workouts.indexWhere((w) => w.title == workout.title);
    if (index != -1) {
      _workouts[index].status = _workouts[index].status == WorkoutStatus.pending
          ? WorkoutStatus.completed
          : WorkoutStatus.pending;
      // You would save this status update to the workout_logs table here.
      notifyListeners();
    }
  }

  void addWorkout(Workout newWorkout) {
    _workouts.add(newWorkout);
    notifyListeners();
  }
  
  // --- PUBLIC GETTERS ---
  List<Meal> get meals => _meals;
  List<Workout> get workouts => _workouts;
  List<WaterLog> get waterLogs => _waterLogs;
  int get currentCalories => _activeCalories + _meals.where((m) => m.isLogged).fold(0, (sum, meal) => sum + meal.calories);

  int get totalWaterIntakeInMl {
    final today = DateTime.now();
    return _waterLogs
        .where((log) => log.date.day == today.day && log.date.month == today.month && log.date.year == today.year)
        .fold(0, (sum, log) => sum + log.amountInMl);
  }
  int get completedWorkoutsCount => _workouts.where((w) => w.status == WorkoutStatus.completed).length;

  List<Goal> get goals {
    final waterProgress = (totalWaterIntakeInMl / _waterGoalInMl).clamp(0.0, 1.0);
    final workoutProgress = (completedWorkoutsCount / _weeklyWorkoutGoal).clamp(0.0, 1.0);
    final stepsProgress = (_currentSteps / _stepsGoal).clamp(0.0, 1.0);
    final sleepProgress = (_sleepHours / 8.0).clamp(0.0, 1.0);
    
    return [
      Goal(title: 'Steps', currentValue: '$_currentSteps', goalValue: '$_stepsGoal goal', progress: stepsProgress, icon: Icons.directions_walk, color: Colors.green),
      Goal(title: 'Water', currentValue: '${(totalWaterIntakeInMl / 250).round()} cups', goalValue: '${(_waterGoalInMl / 250).round()} cups goal', progress: waterProgress, icon: Icons.local_drink, color: Colors.blue),
      Goal(title: 'Sleep', currentValue: '${_sleepHours.toStringAsFixed(1)}h', goalValue: '8h goal', progress: sleepProgress, icon: Icons.bedtime, color: Colors.purple),
      Goal(title: 'Workouts', currentValue: '$completedWorkoutsCount', goalValue: '$_weeklyWorkoutGoal weekly goal', progress: workoutProgress, icon: Icons.fitness_center, color: Colors.orange),
    ];
  }
}
