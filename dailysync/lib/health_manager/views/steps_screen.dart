// lib/health_manager/views/steps_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../controllers/health_controller.dart';
import 'widgets/weekly_chart.dart'; // Import chart

class StepsScreen extends StatefulWidget {
  const StepsScreen({super.key});
  @override
  State<StepsScreen> createState() => _StepsScreenState();
}

class _StepsScreenState extends State<StepsScreen> {
  int _stepsToAdd = 500;
  final TextEditingController _targetController = TextEditingController();
  final Color _primaryColor = Colors.green; // Green theme
  final Color _secondaryColor = Colors.lightGreen; // Lighter green

  @override
  void initState() {
    super.initState();
     WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctrl = Provider.of<HealthController>(context, listen: false);
        _targetController.text = ctrl.stepTarget.toString();
     });
  }

   @override
  void dispose() {
    _targetController.dispose();
    super.dispose();
  }

  Future<void> _showSetTargetDialog(HealthController ctrl) async {
    _targetController.text = ctrl.stepTarget.toString();

    final newTarget = await showDialog<int>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Set Daily Step Target'),
          content: TextField(
            controller: _targetController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Target steps'),
            autofocus: true,
             onSubmitted: (value) {
               final target = int.tryParse(value);
               if (target != null && target > 0) Navigator.pop(ctx, target);
            },
          ),
          actions: [
            TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: _primaryColor), // Green button
                onPressed: () {
                   final target = int.tryParse(_targetController.text);
                   if (target != null && target > 0) Navigator.pop(ctx, target);
                }, child: const Text('Save'))
          ],
        );
      },
    );

    if (newTarget != null) {
      await Provider.of<HealthController>(context, listen: false).setStepTarget(newTarget);
    }
  }


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
              child: Column(children: [
                 Text('Weekly Steps ($weekStart - $weekEnd)',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                SizedBox(
                  height: 180,
                  child: WeeklyChart(
                    dataMap: ctrl.stepsWeekly,
                    valueLabel: (v) => NumberFormat.compact().format(v.toInt()), // Compact format
                    barColor: _secondaryColor, // Use secondary green
                    showTarget: true,
                    target: ctrl.stepTarget,
                  ),
                )
              ]),
            ),
          ),
          const SizedBox(height: 16),

          // --- Step Target Card ---
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                    children: [
                      Icon(Icons.flag_outlined, color: _primaryColor), // Green icon
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text('Daily target: ${ctrl.stepTarget} steps', style: const TextStyle(fontSize: 16))),
                      IconButton(
                        tooltip: 'Edit Target',
                        onPressed: () => _showSetTargetDialog(ctrl),
                        icon: Icon(Icons.edit_outlined, color: Colors.grey[600]), // Neutral edit icon
                      )
                    ],
                  ),
            ),
          ),
          const SizedBox(height: 16),

          // --- Add Steps Card ---
          Card(
             elevation: 2,
             color: _primaryColor.withOpacity(0.1), // Light green background
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                    children: [
                      Icon(Icons.add_circle_outline, size: 30, color: _primaryColor),
                      const SizedBox(width: 12),
                      const Text('Add steps:', style: TextStyle(fontSize: 16)),
                      const Spacer(),
                      DropdownButton<int>(
                        value: _stepsToAdd,
                        items: [100, 250, 500, 1000, 2000, 5000]
                            .map((s) => DropdownMenuItem(
                                value: s, child: Text('$s')))
                            .toList(),
                        onChanged: (v) => setState(() => _stepsToAdd = v ?? 500),
                        dropdownColor: Colors.lightGreen[50], // Match theme
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: _primaryColor), // Use primary green
                        onPressed: () async {
                          final healthController = Provider.of<HealthController>(context, listen: false);
                          await healthController.addSteps(_stepsToAdd);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('$_stepsToAdd steps added')));
                          }
                        },
                        child: const Text('Add'),
                      )
                    ],
                  ),
            ),
          ),
        ]),
      ),
    );
  }
}

