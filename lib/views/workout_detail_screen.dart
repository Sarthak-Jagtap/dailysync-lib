import 'package:dailysync/models/goal_model.dart';
import 'package:flutter/material.dart';


class WorkoutsDetailScreen extends StatelessWidget {
  final Goal goal;
  const WorkoutsDetailScreen({super.key, required this.goal});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(goal.title),
        backgroundColor: goal.color.withOpacity(0.1),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This Week\'s Workouts', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: Icon(Icons.fitness_center, color: goal.color, size: 30),
                title: const Text('Total This Week'),
                trailing: Text(goal.currentValue, style: TextStyle(color: goal.color, fontWeight: FontWeight.bold, fontSize: 20)),
              ),
            ),
             const SizedBox(height: 24),
            Text('History', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                children: const [
                   ListTile(title: Text('Morning Run'), subtitle: Text('Today'), trailing: Text('320 cal')),
                   ListTile(title: Text('Strength Training'), subtitle: Text('Yesterday'), trailing: Text('450 cal')),
                   ListTile(title: Text('Yoga Session'), subtitle: Text('3 days ago'), trailing: Text('150 cal')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
