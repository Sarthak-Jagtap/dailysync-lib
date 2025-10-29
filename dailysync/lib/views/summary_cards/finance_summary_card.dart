import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class FinanceSummaryCardCircular extends StatelessWidget {
  final double dailyBudget = 2000.0;
  final double todaySpent = 1500.0;
  final double monthlySavingsGoal = 20000.0;
  final double currentSavings = 12000.0;

  const FinanceSummaryCardCircular({super.key});

  @override
  Widget build(BuildContext context) {
    final double budgetProgress = (todaySpent / dailyBudget).clamp(0.0, 1.0);
    final double savingsProgress = (currentSavings / monthlySavingsGoal).clamp(0.0, 1.0);
    final double budgetRemaining = dailyBudget - todaySpent;

    // Dynamic color coding: Green, then Yellow, then Red
    Color getProgressColor() {
      if (budgetProgress >= 1.0) return Colors.red.shade600;
      if (budgetProgress >= 0.75) return Colors.amber.shade600;
      return Colors.green.shade600;
    }

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Daily Spending Tracker",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Circular Budget Meter
                CircularPercentIndicator(
                  radius: 70.0,
                  lineWidth: 12.0,
                  animation: true,
                  percent: budgetProgress,
                  center: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "₹${todaySpent.toStringAsFixed(0)}",
                        style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 22.0,
                            color: getProgressColor()),
                      ),
                      Text(
                        "Spent",
                        style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 12.0,
                            color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  circularStrokeCap: CircularStrokeCap.round,
                  progressColor: getProgressColor(),
                  backgroundColor: Colors.grey.shade200,
                ),

                const SizedBox(width: 16),

                // Key Metrics Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMetricRow(
                        context,
                        title: "Daily Budget",
                        value: "₹${dailyBudget.toStringAsFixed(0)}",
                        icon: Icons.account_balance_wallet,
                        color: Colors.blueAccent,
                      ),
                      const Divider(height: 16),
                      _buildMetricRow(
                        context,
                        title: "Remaining",
                        value: "₹${budgetRemaining.toStringAsFixed(0)}",
                        icon: Icons.local_atm,
                        color: budgetRemaining < 0 ? Colors.red : Colors.green,
                      ),
                      const Divider(height: 16),
                      _buildMetricRow(
                        context,
                        title: "Monthly Savings",
                        value: "${(savingsProgress * 100).toInt()}%",
                        icon: Icons.savings,
                        color: Colors.purple,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(BuildContext context, {required String title, required String value, required IconData icon, required Color color}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
