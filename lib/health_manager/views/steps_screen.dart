// lib/health_manager/views/steps_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/health_controller.dart';
import 'widgets/weekly_chart.dart';

class StepsScreen extends StatefulWidget {
  const StepsScreen({super.key});
  @override
  State<StepsScreen> createState() => _StepsScreenState();
}

class _StepsScreenState extends State<StepsScreen> {
  int _stepsToAdd = 500;

  @override
  Widget build(BuildContext context) {
    final ctrl = Provider.of<HealthController>(context);
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.directions_walk, color: Colors.indigo),
                    const SizedBox(width: 8),
                    Expanded(child: Text('Set daily target: ${ctrl.stepTarget} steps')),
                    IconButton(
                      onPressed: () async {
                        final n = await showDialog<int>(
                          context: context,
                          builder: (ctx) {
                            int temp = ctrl.stepTarget;
                            return AlertDialog(
                              title: const Text('Set Step Target'),
                              content: TextField(
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Target steps'),
                                onChanged: (v) => temp = int.tryParse(v) ?? temp,
                              ),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                ElevatedButton(onPressed: () => Navigator.pop(ctx, temp), child: const Text('Save'))
                              ],
                            );
                          },
                        );
                        if (n != null) ctrl.setStepTarget(n);
                      },
                      icon: const Icon(Icons.edit),
                    )
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Add steps:'),
                    const SizedBox(width: 12),
                    DropdownButton<int>(
                      value: _stepsToAdd,
                      items: [100, 250, 500, 1000, 2000].map((s) => DropdownMenuItem(value: s, child: Text('$s'))).toList(),
                      onChanged: (v) => setState(() => _stepsToAdd = v ?? 500),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                      onPressed: () async {
                        await ctrl.addSteps(_stepsToAdd);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Steps added')));
                      },
                      child: const Text('Add'),
                    )
                  ],
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
              child: Column(children: [
                const Text('Weekly steps', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Expanded(
                  child: WeeklyChart(
                    dataMap: ctrl.stepsWeekly,
                    valueLabel: (v) => '${v.toInt()}',
                    barColor: Colors.teal,
                    showTarget: true,
                    target: ctrl.stepTarget,
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
