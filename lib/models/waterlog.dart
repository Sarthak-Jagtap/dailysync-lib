class WaterLog {
  final String id;
  final int amountInMl;
  final DateTime date;

  WaterLog({
    required this.id,
    required this.amountInMl,
    required this.date,
  });

  // To SQL Map (Insert)
  Map<String, dynamic> toMap() => {
    'id': id,
    'amountInMl': amountInMl,
    'date': date.toIso8601String(), // Store DateTime as ISO String
  };

  // From SQL Map (Read)
  factory WaterLog.fromMap(Map<String, dynamic> map) {
    return WaterLog(
      id: map['id'] as String,
      amountInMl: map['amountInMl'] as int,
      date: DateTime.parse(map['date'] as String),
    );
  }
}
