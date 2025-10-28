class Meal {
  final String id;
  final String name;
  final String time;
  final int calories;
  final bool isLogged;

  Meal({
    required this.id,
    required this.name,
    required this.time,
    required this.calories,
    this.isLogged = false,
  });

  // Helper method to create a new Meal instance with updated values
  Meal copyWith({bool? isLogged}) {
    return Meal(
      id: id,
      name: name,
      time: time,
      calories: calories,
      isLogged: isLogged ?? this.isLogged,
    );
  }

  // To SQL Map (Insert)
  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'time': time,
    'calories': calories,
    'isLogged': isLogged ? 1 : 0, // SQLite stores bools as INTEGER (1 or 0)
  };

  // From SQL Map (Read)
  factory Meal.fromMap(Map<String, dynamic> map) {
    return Meal(
      id: map['id'] as String,
      name: map['name'] as String,
      time: map['time'] as String,
      calories: map['calories'] as int,
      isLogged: (map['isLogged'] as int) == 1, // Convert INTEGER back to bool
    );
  }
}
