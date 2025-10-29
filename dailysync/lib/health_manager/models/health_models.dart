// lib/health_manager/models/health_models.dart

// REMOVED dateToKey function from here. It's now defined in db_helper.dart
// String dateToKey(DateTime dt) => '${dt.year.toString().padLeft(4,'0')}-${dt.month.toString().padLeft(2,'0')}-${dt.day.toString().padLeft(2,'0')}';

class WaterEntry {
  final int? id;
  final String date; // YYYY-MM-DD
  final int glasses;

  WaterEntry({this.id, required this.date, required this.glasses});

  Map<String, dynamic> toMap() => {'id': id, 'date': date, 'glasses': glasses};
  static WaterEntry fromMap(Map<String, dynamic> m) => WaterEntry(id: m['id'] as int?, date: m['date'], glasses: m['glasses']);
}

class DietEntry {
  final int? id;
  final String date;
  final bool morningDryFruits;
  final bool breakfast;
  final bool lunch;
  final bool snacks;
  final bool dinner;

  DietEntry({
    this.id,
    required this.date,
    required this.morningDryFruits,
    required this.breakfast,
    required this.lunch,
    required this.snacks,
    required this.dinner,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'date': date,
    'morningDryFruits': morningDryFruits ? 1 : 0,
    'breakfast': breakfast ? 1 : 0,
    'lunch': lunch ? 1 : 0,
    'snacks': snacks ? 1 : 0,
    'dinner': dinner ? 1 : 0,
  };

  static DietEntry fromMap(Map<String, dynamic> m) => DietEntry(
    id: m['id'] as int?,
    date: m['date'],
    morningDryFruits: (m['morningDryFruits'] ?? 0) == 1,
    breakfast: (m['breakfast'] ?? 0) == 1,
    lunch: (m['lunch'] ?? 0) == 1,
    snacks: (m['snacks'] ?? 0) == 1,
    dinner: (m['dinner'] ?? 0) == 1,
  );
}

class StepsEntry {
  final int? id;
  final String date;
  final int steps;
  final int? target; // optional per-entry target

  StepsEntry({this.id, required this.date, required this.steps, this.target});

  Map<String, dynamic> toMap() => {'id': id, 'date': date, 'steps': steps, 'target': target};
  static StepsEntry fromMap(Map<String, dynamic> m) => StepsEntry(
    id: m['id'] as int?,
    date: m['date'],
    steps: m['steps'],
    target: m['target'] as int?,
  );
}

class SleepEntry {
  final int? id;
  final String date;
  final int minutes; // store minutes of sleep

  SleepEntry({this.id, required this.date, required this.minutes});

  Map<String, dynamic> toMap() => {'id': id, 'date': date, 'minutes': minutes};
  static SleepEntry fromMap(Map<String, dynamic> m) => SleepEntry(id: m['id'] as int?, date: m['date'], minutes: m['minutes']);
}

class ExerciseEntry {
  final int? id;
  final String date;
  final String type;
  final int minutes;

  ExerciseEntry({this.id, required this.date, required this.type, required this.minutes});

  Map<String, dynamic> toMap() => {'id': id, 'date': date, 'type': type, 'minutes': minutes};
  static ExerciseEntry fromMap(Map<String, dynamic> m) => ExerciseEntry(
    id: m['id'] as int?,
    date: m['date'],
    type: m['type'],
    minutes: m['minutes'],
  );
}
