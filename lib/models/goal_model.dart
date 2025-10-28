import 'package:flutter/material.dart';

class Goal {
  final String title;
  final String currentValue;
  final String goalValue;
  final double progress;
  final IconData icon;
  final Color color;

  Goal({
    required this.title,
    required this.currentValue,
    required this.goalValue,
    required this.progress,
    required this.icon,
    required this.color,
  });
}