import 'package:dailysync/models/goal_model.dart';
import 'package:flutter/material.dart';


class WaterDetailScreen extends StatelessWidget {
  final Goal goal;
  const WaterDetailScreen({super.key, required this.goal});

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
            Text('Today\'s Intake', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: Icon(Icons.local_drink, color: goal.color, size: 30),
                title: const Text('Total Drank Today'),
                trailing: Text(goal.currentValue, style: TextStyle(color: goal.color, fontWeight: FontWeight.bold, fontSize: 20)),
              ),
            ),
            const SizedBox(height: 24),
            Text('Log', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                children: const [
                   ListTile(title: Text('A glass of water'), subtitle: Text('9:00 AM'), trailing: Text('250 ml')),
                   ListTile(title: Text('A glass of water'), subtitle: Text('11:30 AM'), trailing: Text('250 ml')),
                   ListTile(title: Text('A bottle of water'), subtitle: Text('1:00 PM'), trailing: Text('500 ml')),
                   ListTile(title: Text('A glass of water'), subtitle: Text('3:45 PM'), trailing: Text('250 ml')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
