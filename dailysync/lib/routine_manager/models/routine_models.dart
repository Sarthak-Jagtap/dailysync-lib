// lib/routine_manager/models/routine_models.dart
import 'package:flutter/material.dart';

/// Represents a single task in the master routine template.
class RoutineTask {
  final int? id; // Primary Key from the database
  final String taskTitle;
  final String startTime; // Stored as "HH:mm"
  final String endTime; // Stored as "HH:mm"
  final String category;

  RoutineTask({
    this.id,
    required this.taskTitle,
    required this.startTime,
    required this.endTime,
    required this.category,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_title': taskTitle,
      'start_time': startTime,
      'end_time': endTime,
      'category': category,
    };
  }

  factory RoutineTask.fromJson(Map<String, dynamic> json) {
    return RoutineTask(
      id: json['id'] as int?, // Read the ID from the database map
      taskTitle: json['task_title'] as String,
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      category: json['category'] as String,
    );
  }

  // Helper to get TimeOfDay from "HH:mm" string
  TimeOfDay get startTimeOfDay {
      final parts = startTime.split(':');
      // Add error handling for invalid format
      if (parts.length != 2) return TimeOfDay.now();
      return TimeOfDay(hour: int.tryParse(parts[0]) ?? 0, minute: int.tryParse(parts[1]) ?? 0);
  }
   TimeOfDay get endTimeOfDay {
      final parts = endTime.split(':');
       // Add error handling for invalid format
      if (parts.length != 2) return TimeOfDay.now();
      return TimeOfDay(hour: int.tryParse(parts[0]) ?? 0, minute: int.tryParse(parts[1]) ?? 0);
  }

  static String formatTime(TimeOfDay time) {
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  }

   // Create a copy with potentially updated values (useful for editing)
  RoutineTask copyWith({
    int? id,
    String? taskTitle,
    String? startTime,
    String? endTime,
    String? category,
  }) {
    return RoutineTask(
      id: id ?? this.id,
      taskTitle: taskTitle ?? this.taskTitle,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      category: category ?? this.category,
    );
  }
}

/// Represents a single task in the daily log, with completion & skipped status.
class DailyRoutineTask extends RoutineTask {
  final int logId; // The ID of the log entry (PK)
  final bool isCompleted;
  final bool isSkipped; // New field

  DailyRoutineTask({
    required this.logId,
    required super.taskTitle,
    required super.startTime,
    required super.endTime,
    required super.category,
    this.isCompleted = false,
    this.isSkipped = false, // Initialize skipped
    super.id, // This is the template_id (can be null if task added manually today)
  });

  factory DailyRoutineTask.fromJson(Map<String, dynamic> json) {
    return DailyRoutineTask(
      logId: json['id'] as int, // Log entry's primary key
      id: json['template_id'] as int?, // Original template task ID (FK)
      taskTitle: json['task_title'] as String,
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      category: json['category'] as String,
      isCompleted: (json['is_completed'] as int? ?? 0) == 1,
      isSkipped: (json['is_skipped'] as int? ?? 0) == 1, // Read skipped status
    );
  }

  /// Helper to create a copy with new values.
  /// Overrides RoutineTask.copyWith and adds isCompleted/isSkipped.
  @override
  DailyRoutineTask copyWith({
    // Parameters from RoutineTask
    int? id,
    String? taskTitle,
    String? startTime,
    String? endTime,
    String? category,
    // Parameters specific to DailyRoutineTask
    int? logId, // Allow changing logId too? Usually not needed for copy.
    bool? isCompleted,
    bool? isSkipped,
  }) {
    // Call super.copyWith for the inherited fields
    final routineTaskPart = super.copyWith(
      id: id,
      taskTitle: taskTitle,
      startTime: startTime,
      endTime: endTime,
      category: category,
    );

    // Return a new DailyRoutineTask combining the super part and the specific fields
    return DailyRoutineTask(
      logId: logId ?? this.logId, // Use current logId if not provided
      id: routineTaskPart.id,
      taskTitle: routineTaskPart.taskTitle,
      startTime: routineTaskPart.startTime,
      endTime: routineTaskPart.endTime,
      category: routineTaskPart.category,
      isCompleted: isCompleted ?? this.isCompleted, // Update or keep current
      isSkipped: isSkipped ?? this.isSkipped,       // Update or keep current
    );
  }
}

// Helper models for the setup screen
class FixedTaskInput {
  String title;
  TimeOfDay startTime;
  TimeOfDay endTime;
  // Optional: Add an ID for editing purposes
  int? tempId;

  FixedTaskInput({
    required this.title,
    required this.startTime,
    required this.endTime,
    this.tempId,
  });
}

