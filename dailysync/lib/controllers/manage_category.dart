// manage_category.dart
import 'package:flutter/material.dart';
import 'database_helper.dart'; // Import the helper

class ManageCategory extends StatefulWidget {
  // ✅ This constructor matches the one in todo_main.dart (no arguments)
  const ManageCategory({super.key});

  @override
  State<ManageCategory> createState() => _ManageCategoryState();
}

class _ManageCategoryState extends State<ManageCategory> {
  final dbHelper = DatabaseHelper.instance;
  final TextEditingController _categoryController = TextEditingController();
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  
  List<String> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshCategories();
  }

  Future<void> _refreshCategories() async {
    setState(() => _isLoading = true);
    // 1. Get categories from the database
    final cats = await dbHelper.getCategories(); 
    
    // 2. We don't want "All" to be manageable
    cats.remove("All");
    _categories = cats;
    setState(() => _isLoading = false);
  }

  Future<void> _addCategory() async {
    final name = _categoryController.text.trim();
    if (name.isEmpty) return;
    
    if (_categories.any((cat) => cat.toLowerCase() == name.toLowerCase())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Category '$name' already exists.")),
      );
      return;
    }

    // 3. Insert new category into the database
    final id = await dbHelper.insertCategory(name);
    
    if (id != -1) {
      // Add to local list and animate
      final insertIndex = _categories.length;
      _categories.add(name);
      _listKey.currentState?.insertItem(insertIndex, duration: const Duration(milliseconds: 300));
      _categoryController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Category '$name' already exists.")),
      );
    }
  }

  void _deleteCategory(String name, int index) async {
    // 1. Animate removal from list
    final item = _categories.removeAt(index);
    _listKey.currentState?.removeItem(
      index,
      (context, animation) => _buildCategoryItem(item, index, animation, isDeleting: true),
      duration: const Duration(milliseconds: 300),
    );
    
    // 4. Delete from the database
    await dbHelper.deleteCategory(name);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Deleted '$name'. Tasks moved to 'All'.")),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                    ),
                    onSubmitted: (_) => _addCategory(),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filled(
                  icon: const Icon(Icons.add),
                  onPressed: _addCategory,
                  style: IconButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // List of categories
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _categories.isEmpty 
                      ? const Center(child: Text("No custom categories yet."))
                      : AnimatedList(
                          key: _listKey,
                          initialItemCount: _categories.length,
                          itemBuilder: (context, index, animation) {
                            final category = _categories[index];
                            return _buildCategoryItem(category, index, animation);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // Animation helper widget
  Widget _buildCategoryItem(String category, int index, Animation<double> animation, {bool isDeleting = false}) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: isDeleting ? Offset.zero : const Offset(0.3, 0),
          end: Offset.zero,
        ).animate(animation),
        child: Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            title: Text(category),
            trailing: IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.red[700]),
              onPressed: () => _deleteCategory(category, index),
            ),
          ),
        ),
      ),
    );
  }
}