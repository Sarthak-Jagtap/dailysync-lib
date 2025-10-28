import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart'; 
import 'create_task.dart';
import 'package:dailysync/controllers/manage_category.dart';
import 'package:dailysync/controllers/database_helper.dart';

class TodoMain extends StatefulWidget {
  const TodoMain({super.key});

  @override
  State<TodoMain> createState() => _TodoMainState();
}

class _TodoMainState extends State<TodoMain> with TickerProviderStateMixin {
  List<String> categories = ["All"];
  int categorySelectedIndex = 0;
  bool _isLoading = true;

  List<Map<String, dynamic>> tasks = [];
  final dbHelper = DatabaseHelper.instance;

  late AnimationController _fabController;
  late Animation<double> _fabAnimation;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _fabAnimation = CurvedAnimation(parent: _fabController, curve: Curves.easeIn);

    _refreshData();
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    
    final categoryData = await dbHelper.getCategories();
    final taskData = await dbHelper.getTasks();
    
    setState(() {
      categories = categoryData;
      tasks = taskData;
      _isLoading = false;

      if (categorySelectedIndex >= categories.length) {
         categorySelectedIndex = 0;
      }
    });
  }

  Future<void> _addTask(Map<String, dynamic> newTask) async {
    await dbHelper.insertTask(newTask);
    _refreshData();
  }

  Future<void> _updateTask(Map<String, dynamic> task) async {
    await dbHelper.updateTask(task);
    _refreshData();
  }

  Future<void> _deleteTask(int id) async {
    await dbHelper.deleteTask(id);
    _refreshData();
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  // 🟨 Sticky note task card widget - FIXED VERSION
  Widget taskCard(Map<String, dynamic> task, int index) {
    final taskId = task['id'];
    final isCompleted = task["completed"] == 1;
    
    return GestureDetector(
      onTap: () async {
        // Create a safe copy for editing
        final taskCopy = Map<String, dynamic>.from(task);
        
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CreateTask(
              existingTask: taskCopy,
              index: index,
              categories: categories,
            ),
          ),
        );

        if (result == null) return;

        if (result == "delete") {
          _deleteTask(taskId);
        } else if (result is Map<String, dynamic>) {
          result['id'] = taskId;
          _updateTask(result);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Color(task["color"] ?? Colors.amber.shade100.value),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(2, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, 
          children: [
            Text(
              task["title"] ?? "Untitled",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black87,
                decoration: isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
              ),
            ),
            const SizedBox(height: 8),

            if ((task["description"] ?? "").toString().trim().isNotEmpty)
              Text(
                task["description"] ?? "",
                style: TextStyle(
                  fontSize: 14, 
                  color: Colors.black87,
                  decoration: isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                ),
                softWrap: true,
              ),

            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  task["date"] ?? "",
                  style: TextStyle(
                    fontSize: 12, 
                    color: Colors.grey.shade700,
                    decoration: isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                  ),
                ),
                Checkbox(
                  value: isCompleted,
                  onChanged: (val) async {
                    try {
                      // Create a completely new task object
                      final updatedTask = {
                        'id': taskId,
                        'title': task["title"],
                        'description': task["description"],
                        'completed': val! ? 1 : 0,
                        'date': task["date"],
                        'category': task["category"],
                        'color': task["color"],
                        'priority': task["priority"] ?? 3,
                      };
                      
                      // Update UI immediately
                      setState(() {
                        tasks = tasks.map((t) => t['id'] == taskId ? updatedTask : t).toList();
                      });
                      
                      // Persist to database
                      await _updateTask(updatedTask);
                      
                    } catch (e) {
                      print('Error updating task completion: $e');
                      // Revert UI if there's an error
                      _refreshData();
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 🟩 Category Card
  Widget categoryCard(String name, int index) {
    bool isSelected = index == categorySelectedIndex;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          categorySelectedIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 35,
        width: 80,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(15),
          border: isSelected ? Border.all(color: Colors.blue.shade700, width: 2) : null,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            name,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 700 ? 3 : 2;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Category",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.grey.shade800,
                ),
              ),
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (int i = 0; i < categories.length; i++) ...[
                          categoryCard(categories[i], i),
                          const SizedBox(width: 10),
                        ],
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.dashboard_customize_rounded),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ManageCategory(),
                      ),
                    );
                    _refreshData();
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),
            
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "My Tasks",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.grey.shade800,
                ),
              ),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Builder(
                      builder: (context) {
                        final filteredTasks = categorySelectedIndex == 0
                            ? tasks
                            : tasks
                                .where((task) =>
                                    task["category"] ==
                                    categories[categorySelectedIndex])
                                .toList();

                        if (filteredTasks.isEmpty) {
                          return const Center(
                            child: Text(
                              "No tasks yet",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                          );
                        }

                        return AnimationLimiter(
                          child: MasonryGridView.count(
                            crossAxisCount: crossAxisCount,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                            itemCount: filteredTasks.length,
                            itemBuilder: (context, index) {
                              return AnimationConfiguration.staggeredGrid(
                                position: index,
                                duration: const Duration(milliseconds: 375),
                                columnCount: crossAxisCount,
                                child: ScaleAnimation(
                                  child: FadeInAnimation(
                                    child: taskCard(filteredTasks[index], index),
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),

      floatingActionButton: AnimatedBuilder(
        animation: _fabAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _fabAnimation.value,
            child: FloatingActionButton(
              onPressed: () async {
                final newTask = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateTask(
                      categories: categories,
                    ),
                  ),
                );

                if (newTask != null && newTask is Map<String, dynamic>) {
                  _addTask(newTask);
                }
              },
              child: const Icon(Icons.add),
            ),
          );
        },
      ),
    );
  }
}