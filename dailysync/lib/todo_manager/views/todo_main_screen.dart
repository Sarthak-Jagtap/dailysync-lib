// lib/todo_manager/views/todo_main_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:intl/intl.dart';

import '../controllers/todo_controller.dart';
import '../models/task_model.dart';
import 'create_task_screen.dart';
import 'manage_category_screen.dart';

class TodoMainScreen extends StatefulWidget {
  const TodoMainScreen({super.key});

  @override
  State<TodoMainScreen> createState() => _TodoMainScreenState();
}

class _TodoMainScreenState extends State<TodoMainScreen> with TickerProviderStateMixin {
  late AnimationController _fabController;
  late Animation<double> _fabAnimation;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300), // Faster animation
    )..forward();
    _fabAnimation = CurvedAnimation(parent: _fabController, curve: Curves.easeOut); // Smoother curve

    // Initial data fetch is handled by the Controller's constructor
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  // --- Widgets ---

  Widget _buildTaskCard(Task task, int index, TodoController controller) {
    final isCompleted = task.isCompleted;
    // Determine color based on priority
     Color priorityColor = Colors.grey; // Default
    switch (task.priority) {
      case 1: priorityColor = Colors.green; break; // Low
      case 2: priorityColor = Colors.blue; break; // Medium
      case 3: priorityColor = Colors.orange; break; // Normal
      case 4: priorityColor = Colors.red; break; // High
      case 5: priorityColor = Colors.purple; break; // Urgent
    }


    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push<dynamic>( // Expect dynamic result
          context,
          MaterialPageRoute(
            builder: (context) => CreateTaskScreen(
              existingTask: task, // Pass the Task object
              categories: controller.categories,
            ),
          ),
        );

        if (result == null) return;

        if (result == "delete" && task.id != null) {
          controller.deleteTask(task.id!);
        } else if (result is Task) { // Check if the result is a Task object
           controller.updateTask(result);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
         decoration: BoxDecoration(
          // Use task color slightly desaturated, or fallback
          color: task.color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(color: priorityColor, width: 5), // Priority indicator
          ),
           boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04), // Softer shadow
              blurRadius: 4,
              offset: const Offset(1, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              task.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17, // Slightly smaller
                color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(isCompleted ? 0.5 : 1.0),
                decoration: isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                decorationColor: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.7),
              ),
               maxLines: 2, // Allow title wrapping
              overflow: TextOverflow.ellipsis,
            ),
            if (task.description != null && task.description!.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                task.description!,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(isCompleted ? 0.5 : 0.8),
                  decoration: isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                   decorationColor: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                ),
                maxLines: 3, // Limit description lines
                overflow: TextOverflow.ellipsis, // Add ellipsis for overflow
                softWrap: true,
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end, // Align items at the bottom
              children: [
                 Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     // Show Category Chip
                    Chip(
                      label: Text(task.category),
                      padding: EdgeInsets.zero,
                      labelStyle: TextStyle(fontSize: 10, color: Theme.of(context).chipTheme.labelStyle?.color),
                      backgroundColor: Theme.of(context).chipTheme.backgroundColor,
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      side: BorderSide.none,
                    ),
                     const SizedBox(height: 4),
                    Text(
                      task.date, // Assuming date is already formatted
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                        decoration: isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                         decorationColor: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),

                // Checkbox aligned to the right, slightly smaller
                 Transform.scale(
                   scale: 0.9,
                   child: Checkbox(
                    value: isCompleted,
                    onChanged: (val) {
                       if (task.id != null) {
                        controller.toggleTaskCompletion(task);
                      }
                    },
                     visualDensity: VisualDensity.compact, // Make checkbox smaller
                     side: BorderSide(color: Theme.of(context).unselectedWidgetColor), // Subtle border
                                     ),
                 ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String name, bool isSelected, TodoController controller) {
    return GestureDetector(
      onTap: () => controller.selectCategory(name),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), // Adjusted padding
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).chipTheme.backgroundColor,
          borderRadius: BorderRadius.circular(18), // More rounded
          border: isSelected
              ? Border.all(color: Theme.of(context).colorScheme.primaryContainer, width: 1.5)
              : Border.all(color: Colors.transparent), // No border when not selected
        ),
        child: Text(
          name,
          style: TextStyle(
            fontSize: 14, // Slightly smaller font
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).chipTheme.labelStyle?.color,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Adjust grid count based on screen width for better responsiveness
    final crossAxisCount = (screenWidth / 250).floor().clamp(1, 4); // Min 1, Max 4 columns, aiming for ~250px width

    // Use Consumer for reactive UI updates
    return Consumer<TodoController>(
      builder: (context, controller, child) {
        return Scaffold(
         backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Use theme background
          // AppBar can be added here if this screen is navigated to directly
          // appBar: AppBar(title: const Text("To-Do Manager")),
          body: Padding(
            padding: const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0), // Adjust top padding
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, // Align headers to the left
              children: [
                 // --- Category Section ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                     Text(
                      "Categories",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold), // Use theme text style
                    ),
                     IconButton(
                      icon: Icon(Icons.grid_view_rounded, color: Theme.of(context).hintColor), // Use theme hint color
                      tooltip: "Manage Categories", // Add tooltip
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            // Pass controller to manage categories directly
                            builder: (context) => ManageCategoryScreen(),
                          ),
                        );
                        // Refresh happens within the controller now
                      },
                      splashRadius: 20, // Smaller splash radius
                    ),
                  ],
                ),
                const SizedBox(height: 8), // Reduced space
                 SizedBox(
                  height: 40, // Fixed height for category list
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: controller.categories.length,
                    itemBuilder: (context, index) {
                      final category = controller.categories[index];
                      return _buildCategoryChip(
                        category,
                        category == controller.selectedCategory,
                        controller,
                      );
                    },
                     separatorBuilder: (context, index) => const SizedBox(width: 8), // Consistent spacing
                    padding: const EdgeInsets.only(bottom: 4), // Add padding below chips
                  ),
                ),

                const SizedBox(height: 16), // Reduced space

                 // --- Tasks Section ---
                 Text(
                   "Tasks (${controller.filteredTasks.where((t) => !t.isCompleted).length} pending)", // Show pending count
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                 const SizedBox(height: 8),

                Expanded(
                  child: controller.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : controller.filteredTasks.isEmpty
                          ? Center(
                              child: Text(
                                controller.selectedCategory == "All"
                                    ? "No tasks yet!\nTap '+' to add one."
                                    : "No tasks in this category.",
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 16, color: Theme.of(context).hintColor),
                              ),
                            )
                          : AnimationLimiter(
                              child: MasonryGridView.count(
                                crossAxisCount: crossAxisCount,
                                mainAxisSpacing: 10, // Reduced spacing
                                crossAxisSpacing: 10,
                                padding: const EdgeInsets.only(bottom: 80, top: 8), // Padding for FAB and top spacing
                                itemCount: controller.filteredTasks.length,
                                itemBuilder: (context, index) {
                                  final task = controller.filteredTasks[index];
                                  return AnimationConfiguration.staggeredGrid(
                                    position: index,
                                    duration: const Duration(milliseconds: 375),
                                    columnCount: crossAxisCount,
                                    child: ScaleAnimation(
                                      child: FadeInAnimation(
                                        child: _buildTaskCard(task, index, controller),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                ),
              ],
            ),
          ),
          floatingActionButton: ScaleTransition( // Use ScaleTransition for FAB animation
             scale: _fabAnimation,
            child: FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.push<dynamic>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateTaskScreen(
                      // Pass current categories for the dropdown
                      categories: controller.categories,
                       // Pass selected category as default for new task
                      selectedCategory: controller.selectedCategory != "All" ? controller.selectedCategory : null,
                    ),
                  ),
                );

                if (result != null && result is Task) {
                  controller.addTask(result);
                }
              },
               tooltip: 'Add Task', // Add tooltip
               child: const Icon(Icons.add),
            ),
          ),
        );
      },
    );
  }
}