// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:flutter/services.dart';

// class CreateTask extends StatefulWidget {
//   final Map<String, dynamic>? existingTask;
//   final int? index;
//   final List<String> categories;

//   const CreateTask({
//     super.key,
//     this.existingTask,
//     this.index,
//     required this.categories,
//   });

//   @override
//   State<CreateTask> createState() => _CreateTaskState();
// }

// class _CreateTaskState extends State<CreateTask> {
//   final TextEditingController _titleController = TextEditingController();
//   final TextEditingController _descController = TextEditingController();
//   final FocusNode _titleFocusNode = FocusNode();
//   final FocusNode _descFocusNode = FocusNode();

//   String? _selectedCategory;
//   double _currentSliderValue = 3.0;
//   bool _isExpanded = false;
//   late List<String> _availableCategories;

//   @override
//   void initState() {
//     super.initState();
//     _initializeData();
//     _titleFocusNode.addListener(_onTitleFocusChange);
//   }

//   void _initializeData() {
//     // Fix: Create a mutable copy of categories to avoid read-only issues
//     _availableCategories = List<String>.from(widget.categories)
//       ..removeWhere((cat) => cat == "All");
    
//     if (widget.existingTask != null) {
//       _titleController.text = widget.existingTask!["title"];
//       _descController.text = widget.existingTask!["description"];
//       _selectedCategory = widget.existingTask!["category"];
//       _currentSliderValue = (widget.existingTask!["priority"] ?? 3.0).toDouble();
//     } else {
//       _selectedCategory = _availableCategories.isNotEmpty 
//           ? _availableCategories.first 
//           : "Personal";
//     }
//   }

//   void _onTitleFocusChange() {
//     if (_titleFocusNode.hasFocus && !_isExpanded) {
//       setState(() {
//         _isExpanded = true;
//       });
//     }
//   }

//   void _saveTask() {
//     if (_titleController.text.trim().isEmpty) {
//       _showSnackBar("Please enter a task title", Icons.warning_amber_rounded);
//       return;
//     }

//     if (_selectedCategory == null || _selectedCategory!.isEmpty) {
//       _showSnackBar("Please select a category", Icons.category_rounded);
//       return;
//     }

//     HapticFeedback.lightImpact();
    
//     final String now = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
//     final Map<String, dynamic> newTask = {
//       "title": _titleController.text.trim(),
//       "description": _descController.text.trim(),
//       "completed": widget.existingTask?["completed"] ?? 0,
//       "date": now,
//       "category": _selectedCategory,
//       "color": Colors.blue.value,
//       "priority": _currentSliderValue.round(),
//     };

//     Navigator.pop(context, newTask);
//   }

//   void _deleteTask() {
//     HapticFeedback.heavyImpact();
    
//     showDialog(
//       context: context,
//       builder: (context) => _buildDeleteConfirmationDialog(),
//     );
//   }

//   Widget _buildDeleteConfirmationDialog() {
//     return Dialog(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       child: Padding(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(
//               Icons.delete_outline_rounded,
//               color: Colors.red.shade500,
//               size: 48,
//             ),
//             const SizedBox(height: 16),
//             const Text(
//               "Delete Task?",
//               style: TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               "This action cannot be undone",
//               style: TextStyle(
//                 color: Colors.grey.shade600,
//               ),
//             ),
//             const SizedBox(height: 24),
//             Row(
//               children: [
//                 Expanded(
//                   child: OutlinedButton(
//                     onPressed: () => Navigator.pop(context),
//                     style: OutlinedButton.styleFrom(
//                       padding: const EdgeInsets.symmetric(vertical: 12),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                     child: const Text("Cancel"),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: ElevatedButton(
//                     onPressed: () {
//                       Navigator.pop(context);
//                       Navigator.pop(context, "delete");
//                     },
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.red,
//                       padding: const EdgeInsets.symmetric(vertical: 12),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                     child: const Text(
//                       "Delete",
//                       style: TextStyle(color: Colors.white),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _showSnackBar(String message, IconData icon) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Row(
//           children: [
//             Icon(icon, color: Colors.white, size: 20),
//             const SizedBox(width: 8),
//             Text(message),
//           ],
//         ),
//         backgroundColor: Colors.grey.shade800,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isEditing = widget.existingTask != null;

