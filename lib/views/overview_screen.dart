import 'package:dailysync/models/goal_model.dart';
import 'package:dailysync/views/sleep_screen_detail.dart';
import 'package:dailysync/views/steps_detail_screen.dart';
import 'package:dailysync/views/water_detail_screen.dart';
import 'package:dailysync/views/workout_detail_screen.dart';
import 'package:dailysync/widgets/addwatersheet.dart';
import 'package:dailysync/widgets/bottomsheet.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dailysync/controllers/health_controller.dart'; // <--- UPDATED IMPORT

class OverviewScreen extends StatelessWidget {
  const OverviewScreen({super.key});

  void _showLogWorkoutSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const LogWorkoutSheet(),
    );
  }

  void _showAddWaterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => const AddWaterSheet(),
    );
  }

  // Method to handle navigation (unchanged from original)
  void _navigateToDetail(BuildContext context, Goal goal) {
    Widget page;
    switch (goal.title) {
      case 'Steps':
        page = StepsDetailScreen(goal: goal);
        break;
      case 'Water':
        page = WaterDetailScreen(goal: goal);
        break;
      case 'Sleep':
        page = SleepDetailScreen(goal: goal);
        break;
      case 'Workouts':
        page = WorkoutsDetailScreen(goal: goal);
        break;
      default:
        return; 
    }

    Navigator.of(context).push(
      MaterialPageRoute(builder: (ctx) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Consume the controller and get the dynamic goals list
    final healthController = Provider.of<HealthController>(context);
    final List<Goal> goals = healthController.goals;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Today's Goals", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
            ),
            itemCount: goals.length,
            itemBuilder: (context, index) {
              final goal = goals[index];
              
              return InkWell(
                onTap: () => _navigateToDetail(context, goal),
                borderRadius: BorderRadius.circular(12.0),
                child: _buildGoalCard(context, goal),
              );
            },
          ),
          const SizedBox(height: 24),
          const Text("Quick Actions", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Log Workout'),
                  onPressed: () => _showLogWorkoutSheet(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.opacity),
                  label: const Text('Add Water'),
                  onPressed: () => _showAddWaterSheet(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.teal,
                    side: const BorderSide(color: Colors.teal),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Button to trigger the live data fetch and permission prompt
          Center(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.cloud_sync, color: Colors.white),
              label: const Text('Sync Mobile Data', style: TextStyle(color: Colors.white)),
              onPressed: () {
                healthController.fetchMobileSensorData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Requesting data sync with Google Fit...')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildGoalCard(BuildContext context, Goal goal) {
    // ... (unchanged helper method)
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(goal.icon, color: goal.color),
                Text(
                  goal.currentValue,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: goal.color),
                ),
              ],
            ),
            const Spacer(),
            Text(goal.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(goal.goalValue, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: goal.progress,
              backgroundColor: goal.color.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(goal.color),
            ),
          ],
        ),
      ),
    );
  }
}
