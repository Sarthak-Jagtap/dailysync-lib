import 'package:dailysync/views/routine_summary_card.dart';
import 'package:flutter/material.dart';

// --- Model for RoutineStep (Moved here for self-contained file) ---
// Note: This model should ideally be in a separate model file, 
// but is included here for a complete, self-contained UI file.
class RoutineStep {
  final String title;
  final TimeOfDay startTime;
  final bool isCompleted;

  const RoutineStep(this.title, this.startTime, this.isCompleted);

  // Helper method to create a copy with a toggled state
  RoutineStep toggleCompletion() {
    return RoutineStep(title, startTime, !isCompleted);
  }
}

class RoutineMainScreen extends StatefulWidget {
  const RoutineMainScreen({super.key});

  @override
  State<RoutineMainScreen> createState() => _RoutineMainScreenState();
}

class _RoutineMainScreenState extends State<RoutineMainScreen> {
  // Mock routine data (similar to RoutineSummaryCard, but for the main page)
  List<RoutineStep> routineSteps = [
    const RoutineStep("Wake Up & Hydrate", TimeOfDay(hour: 7, minute: 0), false),
    const RoutineStep("Morning Workout", TimeOfDay(hour: 7, minute: 30), false),
    const RoutineStep("Deep Work Block 1", TimeOfDay(hour: 9, minute: 30), false),
    const RoutineStep("Team Sync Meeting", TimeOfDay(hour: 11, minute: 0), false),
    const RoutineStep("Lunch & Walk", TimeOfDay(hour: 13, minute: 0), false),
    const RoutineStep("Deep Work Block 2", TimeOfDay(hour: 14, minute: 0), false),
    const RoutineStep("Review & Planning", TimeOfDay(hour: 17, minute: 0), false),
    const RoutineStep("Evening Wind Down", TimeOfDay(hour: 18, minute: 30), false),
    const RoutineStep("Dinner & Family Time", TimeOfDay(hour: 19, minute: 30), false),
    const RoutineStep("Read & Journal", TimeOfDay(hour: 21, minute: 0), false),
    const RoutineStep("Bedtime Prep", TimeOfDay(hour: 22, minute: 0), false),
  ];

  void _toggleStep(RoutineStep step) {
    setState(() {
      final index = routineSteps.indexWhere((s) => s.title == step.title);
      if (index != -1) {
        routineSteps[index] = step.toggleCompletion();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Separate completed and pending tasks
    final completedSteps = routineSteps.where((s) => s.isCompleted).toList();
    final pendingSteps = routineSteps.where((s) => !s.isCompleted).toList();
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text('Daily Routine'),
            floating: true,
            pinned: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_note_outlined),
                onPressed: () {
                  // Action to edit the entire routine/schedule
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Edit Routine...'))
                  );
                },
              ),
            ],
          ),
          
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  // A summary card is a great way to start
                  const RoutineSummaryCard(),
                  const SizedBox(height: 24),
                  
                  // Pending Steps Section
                  Text(
                    'Pending Steps (${pendingSteps.length})',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  
                  // List of Pending Steps
                  ...pendingSteps.map((step) => _buildRoutineTile(context, step, isCompleted: false, onTap: () => _toggleStep(step))),
                  
                  const SizedBox(height: 32),
                  
                  // Completed Steps Section
                  Text(
                    'Completed Steps (${completedSteps.length})',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  
                  // List of Completed Steps
                  ...completedSteps.map((step) => _buildRoutineTile(context, step, isCompleted: true, onTap: () => _toggleStep(step))),
                  
                  if (routineSteps.isEmpty)
                    const Center(child: Text("No routine steps defined.")),
                  
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRoutineTile(BuildContext context, RoutineStep step, {required bool isCompleted, required VoidCallback onTap}) {
    final Color primaryColor = isCompleted ? Colors.green.shade600! : Colors.blueAccent.shade400!;
    
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      color: isCompleted ? Colors.green.withOpacity(0.08) : Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: primaryColor,
          child: isCompleted
              ? const Icon(Icons.check, color: Colors.white)
              : Text(
                  step.startTime.format(context),
                  style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                ),
        ),
        title: Text(
          step.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: isCompleted ? TextDecoration.lineThrough : null,
            color: isCompleted ? Colors.grey : null,
          ),
        ),
        subtitle: Text(
          isCompleted ? 'Completed' : 'Starts at ${step.startTime.format(context)}',
          style: TextStyle(color: isCompleted ? Colors.green : Colors.grey),
        ),
        trailing: IconButton(
          icon: Icon(
            isCompleted ? Icons.close_rounded : Icons.check_circle_outline,
            color: isCompleted ? Colors.red : primaryColor,
          ),
          onPressed: onTap,
        ),
        onTap: onTap,
      ),
    );
  }
}