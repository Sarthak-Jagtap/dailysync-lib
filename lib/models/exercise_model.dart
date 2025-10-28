import 'package:flutter/material.dart';

enum WorkoutStatus { pending, completed }

class Workout {
  final String title;
  final String duration;
  final String calories;
  final IconData icon;
  WorkoutStatus status;

  Workout({
    required this.title,
    required this.duration,
    required this.calories,
    required this.icon,
    this.status = WorkoutStatus.pending,
  });
}