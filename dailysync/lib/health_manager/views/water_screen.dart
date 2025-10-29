// lib/health_manager/views/water_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../controllers/health_controller.dart';
import '../views/widgets/weekly_chart.dart';

class WaterScreen extends StatefulWidget {
  const WaterScreen({super.key});
  @override
  State<WaterScreen> createState() => _WaterScreenState();
}

class _WaterScreenState extends State<WaterScreen> {
  int _glasses = 1;
  final Color _primaryColor = Colors.green; // Use green as primary
  final Color _secondaryColor = Colors.lightGreen; // Lighter green

  @override
  Widget build(BuildContext context) {
    final ctrl = Provider.of<HealthController>(context);
    final weekStart = DateFormat.MMMd().format(ctrl.currentWeekStart);
    final weekEnd = DateFormat.MMMd().format(ctrl.currentWeekEnd);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Weekly Summary Chart ---
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                     Text(
                      'Weekly Water Intake ($weekStart - $weekEnd)',
                      style: const TextStyle(fontWeight: FontWeight.bold)
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 180,
                      child: WeeklyChart(
                        dataMap: ctrl.waterWeekly,
                        valueLabel: (v) => '${v.toInt()} gl',
                        barColor: _secondaryColor, // Use secondary green
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // --- Water Input Section ---
            Card(
              color: _primaryColor.withOpacity(0.1), // Light green background
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.local_drink, size: 36, color: _primaryColor),
                    const SizedBox(width: 12),
                    Expanded(child: Text('Add water (glasses)', style: Theme.of(context).textTheme.titleMedium)),
                    DropdownButton<int>(
                      value: _glasses,
                      items: List.generate(12, (i) => i + 1).map((g) => DropdownMenuItem(value: g, child: Text('$g'))).toList(),
                      onChanged: (v) => setState(() => _glasses = v ?? 1),
                      dropdownColor: Colors.lightGreen[50], // Match theme
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        final healthController = Provider.of<HealthController>(context, listen: false);
                        await healthController.addWater(_glasses);
                        if(mounted) {
                           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Water added')));
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: _primaryColor), // Use primary green
                      child: const Text('Add'),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

