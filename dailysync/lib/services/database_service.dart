import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'dailysync_data.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  void _onCreate(Database db, int version) async {
    // Table 1: Water Logs
    await db.execute('''
      CREATE TABLE water_logs (
        id TEXT PRIMARY KEY,
        amountInMl INTEGER,
        date TEXT
      )
    ''');
    
    // Table 2: Meal Logs
    await db.execute('''
      CREATE TABLE meal_logs (
        id TEXT PRIMARY KEY,
        name TEXT,
        time TEXT,
        calories INTEGER,
        isLogged INTEGER
      )
    ''');

    // Table 3: User Health Metrics (For current day's summary, updated by Health API)
    // We store this as a key-value pair tied to a specific date.
    await db.execute('''
      CREATE TABLE daily_metrics (
        date TEXT PRIMARY KEY,
        steps INTEGER,
        activeCalories INTEGER,
        sleepHours REAL
      )
    ''');
  }
}
