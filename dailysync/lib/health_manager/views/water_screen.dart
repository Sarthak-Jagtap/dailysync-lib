// lib/health_manager/views/water_screen.dart
import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    final ctrl = Provider.of<HealthController>(context);
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Card(
            color: Colors.indigo.shade50,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.local_drink, size: 36, color: Colors.indigo),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Add water (glasses)', style: Theme.of(context).textTheme.titleMedium)),
                  DropdownButton<int>(
                    value: _glasses,
                    items: List.generate(12, (i) => i + 1).map((g) => DropdownMenuItem(value: g, child: Text('$g'))).toList(),
                    onChanged: (v) => setState(() => _glasses = v ?? 1),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      await ctrl.addWater(_glasses);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Water added')));
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                    child: const Text('Add'),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    const Text('Weekly water (glasses)', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Expanded(
                      child: WeeklyChart(
                        dataMap: ctrl.waterWeekly,
                        valueLabel: (v) => '${v.toInt()}',
                        barColor: Colors.indigo,
                      ),
                    )
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
