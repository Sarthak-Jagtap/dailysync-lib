import 'package:dailysync/models/goal_model.dart';
import 'package:flutter/material.dart';


class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Reusing the Goal model with sample data
    final List<Goal> goals = [
      Goal(title: 'Steps', currentValue: '8,420', goalValue: '10,000 steps', progress: 0.84, icon: Icons.directions_walk, color: Colors.green),
      Goal(title: 'Water Intake', currentValue: '1.5L', goalValue: '2L goal', progress: 0.75, icon: Icons.local_drink, color: Colors.blue),
      Goal(title: 'Sleep', currentValue: '7.5h', goalValue: '8h goal', progress: 0.93, icon: Icons.bedtime, color: Colors.purple),
      Goal(title: 'Active Calories', currentValue: '350', goalValue: '500 kcal', progress: 0.70, icon: Icons.local_fire_department, color: Colors.orange),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Goals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note),
            onPressed: () {
              // Placeholder for editing goals
               ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Edit Goals...'))
                );
            },
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: goals.length,
        itemBuilder: (context, index) {
          final goal = goals[index];
          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(goal.icon, color: goal.color, size: 28),
                      const SizedBox(width: 12),
                      Text(
                        goal.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        goal.currentValue,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: goal.color),
                      ),
                      Text(
                        goal.goalValue,
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: goal.progress,
                    minHeight: 8,
                    backgroundColor: goal.color.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(goal.color),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

