// lib/routine_manager/views/schedule_review_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/routine_controller.dart';
import '../models/routine_models.dart';

class ScheduleReviewScreen extends StatefulWidget {
  final List<RoutineTask> generatedTasks;
  // --- ADDED COLOR PARAMETERS ---
  final Color primaryColor;
  final Color accentColor;

  const ScheduleReviewScreen({
    super.key,
    required this.generatedTasks,
    required this.primaryColor, // Required in constructor
    required this.accentColor,  // Required in constructor
  });

  @override
  State<ScheduleReviewScreen> createState() => _ScheduleReviewScreenState();
}

class _ScheduleReviewScreenState extends State<ScheduleReviewScreen> {
  bool _isSaving = false;

  Future<void> _saveSchedule() async {
    setState(() => _isSaving = true);
    final controller = Provider.of<RoutineController>(context, listen: false);

    try {
      await controller.saveNewMasterTemplate(widget.generatedTasks);
      if (mounted) {
        // Pop twice: once for this screen, once for the setup screen
        Navigator.pop(context); // Pop review screen
        Navigator.pop(context); // Pop setup screen
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('New routine saved successfully!'),
            backgroundColor: widget.primaryColor, // Use passed color
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving routine: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Your Generated Schedule'),
        backgroundColor: widget.primaryColor, // Use passed color
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: widget.generatedTasks.length,
              itemBuilder: (context, index) {
                final task = widget.generatedTasks[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                  child: ListTile(
                    leading: CircleAvatar(
                       backgroundColor: widget.primaryColor.withOpacity(0.1), // Use passed color
                       foregroundColor: widget.primaryColor, // Use passed color
                       child: _getCategoryIcon(task.category),
                    ),
                    title: Text(task.taskTitle),
                    subtitle: Text('${task.startTime} - ${task.endTime} (${task.category})'),
                  ),
                );
              },
            ),
          ),
          // --- Save Button ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              icon: _isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.check_circle_outline),
              label: Text(_isSaving ? 'Saving...' : 'Looks Good! Save My Routine'),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.accentColor, // Use passed color
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50), // Make button wide
                textStyle: const TextStyle(fontSize: 16),
              ),
              onPressed: _isSaving ? null : _saveSchedule,
            ),
          ),
        ],
      ),
    );
  }

  // Helper to get an icon based on category (customize as needed)
  Icon _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'work': return const Icon(Icons.work_outline);
      case 'health': return const Icon(Icons.fitness_center);
      case 'personal': return const Icon(Icons.person_outline);
      case 'focus': return const Icon(Icons.psychology_outlined);
      case 'meal': return const Icon(Icons.restaurant_outlined);
      case 'commute': return const Icon(Icons.directions_car_outlined);
      case 'break': return const Icon(Icons.coffee_outlined);
      default: return const Icon(Icons.label_outline);
    }
  }
}

