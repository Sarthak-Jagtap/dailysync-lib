import 'package:flutter/material.dart';

// --- Model for Mock Data ---
class Task {
  final String title;
  final bool isCompleted;
  final String priority;

  // Added 'const' modifier
  const Task(this.title, this.isCompleted, this.priority);
}

// --- Main To-Do Summary Card Component (Now Stateful) ---
class TodoSummaryCard extends StatefulWidget {
  const TodoSummaryCard({super.key});

  @override
  State<TodoSummaryCard> createState() => _TodoSummaryCardState();
}

class _TodoSummaryCardState extends State<TodoSummaryCard> {
  // Mock data moved to state, no longer static const, so it can be mutated
  List<Task> mockTasks = [
    const Task("Finalize project report", false, "High"),
    const Task("Schedule team review meeting", true, "High"),
    const Task("Review Q3 marketing plan", false, "Medium"),
    const Task("Draft email to client X", false, "Medium"),
    const Task("Research new flutter packages", true, "Medium"),
    const Task("Clean up inbox folders", false, "Low"),
    const Task("Organize desktop files", false, "Low"),
    const Task("Update LinkedIn profile", true, "Low"),
  ];

  // Function to toggle task completion and trigger setState
  void toggleTaskCompletion(Task task) {
    setState(() {
      final index = mockTasks.indexOf(task);
      if (index != -1) {
        // Replace the old task with a new one with the toggled status
        mockTasks[index] = Task(
          task.title,
          !task.isCompleted,
          task.priority,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Filter tasks for each column
    final highTasks = mockTasks.where((t) => t.priority == "High").take(5).toList();
    final mediumTasks = mockTasks.where((t) => t.priority == "Medium").take(5).toList();
    final lowTasks = mockTasks.where((t) => t.priority == "Low").take(5).toList();

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Task Priorities",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Horizontal Scroll View for the columns
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // High Priority Column (fixed width)
                  SizedBox(
                    width: 250, // Increased width for readability
                    child: _PriorityColumn(
                      title: "High Priority",
                      tasks: highTasks,
                      color: Colors.red[600]!,
                      backgroundColor: Colors.red[50]!,
                      onTaskToggled: toggleTaskCompletion,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Medium Priority Column (fixed width)
                  SizedBox(
                    width: 250, // Increased width
                    child: _PriorityColumn(
                      title: "Medium Priority",
                      tasks: mediumTasks,
                      color: Colors.orange[600]!,
                      backgroundColor: Colors.orange[50]!,
                      onTaskToggled: toggleTaskCompletion,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Low Priority Column (fixed width)
                  SizedBox(
                    width: 250, // Increased width
                    child: _PriorityColumn(
                      title: "Low Priority",
                      tasks: lowTasks,
                      color: Colors.green[600]!,
                      backgroundColor: Colors.green[50]!,
                      onTaskToggled: toggleTaskCompletion,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Helper Widget for Priority Column ---
class _PriorityColumn extends StatelessWidget {
  final String title;
  final List<Task> tasks;
  final Color color;
  final Color backgroundColor;
  final Function(Task) onTaskToggled; // New callback

  const _PriorityColumn({
    required this.title,
    required this.tasks,
    required this.color,
    required this.backgroundColor,
    required this.onTaskToggled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      constraints: const BoxConstraints(minHeight: 200), // Ensure minimum height for visual balance
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const Divider(height: 12, thickness: 1),
          // List of task items
          ...tasks.map((task) => _TaskItem(
                task: task, 
                color: color, 
                onToggled: onTaskToggled, // Pass callback
              )).toList(),
          if (tasks.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text("No $title tasks.", style: TextStyle(color: color.withOpacity(0.7))),
            ),
        ],
      ),
    );
  }
}

// --- Helper Widget for Individual Task Item ---
class _TaskItem extends StatelessWidget {
  final Task task;
  final Color color;
  final Function(Task) onToggled; // Required callback

  const _TaskItem({
    required this.task, 
    required this.color, 
    required this.onToggled,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 20,
            width: 20,
            child: Checkbox(
              value: task.isCompleted,
              // Bind the onChanged to the state function
              onChanged: (val) {
                // Ignore the boolean value and just pass the task object to the state's toggle function
                onToggled(task);
              },
              activeColor: color,
              checkColor: Colors.white,
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 3.0),
              child: Text(
                task.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: task.isCompleted ? Colors.grey : Colors.black87,
                  decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
