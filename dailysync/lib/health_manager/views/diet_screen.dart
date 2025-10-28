// lib/health_manager/views/diet_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../controllers/health_controller.dart';

class DietScreen extends StatefulWidget {
  const DietScreen({super.key});

  @override
  State<DietScreen> createState() => _DietScreenState();
}

class _DietScreenState extends State<DietScreen> {
  DateTime selectedDate = DateTime.now();
  bool morning = false, breakfast = false, lunch = false, snacks = false, dinner = false;

  Future<void> _save(HealthController ctrl) async {
    await ctrl.addDiet(
      date: selectedDate,
      morningDryFruits: morning,
      breakfast: breakfast,
      lunch: lunch,
      snacks: snacks,
      dinner: dinner,
    );
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Diet saved')));
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Provider.of<HealthController>(context);
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Text('Date: ${DateFormat.yMMMd().format(selectedDate)}'),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () async {
                  final d = await showDatePicker(context: context, initialDate: selectedDate, firstDate: DateTime.now().subtract(const Duration(days: 365)), lastDate: DateTime.now());
                  if (d != null) setState(() => selectedDate = d);
                },
                child: const Text('Change'),
              )
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: ListView(
                  children: [
                    CheckboxListTile(title: const Text('Morning dry fruits'), value: morning, onChanged: (v) => setState(() => morning = v ?? false)),
                    CheckboxListTile(title: const Text('Breakfast'), value: breakfast, onChanged: (v) => setState(() => breakfast = v ?? false)),
                    CheckboxListTile(title: const Text('Lunch'), value: lunch, onChanged: (v) => setState(() => lunch = v ?? false)),
                    CheckboxListTile(title: const Text('Snacks'), value: snacks, onChanged: (v) => setState(() => snacks = v ?? false)),
                    CheckboxListTile(title: const Text('Dinner'), value: dinner, onChanged: (v) => setState(() => dinner = v ?? false)),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                      onPressed: () => _save(ctrl),
                      child: const Text('Save Diet'),
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
