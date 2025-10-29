// lib/todo_manager/views/create_task_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart'; // Import Provider
import '../models/task_model.dart';
import '../controllers/todo_controller.dart'; // Import Controller


class CreateTaskScreen extends StatefulWidget {
  final Task? existingTask; // Use Task model
   final List<String> categories; // Categories passed from main screen
  final String? selectedCategory; // Optional pre-selected category

  const CreateTaskScreen({
    super.key,
    this.existingTask,
    required this.categories,
    this.selectedCategory, // Accept pre-selected category
  });


  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>(); // Add a Form key
  late TextEditingController _titleController;
  late TextEditingController _descController;
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _descFocusNode = FocusNode();


  String? _selectedCategory;
  double _currentSliderValue = 3.0; // Default priority: Normal
   Color _selectedColor = Colors.blue; // Default color
  late bool _isEditing;
  late List<String> _availableCategories; // Use local mutable list


  @override
  void initState() {
    super.initState();
    _isEditing = widget.existingTask != null;

    _titleController = TextEditingController(text: widget.existingTask?.title ?? '');
    _descController = TextEditingController(text: widget.existingTask?.description ?? '');
     _selectedColor = widget.existingTask?.color ?? Colors.blue;
    _currentSliderValue = (widget.existingTask?.priority ?? 3).toDouble();

    // Initialize categories carefully
     _availableCategories = List.from(widget.categories.where((cat) => cat != "All")); // Exclude "All"

    if (_isEditing) {
      _selectedCategory = widget.existingTask!.category;
       // Ensure the existing category is in the list, add if missing (edge case)
      if (!_availableCategories.contains(_selectedCategory) && _selectedCategory != "All") {
        _availableCategories.add(_selectedCategory!);
      }
    } else {
       // Use pre-selected category if provided and valid, otherwise default
      if (widget.selectedCategory != null && _availableCategories.contains(widget.selectedCategory)) {
        _selectedCategory = widget.selectedCategory;
      } else if (_availableCategories.isNotEmpty) {
        _selectedCategory = _availableCategories.first; // Default to first available category
      } else {
         _selectedCategory = null; // No categories available
      }
    }


    _titleFocusNode.addListener(_onTitleFocusChange);
  }

  void _onTitleFocusChange() {
    // Optionally trigger UI changes on focus, like expanding description
  }

