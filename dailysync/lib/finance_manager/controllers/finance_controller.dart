// lib/finance_manager/controllers/finance_controller.dart
import 'package:flutter/material.dart';
import '../db/db_helper.dart';
import '../models/expense_model.dart';

class FinanceController extends ChangeNotifier {
  final DBHelper _dbHelper = DBHelper();
  List<Expense> _expenses = [];
  bool _isLoading = false;
  DateTime _reportStartDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _reportEndDate = DateTime.now();

  // Predefined categories
  final List<String> _categories = [
    'Food',
    'Transport',
    'Bills',
    'Entertainment',
    'Shopping',
    'Health',
    'Groceries',
    'Other'
  ];

  List<Expense> get expenses => _expenses;
  bool get isLoading => _isLoading;
  DateTime get reportStartDate => _reportStartDate;
  DateTime get reportEndDate => _reportEndDate;
  List<String> get categories => _categories; // Getter for categories


  FinanceController() {
    loadExpenses();
  }

  Future<void> loadExpenses() async {
    _setLoading(true);
    try {
      _expenses = await _dbHelper.getExpenses();
    } catch (e) {
      debugPrint("Error loading expenses: $e");
      _expenses = []; // Ensure expenses is empty on error
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addExpense(Expense expense) async {
    _setLoading(true);
    try {
      await _dbHelper.insertExpense(expense);
      await loadExpenses(); // Refresh the list
    } catch (e) {
      debugPrint("Error adding expense: $e");
       _setLoading(false); // Ensure loading is turned off on error
    }
    // No finally block needed here as loadExpenses handles its own loading state
  }

  Future<void> updateExpense(Expense expense) async {
    _setLoading(true);
    try {
      await _dbHelper.updateExpense(expense);
      await loadExpenses(); // Refresh the list
    } catch (e) {
      debugPrint("Error updating expense: $e");
       _setLoading(false);
    }
  }

  Future<void> deleteExpense(int id) async {
    _setLoading(true);
    try {
      await _dbHelper.deleteExpense(id);
      _expenses.removeWhere((exp) => exp.id == id); // Optimistic update
      notifyListeners(); // Notify UI immediately
    } catch (e) {
      debugPrint("Error deleting expense: $e");
      await loadExpenses(); // Full refresh on error to ensure consistency
    } finally {
       _setLoading(false); // Make sure loading is false after operation or error
    }
  }


  // --- Reporting Data Fetching ---

  Future<double> getTotalExpensesForCurrentPeriod() async {
    return await _dbHelper.getTotalExpensesForPeriod(_reportStartDate, _reportEndDate);
  }

 Future<Map<String, double>> getExpensesByCategoryForCurrentPeriod() async {
    // Ensure end date includes the full day
    final endOfDay = DateTime(_reportEndDate.year, _reportEndDate.month, _reportEndDate.day, 23, 59, 59);
    return await _dbHelper.getExpensesByCategoryForPeriod(_reportStartDate, endOfDay);
  }


  void setReportDateRange(DateTime start, DateTime end) {
    _reportStartDate = start;
    _reportEndDate = end;
    notifyListeners();
    // Optionally trigger report data refresh here if needed immediately
    debugPrint('Report date range updated: $start to $end');
  }


  // --- Helper Methods ---

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    // Avoid closing the database here if it's potentially used elsewhere
    // If DBHelper is ONLY used by this controller, you could call _dbHelper.close()
    // However, it's generally safer to manage DB lifecycle separately if shared.
    debugPrint("FinanceController disposed");
    super.dispose();
  }
}