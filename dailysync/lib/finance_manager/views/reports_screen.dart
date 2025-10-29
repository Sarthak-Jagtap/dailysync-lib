// lib/finance_manager/views/reports_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../controllers/finance_controller.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  // Use FutureBuilders to load data when the screen builds or date range changes
  late Future<double> _totalExpensesFuture;
  late Future<Map<String, double>> _categoryExpensesFuture;

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

   @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload data if dependencies change (like controller state updates externally)
    // This might be triggered if the date range is updated in the controller
    // If the controller notifies listeners for date changes, this will react.
     _loadReportData();
  }


  void _loadReportData() {
    // Ensure the widget is still mounted before accessing context or controller
    if (!mounted) return;
    final controller = Provider.of<FinanceController>(context, listen: false);
    setState(() {
      _totalExpensesFuture = controller.getTotalExpensesForCurrentPeriod();
      _categoryExpensesFuture = controller.getExpensesByCategoryForCurrentPeriod();
    });
  }

  // Function to show date range picker
  Future<void> _selectDateRange(BuildContext context) async {
    // Ensure the widget is still mounted before accessing context or controller
    if (!mounted) return;
    final controller = Provider.of<FinanceController>(context, listen: false);
    final initialRange = DateTimeRange(
      start: controller.reportStartDate,
      end: controller.reportEndDate,
    );
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: initialRange,
      firstDate: DateTime(2020), // Adjust as needed
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (picked != null && picked != initialRange) {
       // Check mount status again before calling controller method
       if (mounted) {
         controller.setReportDateRange(picked.start, picked.end);
         // No need to call _loadReportData here if didChangeDependencies handles it
         // _loadReportData(); // Reload data manually if didChangeDependencies doesn't trigger reliably
       }
    }
  }


  @override
  Widget build(BuildContext context) {
    // Watch the controller ONLY for date range changes if necessary
    // If _loadReportData is called correctly on date change, watching might not be needed here.
    final controller = Provider.of<FinanceController>(context, listen: true); // Listen for date changes
    final theme = Theme.of(context);
    final dateFormat = DateFormat.yMMMd(); // Date formatter

    // Removed the Scaffold widget

    // Return the body content directly
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Date Range Selection ---
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded( // Allow text to wrap if needed
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Report Period", style: theme.textTheme.labelSmall),
                        Text(
                          '${dateFormat.format(controller.reportStartDate)} - ${dateFormat.format(controller.reportEndDate)}',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis, // Prevent overflow
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_month_outlined),
                    tooltip: "Select Date Range",
                    onPressed: () => _selectDateRange(context),
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // --- Total Expenses ---
          FutureBuilder<double>(
            future: _totalExpensesFuture,
            builder: (context, snapshot) {
              Widget content;
              if (snapshot.connectionState == ConnectionState.waiting) {
                content = const Center(child: LinearProgressIndicator()); // Use LinearProgressIndicator inside ListTile
              } else if (snapshot.hasError) {
                content = Center(child: Text('Error loading total', style: TextStyle(color: theme.colorScheme.error)));
              } else {
                 final total = snapshot.data ?? 0.0;
                 content = ListTile(
                    leading: Icon(Icons.calculate_outlined, color: theme.colorScheme.secondary),
                    title: const Text("Total Spent"),
                    trailing: Text(
                      '₹${total.toStringAsFixed(2)}',
                      style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold, color: theme.colorScheme.error),
                    ),
                  );
              }
               return Card(
                 elevation: 1,
                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                 child: content,
               );
            },
          ),
          const SizedBox(height: 20),

          // --- Expenses by Category (Pie Chart) ---
          Text("Spending by Category", style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          FutureBuilder<Map<String, double>>(
            future: _categoryExpensesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(height: 250, child: Center(child: CircularProgressIndicator()));
              }
              if (snapshot.hasError) {
                return SizedBox(height: 250, child: Center(child: Text('Error: ${snapshot.error}')));
              }
              final categoryData = snapshot.data ?? {};
              if (categoryData.isEmpty) {
                 return const SizedBox(height: 250, child: Center(child: Text("No spending in this period.")));
              }

              final pieChartSections = _createPieChartSections(categoryData, theme);

              return Card(
                 elevation: 1,
                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    height: 250,
                    child: PieChart(
                      PieChartData(
                         sections: pieChartSections,
                         centerSpaceRadius: 60,
                         sectionsSpace: 2,
                         pieTouchData: PieTouchData(
                          touchCallback: (FlTouchEvent event, pieTouchResponse) {
                            // Optional interactivity
                          },
                        ),
                         centerSpaceColor: Colors.transparent,
                         borderData: FlBorderData(show: false),
                      ),
                       swapAnimationDuration: const Duration(milliseconds: 150),
                      swapAnimationCurve: Curves.linear,
                    ),
                  ),
                ),
              );
            },
          ),
           const SizedBox(height: 20),

           // --- Category Legend/List ---
           Text("Category Breakdown", style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
           FutureBuilder<Map<String, double>>(
            future: _categoryExpensesFuture,
            builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                return Card( // Wrap in card for consistency
                   elevation: 0,
                  margin: const EdgeInsets.only(bottom: 8),
                   shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Colors.transparent)),
                  child: const ListTile(title: Center(child: Text("No category data available."))),
                );
              }
               final categoryData = snapshot.data!;
               final sortedCategories = categoryData.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value)); // Sort descending

               return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sortedCategories.length,
                  itemBuilder: (context, index) {
                    final entry = sortedCategories[index];
                    final color = _getCategoryColorForChart(entry.key, index, theme);
                    return Card(
                       elevation: 0,
                       margin: const EdgeInsets.only(bottom: 8),
                       shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: theme.dividerColor)),
                      child: ListTile(
                        dense: true,
                         leading: CircleAvatar(backgroundColor: color, radius: 10),
                        title: Text(entry.key),
                        trailing: Text('₹${entry.value.toStringAsFixed(2)}'),
                      ),
                    );
                  },
                );
            }
           ),
            const SizedBox(height: 80), // Add padding at the bottom if needed
        ],
      ),
    );
  }

  // --- Helper Functions --- (Keep these helpers)

 List<PieChartSectionData> _createPieChartSections(Map<String, double> data, ThemeData theme) {
    // ... (implementation remains the same)
     if (data.isEmpty) return [];

    final total = data.values.fold(0.0, (sum, item) => sum + item);
    if (total <= 0) return []; // Avoid division by zero

    final sortedEntries = data.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return List.generate(sortedEntries.length, (index) {
      final entry = sortedEntries[index];
      final percentage = (entry.value / total) * 100;
      final color = _getCategoryColorForChart(entry.key, index, theme);

      return PieChartSectionData(
        color: color,
        value: entry.value,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 80,
        titleStyle: TextStyle(
            fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white, shadows: [
              Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 2)
            ]),
        borderSide: BorderSide(color: theme.cardColor, width: 1), // Use card color for border
      );
    });
  }

  Color _getCategoryColorForChart(String category, int index, ThemeData theme) {
    // ... (implementation remains the same)
    final List<Color> chartColors = [
      Colors.blue, Colors.red, Colors.green, Colors.orange, Colors.purple,
      Colors.teal, Colors.pink, Colors.amber, Colors.cyan, Colors.indigo,
       Colors.lime, Colors.brown,
    ];
     switch (category.toLowerCase()) {
      case 'food': return Colors.orange.shade400;
      case 'transport': return Colors.blue.shade400;
      case 'bills': return Colors.red.shade400;
      case 'entertainment': return Colors.purple.shade400;
      case 'shopping': return Colors.green.shade400;
      case 'health': return Colors.pink.shade300;
      case 'groceries': return Colors.teal.shade400;
      default: return chartColors[index % chartColors.length];
    }
  }
}