// [MODIFIED FILE: lib/view/exercise_screen.dart]

import 'package:dailysync/controllers/health_controller.dart';
import 'package:dailysync/models/exercise_model.dart';
import 'package:dailysync/widgets/addworkoutsheet.dart';
import 'package:flutter/material.dart';
// ADD NEW IMPORTS
import 'package:provider/provider.dart';


// 1. CONVERTED to StatelessWidget
class ExerciseScreen extends StatelessWidget { 
  const ExerciseScreen({super.key});

  void _showAddWorkoutSheet(BuildContext context) async {
    final newWorkout = await showModalBottomSheet<Workout>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const AddWorkoutSheet(),
    );

    if (newWorkout != null) {
      // Call Provider method to add the workout
      final provider = Provider.of<HealthController>(context, listen: false);
      provider.addWorkout(newWorkout); 

       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${newWorkout.title} has been added to your workouts.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    // 2. Consume the provider to access state
    final healthProvider = Provider.of<HealthController>(context);
    final List<Workout> workouts = healthProvider.workouts;

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Today's Workouts", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: () => _showAddWorkoutSheet(context),
                icon: const Icon(Icons.add),
                label: const Text('Add Workout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: workouts.length,
            itemBuilder: (context, index) {
              final workout = workouts[index];
              final isCompleted = workout.status == WorkoutStatus.completed;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Icon(workout.icon, color: Colors.teal, size: 30),
                  title: Text(workout.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${workout.duration} • ${workout.calories}'),
                  trailing: isCompleted
                      ? Chip(label: const Text('Completed'), backgroundColor: Colors.teal.shade50)
                      : ElevatedButton(
                          // Use provider method for toggling
                          onPressed: () => healthProvider.toggleWorkoutStatus(workout), 
                          child: const Text('Start'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.teal,
                            side: BorderSide(color: Colors.teal.shade200)
                          ),
                        ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}