//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         foregroundColor: Colors.black,
//         title: Text(
//           isEditing ? "Edit Task" : "Create New Task",
//           style: const TextStyle(
//             color: Colors.black,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//         actions: [
//           if (isEditing)
//             IconButton(
//               icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
//               onPressed: _deleteTask,
//             ),
//           IconButton(
//             icon: const Icon(Icons.check, color: Colors.blue),
//             onPressed: _saveTask,
//           ),
//         ],
//       ),
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(20.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               TextField(
//                 controller: _titleController,
//                 focusNode: _titleFocusNode,
//                 decoration: const InputDecoration(
//                   hintText: "Task Title",
//                   hintStyle: TextStyle(
//                     color: Colors.grey,
//                     fontSize: 20,
//                   ),
//                   border: InputBorder.none,
//                 ),
//                 style: const TextStyle(
//                   fontSize: 24,
//                   fontWeight: FontWeight.w700,
//                   color: Colors.black,
//                 ),
//                 maxLines: null,
//               ),
//               const SizedBox(height: 24),

//               Container(
//                 decoration: BoxDecoration(
//                   color: Colors.grey.shade50,
//                   borderRadius: BorderRadius.circular(12),
//                   border: Border.all(color: Colors.grey.shade200),
//                 ),
//                 child: DropdownButtonHideUnderline(
//                   child: DropdownButtonFormField<String>(
//                     value: _selectedCategory,
//                     decoration: const InputDecoration(
//                       contentPadding: EdgeInsets.symmetric(horizontal: 16),
//                       border: InputBorder.none,
//                     ),
//                     icon: const Icon(Icons.arrow_drop_down_rounded),
//                     style: const TextStyle(
//                       fontWeight: FontWeight.w500,
//                       color: Colors.black,
//                     ),
//                     items: _availableCategories
//                         .map((cat) => DropdownMenuItem(
//                               value: cat,
//                               child: Text(cat),
//                             ))
//                         .toList(),
//                     onChanged: (value) {
//                       setState(() {
//                         _selectedCategory = value;
//                       });
//                     },
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 20),

//               Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: Colors.grey.shade50,
//                   borderRadius: BorderRadius.circular(12),
//                   border: Border.all(color: Colors.grey.shade200),
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       children: [
//                         Icon(Icons.flag_rounded, 
//                             color: _getPriorityColor(), size: 20),
//                         const SizedBox(width: 8),
//                         Text(
//                           "Priority: ${_getPriorityText()}",
//                           style: const TextStyle(
//                             fontWeight: FontWeight.w600,
//                             color: Colors.black87,
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 12),
//                     Slider(
//                       value: _currentSliderValue,
//                       min: 1,
//                       max: 5,
//                       divisions: 4,
//                       activeColor: _getPriorityColor(),
//                       inactiveColor: Colors.grey.shade300,
//                       onChanged: (value) {
//                         setState(() {
//                           _currentSliderValue = value;
//                         });
//                       },
//                     ),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Text("Low", style: TextStyle(color: Colors.grey.shade600)),
//                         Text("High", style: TextStyle(color: Colors.grey.shade600)),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 20),

//               Expanded(
//                 child: Container(
//                   decoration: BoxDecoration(
//                     color: Colors.grey.shade50,
//                     borderRadius: BorderRadius.circular(12),
//                     border: Border.all(color: Colors.grey.shade200),
//                   ),
//                   child: TextField(
//                     controller: _descController,
//                     focusNode: _descFocusNode,
//                     decoration: const InputDecoration(
//                       hintText: "Add description, notes, or details...",
//                       border: InputBorder.none,
//                       contentPadding: EdgeInsets.all(16),
//                     ),
//                     maxLines: null,
//                     expands: true,
//                     style: const TextStyle(
//                       fontSize: 16,
//                       color: Colors.black87,
//                     ),
//                   ),
//                 ),
//               ),

//               if (_isExpanded) ..._buildAdvancedOptions(),
//             ],
//           ),
//         ),
//       ),
//       floatingActionButton: _isExpanded ? _buildFloatingActionButton() : null,
//     );
//   }

//   Color _getPriorityColor() {
//     switch (_currentSliderValue.round()) {
//       case 1: return Colors.green;
//       case 2: return Colors.blue;
//       case 3: return Colors.orange;
//       case 4: return Colors.red;
//       case 5: return Colors.purple;
//       default: return Colors.blue;
//     }
//   }

//   String _getPriorityText() {
//     switch (_currentSliderValue.round()) {
//       case 1: return "Low";
//       case 2: return "Medium";
//       case 3: return "Normal";
//       case 4: return "High";
//       case 5: return "Urgent";
//       default: return "Normal";
//     }
//   }

//   List<Widget> _buildAdvancedOptions() {
//     return [
//       const SizedBox(height: 20),
//     ];
//   }

//   Widget _buildFloatingActionButton() {
//     return FloatingActionButton.extended(
//       onPressed: _saveTask,
//       backgroundColor: Colors.blue,
//       foregroundColor: Colors.white,
//       elevation: 2,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16),
//       ),
//       icon: const Icon(Icons.check_rounded, size: 20),
//       label: Text(widget.existingTask != null ? "UPDATE TASK" : "CREATE TASK"),
//     );
//   }

//   @override
//   void dispose() {
//     _titleFocusNode.removeListener(_onTitleFocusChange);
//     _titleFocusNode.dispose();
//     _descFocusNode.dispose();
//     _titleController.dispose();
//     _descController.dispose();
//     super.dispose();
//   }
// }