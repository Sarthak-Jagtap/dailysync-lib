import 'package:dailysync/models/goal_model.dart';
import 'package:flutter/material.dart';


class StepsDetailScreen extends StatelessWidget {
  final Goal goal;
  const StepsDetailScreen({super.key, required this.goal});

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
                child: Text('Weekly Steps Chart', style: TextStyle(color: Colors.grey[600])),
              ),
            ),
            const SizedBox(height: 24),
            Text('Recent Activity', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                children: const [
                  ListTile(title: Text('Today'), trailing: Text('8,420 steps')),
                  ListTile(title: Text('Yesterday'), trailing: Text('10,150 steps')),
                  ListTile(title: Text('2 days ago'), trailing: Text('7,890 steps')),
                   ListTile(title: Text('3 days ago'), trailing: Text('9,200 steps')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
