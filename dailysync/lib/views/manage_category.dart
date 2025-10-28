import 'package:flutter/material.dart';

class ManageCategory extends StatefulWidget {
  final List<String> categories;
  final Function(List<String>) onUpdateCategories;

  const ManageCategory({
    super.key,
    required this.categories,
    required this.onUpdateCategories,
  });

  @override
  State<ManageCategory> createState() => _ManageCategoryState();
}

class _ManageCategoryState extends State<ManageCategory> {
  late List<String> _localCategories;

  @override
  void initState() {
    super.initState();
    _localCategories = List.from(widget.categories);
  }

  void _showAddCategoryBottomSheet({String? existingCategory, int? index}) {
    TextEditingController controller = TextEditingController(
      text: existingCategory ?? '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                existingCategory == null ? "Add New Category" : "Edit Category",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: "Enter Category",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  String newCategory = controller.text.trim();
                  if (newCategory.isNotEmpty) {
                    setState(() {
                      if (existingCategory == null) {
                        _localCategories.add(newCategory);
                      } else {
                        _localCategories[index!] = newCategory;
                      }
                    });
                    widget.onUpdateCategories(_localCategories);
                    Navigator.pop(context);
                  }
                },
                child: Text(existingCategory == null ? "Add" : "Save"),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // void _deleteCategory(int index) {
  //   setState(() {
  //     _localCategories.removeAt(index);
  //   });
  //   widget.onUpdateCategories(_localCategories);
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Manage Category",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _localCategories.isEmpty
          ? const Center(
              child: Text(
                "No categories yet",
                style: TextStyle(fontSize: 16),
              ),
            )
          : ListView.builder(
              itemCount: _localCategories.length,
              itemBuilder: (context, index) {
                final category = _localCategories[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(category),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showAddCategoryBottomSheet(
                            existingCategory: category,
                            index: index,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.blue),
                          onPressed: () {
  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Remove Category?",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Notes under this category will be moved to 'All'.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Cancel Button
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // close popup
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey.shade800,
                    ),
                    child: const Text("Cancel"),
                  ),

                  // Remove Button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context); // close popup first

                      setState(() {
                        _localCategories.removeAt(index); // ✅ remove locally
                      });

                      // ✅ update categories in main screen
                      widget.onUpdateCategories(_localCategories);
                    },
                    child: const Text("Remove"),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
},

                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCategoryBottomSheet(),
        label: const Text("Add Category"),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
