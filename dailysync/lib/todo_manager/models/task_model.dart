// lib/todo_manager/models/task_model.dart
import 'package:flutter/material.dart';

class Task {
  final int? id;
  final String title;
  final String? description;
  final bool isCompleted;
  final String date;
  final String category;
  final Color color;
  final int priority; // 1 (Low) to 5 (Urgent)

  Task({
    this.id,
    required this.title,
    this.description,
    this.isCompleted = false,
    required this.date,
    required this.category,
    this.color = Colors.blue, // Default color
    this.priority = 3, // Default priority (Normal)
  });

  // Convert a Task object into a Map object for DB
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'completed': isCompleted ? 1 : 0,
      'date': date,
      'category': category,
      'color': color.value,
      'priority': priority,
    };
  }

  // Extract a Task object from a Map object
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      isCompleted: map['completed'] == 1,
      date: map['date'],
      category: map['category'],
      color: Color(map['color'] ?? Colors.blue.value),
      priority: map['priority'] ?? 3,
    );
  }

  // Helper to create a copy with updated values
  Task copyWith({
    int? id,
    String? title,
    String? description,
    bool? isCompleted,
    String? date,
    String? category,
    Color? color,
    int? priority,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      date: date ?? this.date,
      category: category ?? this.category,
      color: color ?? this.color,
      priority: priority ?? this.priority,
    );
  }
}