import 'package:dailysync/models/goal_model.dart';
import 'package:dailysync/models/wellness_model.dart';
import 'package:dailysync/views/meditationtimer_screen.dart';
import 'package:dailysync/views/sleep_screen_detail.dart';
import 'package:dailysync/widgets/durationsheet.dart';
import 'package:flutter/material.dart';

class WellnessScreen extends StatelessWidget {
  const WellnessScreen({super.key});

  // Method to show the duration selection bottom sheet
  void _showSelectDurationSheet(BuildContext context) async {
    // Wait for the user to select a duration from the sheet
    final selectedDuration = await showModalBottomSheet<int>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const SelectDurationSheet(),
    );

    // If a duration was selected (the sheet wasn't just dismissed),
    // navigate to the timer screen.
    if (selectedDuration != null && context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MeditationTimerScreen(
            initialDurationInMinutes: selectedDuration,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<WellnessActivity> activities = [
      WellnessActivity(title: 'Meditation', subtitle: 'Custom session', icon: Icons.self_improvement),
      WellnessActivity(title: 'Sleep Tracking', subtitle: 'Last night: 7.5 hours', icon: Icons.bedtime),
    ];

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const Text("Wellness Activities", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildWellnessCard(
          context: context,
          activity: activities[0],
          button: ElevatedButton.icon(
            // When pressed, call the method to show the sheet
            onPressed: () => _showSelectDurationSheet(context),
            icon: const Icon(Icons.play_circle_outline),
            label: const Text('Start Session'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.deepPurple,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildWellnessCard(
          context: context,
          activity: activities[1],
          button: OutlinedButton(
            onPressed: () {
               // Create a Goal object to pass to the detail screen
               final sleepGoal = Goal(
                 title: 'Sleep',
                 currentValue: '7.5 hours',
                 goalValue: '8h goal',
                 progress: 7.5 / 8.0,
                 icon: Icons.bedtime,
                 color: Colors.purple,
               );
               Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => SleepDetailScreen(goal: sleepGoal)),
              );
            },
            child: const Text('View Sleep Data'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.indigo,
              side: const BorderSide(color: Colors.indigo),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWellnessCard({
    required BuildContext context,
    required WellnessActivity activity,
    required Widget button,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(activity.icon, size: 32, color: Theme.of(context).primaryColorDark),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(activity.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(activity.subtitle, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            button,
          ],
        ),
      ),
    );
  }
}