  void _saveTask() {
      if (_formKey.currentState!.validate()) { // Validate the form
      HapticFeedback.lightImpact();

       final now = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()); // Or use existing date if editing? Decide logic.
      final editedDate = widget.existingTask?.date ?? now;


        final task = Task(
        id: widget.existingTask?.id, // Keep ID if editing
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        // Keep existing completed status if editing, else false
        isCompleted: widget.existingTask?.isCompleted ?? false,
        date: editedDate, // Use appropriate date
        category: _selectedCategory!, // Already validated
        color: _selectedColor, // Use selected color
        priority: _currentSliderValue.round(),
      );


      Navigator.pop(context, task); // Return the Task object
    }
  }


  void _deleteTask() {
    if (!_isEditing) return; // Should not happen, but safeguard

    HapticFeedback.heavyImpact();

    showDialog(
      context: context,
      builder: (context) => _buildDeleteConfirmationDialog(),
    ).then((confirmed) {
       if (confirmed == true) {
         Navigator.pop(context, "delete"); // Return "delete" string
       }
     });
  }


   Widget _buildDeleteConfirmationDialog() {
    return AlertDialog( // Use standard AlertDialog for consistency
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text("Delete Task?"),
      content: const Text("This action cannot be undone."),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false), // Return false on cancel
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true), // Return true on confirm
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text("Delete", style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }


  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
         backgroundColor: isError ? Colors.redAccent : Colors.green, // Use color to indicate status
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }


   Color _getPriorityColor(double value) {
    switch (value.round()) {
      case 1: return Colors.green;
      case 2: return Colors.blue;
      case 3: return Colors.orange;
      case 4: return Colors.red;
      case 5: return Colors.purple;
      default: return Colors.grey;
    }
  }

  String _getPriorityText(double value) {
    switch (value.round()) {
      case 1: return "Low";
      case 2: return "Medium";
      case 3: return "Normal";
      case 4: return "High";
      case 5: return "Urgent";
      default: return "Unknown";
    }
  }


  // --- Color Picker ---
   void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) {
        Color tempColor = _selectedColor;
        return AlertDialog(
          title: const Text('Select Task Color'),
          content: SingleChildScrollView(
            // Use a simple grid of predefined colors
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: Colors.primaries.map((color) {
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedColor = color.shade200); // Use a lighter shade
                    Navigator.of(context).pop();
                  },
                  child: CircleAvatar(
                    backgroundColor: color.shade200,
                    radius: 20,
                     child: _selectedColor == color.shade200
                        ? const Icon(Icons.check, color: Colors.black54)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ),
           actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    // Access theme for better UI consistency
     final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;


    return Scaffold(
       backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor, // Use theme AppBar color
        elevation: 0,
        foregroundColor: theme.appBarTheme.foregroundColor ?? (isDark ? Colors.white : Colors.black),
        title: Text(
          _isEditing ? "Edit Task" : "Create New Task",
          // style: theme.appBarTheme.titleTextStyle, // Use theme title style
        ),
        actions: [
           // Color Picker Button
          IconButton(
            icon: Icon(Icons.color_lens_outlined, color: _selectedColor),
            tooltip: "Change Color",
            onPressed: _showColorPicker,
          ),
          if (_isEditing)
            IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
              tooltip: "Delete Task", // Add tooltip
              onPressed: _deleteTask,
            ),
          IconButton(
            icon: Icon(Icons.check, color: theme.colorScheme.primary), // Use primary theme color
             tooltip: _isEditing ? "Update Task" : "Save Task",
            onPressed: _saveTask,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          // Wrap content in a Form
          child: Form(
             key: _formKey,
            child: ListView( // Use ListView for scrollability if content overflows
              children: [
                // --- Title ---
                TextFormField(
                  controller: _titleController,
                  focusNode: _titleFocusNode,
                  decoration: InputDecoration(
                    hintText: "Task Title",
                    hintStyle: TextStyle(color: theme.hintColor, fontSize: 22), // Use theme hint color
                    border: InputBorder.none, // Cleaner look
                     enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                     errorBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.red.shade400)),
                    focusedErrorBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.red)),
                  ),
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold), // Use theme headline style
                  maxLines: null, // Allow multiple lines
                   textCapitalization: TextCapitalization.sentences, // Capitalize sentences
                  validator: (value) { // Add validation
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a task title';
                    }
                    return null;
                  },
                ),
                 const SizedBox(height: 16),


                // --- Category Dropdown ---
                 DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  icon: const Icon(Icons.arrow_drop_down_rounded),
                   style: theme.textTheme.bodyLarge,
                  items: _availableCategories.isEmpty
                    ? [const DropdownMenuItem(value: null, child: Text("No categories available"))] // Handle empty case
                    : _availableCategories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                  onChanged: _availableCategories.isEmpty ? null : (value) { // Disable if no categories
                    setState(() => _selectedCategory = value);
                  },
                   validator: (value) { // Add validation
                    if (value == null || value.isEmpty) {
                      return 'Please select a category';
                    }
                    return null;
                  },
                ),
                 const SizedBox(height: 16),


               // --- Priority Slider ---
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                   decoration: BoxDecoration(
                    color: theme.cardColor, // Use theme card color
                    borderRadius: BorderRadius.circular(12),
                     border: Border.all(color: theme.dividerColor), // Use theme divider color for border
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.flag_outlined, color: _getPriorityColor(_currentSliderValue), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            "Priority: ${_getPriorityText(_currentSliderValue)}",
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      Slider(
                        value: _currentSliderValue,
                        min: 1,
                        max: 5,
                        divisions: 4,
                        activeColor: _getPriorityColor(_currentSliderValue),
                        inactiveColor: theme.disabledColor,
                        label: _getPriorityText(_currentSliderValue), // Show label on interaction
                        onChanged: (value) => setState(() => _currentSliderValue = value),
                      ),
                       Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Low", style: theme.textTheme.bodySmall),
                          Text("Urgent", style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ],
                  ),
                ),
                 const SizedBox(height: 16),


                // --- Description ---
                TextFormField(
                  controller: _descController,
                  focusNode: _descFocusNode,
                  decoration: InputDecoration(
                    hintText: "Add description or notes...",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), // Consistent border
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  maxLines: 5, // Set a reasonable max lines
                  minLines: 3, // Set a minimum lines
                   style: theme.textTheme.bodyLarge,
                   textCapitalization: TextCapitalization.sentences,
                ),


                // Add more fields if needed (e.g., due date picker)
                 const SizedBox(height: 80), // Space for potential FAB


              ],
            ),
          ),
        ),
      ),
       // Consider adding a FAB for saving as well, especially on smaller screens
      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: _saveTask,
      //   label: Text(_isEditing ? "UPDATE TASK" : "CREATE TASK"),
      //   icon: const Icon(Icons.check),
      // ),
    );
  }

  @override
  void dispose() {
    _titleFocusNode.removeListener(_onTitleFocusChange);
    _titleFocusNode.dispose();
    _descFocusNode.dispose();
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }
}