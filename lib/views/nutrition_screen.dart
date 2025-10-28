// [MODIFIED FILE: lib/view/nutrition_screen.dart]

import 'package:dailysync/controllers/health_controller.dart';
import 'package:dailysync/models/meal_model.dart';
import 'package:dailysync/widgets/logmeal_sheet.dart';
import 'package:flutter/material.dart';
// ADD NEW IMPORTS
import 'package:provider/provider.dart';

// 1. CONVERTED to StatelessWidget
class NutritionScreen extends StatelessWidget { 
  const NutritionScreen({super.key});

  void _showLogMealSheet(BuildContext context) async {
    // Update expected return type to Map<String, dynamic>
    final newMealMap = await showModalBottomSheet<Map<String, dynamic>>( 
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const LogMealSheet(),
    );

    if (newMealMap != null) {
      final provider = Provider.of<HealthController>(context, listen: false);
      
      // Call the provider method to process and store the new meal
      provider.addMeal(
         newMealMap['name'] as String,
         newMealMap['time'] as String,
         newMealMap['calories'] as int,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${newMealMap['name']} has been logged.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 2. Consume the provider to access state
    final healthProvider = Provider.of<HealthController>(context);
    final int calorieGoal = healthProvider.currentCalories;
    final int currentCalories = healthProvider.currentCalories;
    final List<Meal> meals = healthProvider.meals;

    double progress = currentCalories / calorieGoal;

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Meal Tracking", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: () => _showLogMealSheet(context),
                icon: const Icon(Icons.add),
                label: const Text('Log Meal'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Daily Calories', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('$currentCalories / $calorieGoal', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress > 1.0 ? 1.0 : progress,
                    backgroundColor: Colors.teal.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(progress > 1.0 ? Colors.red : Colors.teal),
                    minHeight: 8,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: meals.length,
            itemBuilder: (context, index) {
              final meal = meals[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const Icon(Icons.restaurant_menu, color: Colors.teal),
                  title: Text(meal.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${meal.time} • ${meal.calories} cal'),
                  trailing: meal.isLogged
                      ? Chip(label: const Text('Logged'), backgroundColor: Colors.teal.shade50)
                      : ElevatedButton(
                          // Use provider method for toggling
                          onPressed: () => healthProvider.toggleMealLogStatus(meal.id), 
                          child: const Text('Log'),
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