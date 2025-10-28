import 'package:dailysync/models/goal_model.dart';
import 'package:flutter/material.dart';


class SleepDetailScreen extends StatelessWidget {
  final Goal goal;
  const SleepDetailScreen({super.key, required this.goal});

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
            // Placeholder for a chart
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text('Weekly Sleep Chart', style: TextStyle(color: Colors.grey[600])),
              ),
            ),
            const SizedBox(height: 24),
            Text('Recent Nights', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                children: const [
                  ListTile(title: Text('Last Night'), trailing: Text('7h 30m')),
                  ListTile(title: Text('Yesterday'), trailing: Text('8h 15m')),
                  ListTile(title: Text('2 nights ago'), trailing: Text('6h 45m')),
                  ListTile(title: Text('3 nights ago'), trailing: Text('7h 50m')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
