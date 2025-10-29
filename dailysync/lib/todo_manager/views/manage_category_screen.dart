// lib/todo_manager/views/manage_category_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/todo_controller.dart'; // Import the controller

class ManageCategoryScreen extends StatefulWidget {
  // Removed constructor arguments, will use Provider
  const ManageCategoryScreen({super.key});

  @override
  State<ManageCategoryScreen> createState() => _ManageCategoryScreenState();
}

class _ManageCategoryScreenState extends State<ManageCategoryScreen> {
  final TextEditingController _categoryController = TextEditingController();
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  // Get categories directly from the controller via initState or build
  late List<String> _manageableCategories; // Local list for animation

   @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize local list based on controller state, excluding "All"
    final controller = Provider.of<TodoController>(context, listen: false);
     _manageableCategories = List.from(controller.categories.where((cat) => cat != "All"));
  }

  Future<void> _addCategory(TodoController controller) async {
    final name = _categoryController.text.trim();
    if (name.isEmpty) return;

    // Use controller's method to add, which handles duplicates and refreshes
    await controller.addCategory(name);

    // Update local list for animation AFTER controller confirms addition (implicitly via refreshData)
    // We compare controller's list with local list to find the new item
     final newControllerCats = controller.categories.where((c) => c != "All").toList();
    if (newControllerCats.length > _manageableCategories.length) {
      // Find the newly added category (assuming only one was added)
      final newCat = newControllerCats.firstWhere((c) => !_manageableCategories.contains(c));
       final insertIndex = newControllerCats.indexOf(newCat); // Index in the updated list (excluding "All")
      _manageableCategories.insert(insertIndex, newCat);
      _listKey.currentState?.insertItem(insertIndex, duration: const Duration(milliseconds: 300));
    } else {
       // Show feedback if category already exists (controller handles the logic)
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Category '$name' might already exist.")),
      );
    }

    _categoryController.clear();
  }


   void _deleteCategory(TodoController controller, String name, int index) async {
    // 1. Remove from local list and animate UI removal immediately
    final item = _manageableCategories.removeAt(index);
    _listKey.currentState?.removeItem(
      index,
      (context, animation) => _buildCategoryItem(item, index, animation, isDeleting: true),
      duration: const Duration(milliseconds: 300),
    );

    // 2. Call controller to delete from DB and update its state
     await controller.deleteCategory(name); // Controller handles DB and task migration

    // 3. Show confirmation message
    if (mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Deleted '$name'. Tasks moved to 'All'.")),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    // Get the controller instance
    final todoController = Provider.of<TodoController>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Categories'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Input field
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _categoryController,
                    decoration: const InputDecoration(
                      labelText: 'New category name',
                      border: OutlineInputBorder(),
                       hintText: 'e.g., Shopping, Health',
                    ),
                     textCapitalization: TextCapitalization.words,
                    onSubmitted: (_) => _addCategory(todoController), // Pass controller
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filled( // Use filled button for primary action
                  icon: const Icon(Icons.add),
                  tooltip: "Add Category",
                  onPressed: () => _addCategory(todoController), // Pass controller
                  style: IconButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // List of categories
            Expanded(
              child: todoController.isLoading // Check controller's loading state
                  ? const Center(child: CircularProgressIndicator())
                  : _manageableCategories.isEmpty
                      ? const Center(child: Text("No custom categories yet."))
                      : AnimatedList(
                          key: _listKey,
                          initialItemCount: _manageableCategories.length,
                          itemBuilder: (context, index, animation) {
                            // Ensure index is within bounds after potential deletions
                             if (index >= _manageableCategories.length) {
                              return const SizedBox.shrink(); // Or handle appropriately
                            }
                            final category = _manageableCategories[index];
                            return _buildCategoryItem(category, index, animation);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // Animation helper widget (Modified to use controller for delete)
  Widget _buildCategoryItem(String category, int index, Animation<double> animation, {bool isDeleting = false}) {
     // Get controller but don't listen here to avoid rebuilds during animation
    final todoController = Provider.of<TodoController>(context, listen: false);

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: isDeleting ? Offset.zero : const Offset(0.3, 0), // Slide in from right
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)), // Use easeOut curve
        child: Card(
          elevation: 1, // Add subtle elevation
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0), // Adjust margin
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), // Rounded corners
          child: ListTile(
            title: Text(category),
             trailing: IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.red[600]), // Slightly darker red
              tooltip: "Delete Category",
              onPressed: () => _deleteCategory(todoController, category, index), // Pass controller
              splashRadius: 20, // Smaller splash radius
            ),
             contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0), // Adjust padding
          ),
        ),
      ),
    );
  }

   @override
  void dispose() {
    _categoryController.dispose();
    super.dispose();
  }
}