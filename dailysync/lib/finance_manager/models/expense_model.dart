// lib/finance_manager/models/expense_model.dart
import 'package:flutter/material.dart';

class Expense {
  final int? id;
  final String title;
  final double amount;
  final String category; // e.g., Food, Transport, Bills, Entertainment
  final DateTime date;
  final String paymentType; // e.g., Cash, Card, Online
  final String? description;
  final String? merchant;

  Expense({
    this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    required this.paymentType,
    this.description,
    this.merchant,
  });

  // Convert an Expense object into a Map object for DB
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'category': category,
      'date': date.toIso8601String(), // Store date as ISO8601 string
      'paymentType': paymentType,
      'description': description,
      'merchant': merchant,
    };
  }

  // Extract an Expense object from a Map object
  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      title: map['title'],
      amount: map['amount'],
      category: map['category'],
      date: DateTime.parse(map['date']), // Parse ISO8601 string back to DateTime
      paymentType: map['paymentType'],
      description: map['description'],
      merchant: map['merchant'],
    );
  }

  // Helper to create a copy with updated values
  Expense copyWith({
    int? id,
    String? title,
    double? amount,
    String? category,
    DateTime? date,
    String? paymentType,
    String? description,
    String? merchant,
  }) {
    return Expense(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      paymentType: paymentType ?? this.paymentType,
      description: description ?? this.description,
      merchant: merchant ?? this.merchant,
    );
  }
}