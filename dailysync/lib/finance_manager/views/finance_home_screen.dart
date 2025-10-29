// lib/finance_manager/views/finance_home_screen.dart
import 'package:dailysync/finance_manager/models/expense_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/finance_controller.dart';
import 'expense_list_screen.dart';
import 'reports_screen.dart';
import 'create_expense_screen.dart';

// Use DefaultTabController, so StatefulWidget and mixin are not needed here
class FinanceHomeScreen extends StatelessWidget {
  const FinanceHomeScreen({super.key});

  // Screens to display in the TabBarView
  static const List<Widget> _widgetOptions = <Widget>[
    ExpenseListScreen(),
    ReportsScreen(),
    // Add more tabs/screens if needed
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Use DefaultTabController to manage tabs
    return DefaultTabController(
      length: _widgetOptions.length, // Number of tabs
      child: Scaffold(
        // NO AppBar needed here anymore, it's handled by HomeScreen

        // Place the TabBar and TabBarView inside the body column
        body: Column(
          children: [
            // TabBar placed directly below the main AppBar (which is in HomeScreen)
            Container(
              color: theme.appBarTheme.backgroundColor ?? theme.colorScheme.surface, // Match AppBar background
              child: TabBar(
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: theme.hintColor,
                indicatorColor: theme.colorScheme.primary,
                // Make tabs less tall if needed
                // indicatorWeight: 3.0, // Adjust indicator thickness
                // labelPadding: EdgeInsets.symmetric(vertical: 8.0), // Adjust padding
                tabs: const <Widget>[
                  Tab(
                    // Removed icon to save vertical space
                    // icon: Icon(Icons.list_alt),
                    text: 'Expenses',
                  ),
                  Tab(
                    // Removed icon to save vertical space
                    // icon: Icon(Icons.bar_chart),
                    text: 'Reports',
                  ),
                ],
              ),
            ),
            // Expanded TabBarView takes the remaining space
            Expanded(
              child: TabBarView(
                children: _widgetOptions,
              ),
            ),
          ],
        ),
        // Floating Action Button remains
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final result = await Navigator.push<Expense?>(
              context,
              MaterialPageRoute(builder: (context) => const CreateExpenseScreen()),
            );
            if (result != null && mounted(context)) { // Added helper function for mounted check
              Provider.of<FinanceController>(context, listen: false).addExpense(result);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Expense "${result.title}" saved!'), duration: const Duration(seconds: 2)),
              );
            }
          },
          tooltip: 'Add Expense',
          backgroundColor: theme.colorScheme.secondary,
          foregroundColor: theme.colorScheme.onSecondary,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  // Helper function to check mounted status safely after async gap
  bool mounted(BuildContext context) {
    try {
      // Accessing context properties will throw if not mounted
      ModalRoute.of(context);
      return true;
    } catch (e) {
      return false;
    }
  }
}