// lib/finance_manager/views/expense_list_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../controllers/finance_controller.dart';
import '../models/expense_model.dart';
import 'create_expense_screen.dart'; // To navigate for editing

class ExpenseListScreen extends StatelessWidget {
  const ExpenseListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Listen to changes in the controller
    final controller = Provider.of<FinanceController>(context);
    final theme = Theme.of(context);

    // Removed the Scaffold widget

    // Return the body content directly
    return controller.isLoading
        ? const Center(child: CircularProgressIndicator())
        : controller.expenses.isEmpty
            ? Center(
                child: Text(
                'No expenses recorded yet.\nTap "+" to add one!',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(color: theme.hintColor),
              ))
            : ListView.builder(
                padding: const EdgeInsets.only(top: 8.0, left: 8.0, right: 8.0, bottom: 80.0), // Add padding, esp. bottom for FAB
                itemCount: controller.expenses.length,
                itemBuilder: (context, index) {
                  final expense = controller.expenses[index];
                  return Card(
                     elevation: 1, // Subtle elevation
                     margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0), // Adjust horizontal margin
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getCategoryColor(expense.category, theme).withOpacity(0.2),
                        foregroundColor: _getCategoryColor(expense.category, theme),
                        child: _getCategoryIcon(expense.category),
                      ),
                      title: Text(expense.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        '${expense.category} • ${expense.merchant ?? "N/A"} • ${DateFormat.yMd().add_jm().format(expense.date)}',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                      ),
                      trailing: Text(
                        '₹${expense.amount.toStringAsFixed(2)}', // Format amount
                        style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold, color: theme.colorScheme.error),
                      ),
                      onTap: () async {
                         // Navigate to edit screen
                        final result = await Navigator.push<Expense?>(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  CreateExpenseScreen(existingExpense: expense)),
                        );
                        if (result != null && context.mounted) {
                          controller.updateExpense(result);
                           ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Expense "${result.title}" updated!')),
                          );
                        }
                      },
                       onLongPress: () { // Add delete confirmation on long press
                        _showDeleteConfirmation(context, controller, expense);
                      },
                    ),
                  );
                },
              );
  }

   // --- Helper Functions --- (Keep these helpers)

  Icon _getCategoryIcon(String category) {
    // ... (implementation remains the same)
    switch (category.toLowerCase()) {
      case 'food': return const Icon(Icons.fastfood);
      case 'transport': return const Icon(Icons.directions_bus);
      case 'bills': return const Icon(Icons.receipt);
      case 'entertainment': return const Icon(Icons.movie);
      case 'shopping': return const Icon(Icons.shopping_bag);
      case 'health': return const Icon(Icons.medical_services);
      case 'groceries': return const Icon(Icons.local_grocery_store);
      default: return const Icon(Icons.category);
    }
  }

  Color _getCategoryColor(String category, ThemeData theme) {
    // ... (implementation remains the same)
    switch (category.toLowerCase()) {
      case 'food': return Colors.orange;
      case 'transport': return Colors.blue;
      case 'bills': return Colors.red;
      case 'entertainment': return Colors.purple;
      case 'shopping': return Colors.green;
      case 'health': return Colors.pink;
      case 'groceries': return Colors.teal;
      default: return theme.colorScheme.secondary;
    }
  }

   void _showDeleteConfirmation(BuildContext context, FinanceController controller, Expense expense) {
    // ... (implementation remains the same)
     showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Delete Expense?'),
          content: Text('Are you sure you want to delete "${expense.title}"? This cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(ctx).pop(); // Close the dialog
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
              child: const Text('Delete'),
              onPressed: () {
                 if (expense.id != null) {
                  controller.deleteExpense(expense.id!);
                   ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Expense "${expense.title}" deleted.')),
                  );
                }
                Navigator.of(ctx).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }
}