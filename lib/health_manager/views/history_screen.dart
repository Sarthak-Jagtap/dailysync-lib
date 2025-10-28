// lib/health_manager/views/history_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/health_controller.dart';
import 'widgets/weekly_chart.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Provider.of<HealthController>(context);
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(children: [
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(children: [
                const Text('Weekly overview', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView(
                    children: [
                      SizedBox(height: 200, child: WeeklyChart(dataMap: ctrl.waterWeekly, valueLabel: (v) => '${v.toInt()}', barColor: Colors.indigo)),
                      const SizedBox(height: 12),
                      SizedBox(height: 200, child: WeeklyChart(dataMap: ctrl.stepsWeekly, valueLabel: (v) => '${v.toInt()}', barColor: Colors.teal, showTarget: true, target: ctrl.stepTarget)),
                      const SizedBox(height: 12),
                      SizedBox(height: 200, child: WeeklyChart(dataMap: ctrl.sleepWeekly, valueLabel: (v) => '${(v/60).toStringAsFixed(1)}h', barColor: Colors.orange)),
                      const SizedBox(height: 12),
                      SizedBox(height: 200, child: WeeklyChart(dataMap: ctrl.exerciseWeekly, valueLabel: (v) => '${v.toInt()}m', barColor: Colors.purple)),
                    ],
                  ),
                )
              ]),
            ),
          ),
        )
      ]),
    );
  }
}
