// lib/routine_manager/views/edit_template_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/routine_controller.dart';
import '../models/routine_models.dart';

class EditTemplateScreen extends StatefulWidget {
  const EditTemplateScreen({super.key});

  @override
  State<EditTemplateScreen> createState() => _EditTemplateScreenState();
}

class _EditTemplateScreenState extends State<EditTemplateScreen> {
  List<RoutineTask> _templateTasks = [];
  bool _isLoading = true;
  bool _hasChanges = false; // Track if changes were made

  // Define the purple color scheme
  final Color _primaryColor = Colors.deepPurple;
  final Color _accentColor = Colors.purpleAccent;

  @override
  void initState() {
    super.initState();
    _loadTemplate();
  }

  Future<void> _loadTemplate() async {
    setState(() => _isLoading = true);
    final controller = Provider.of<RoutineController>(context, listen: false);
    _templateTasks = await controller.getMasterTemplate();
    // Sort just in case DB didn't order correctly
    _templateTasks.sort((a, b) => a.startTime.compareTo(b.startTime));
    setState(() => _isLoading = false);
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final RoutineTask item = _templateTasks.removeAt(oldIndex);
      _templateTasks.insert(newIndex, item);
      _hasChanges = true;
    });
  }

  Future<void> _editTask(int index) async {
    final RoutineTask? editedTask = await showDialog<RoutineTask>(
      context: context,
      builder: (context) => _EditTaskDialog(task: _templateTasks[index], primaryColor: _primaryColor),
    );
    if (editedTask != null) {
      setState(() {
        _templateTasks[index] = editedTask;
        _hasChanges = true;
      });
    }
  }

   Future<void> _addNewTask() async {
      final RoutineTask? newTask = await showDialog<RoutineTask>(
        context: context,
        builder: (context) => _EditTaskDialog(primaryColor: _primaryColor), // No initial task
      );
      if (newTask != null) {
        setState(() {
          _templateTasks.add(newTask);
          // Sort after adding
           _templateTasks.sort((a, b) => a.startTime.compareTo(b.startTime));
          _hasChanges = true;
        });
      }
   }

  void _deleteTask(int index) {
    setState(() {
      _templateTasks.removeAt(index);
      _hasChanges = true;
    });
  }

  Future<void> _saveChanges() async {
     if (!_hasChanges) {
       Navigator.pop(context); // No changes, just go back
       return;
     }
      setState(() => _isLoading = true);
      final controller = Provider.of<RoutineController>(context, listen: false);
      try {
        // Ensure tasks are sorted before saving
        _templateTasks.sort((a, b) => a.startTime.compareTo(b.startTime));
        await controller.updateMasterTemplate(_templateTasks);
        if (mounted) {
           Navigator.pop(context, true); // Indicate success
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: const Text('Routine updated successfully!'), backgroundColor: _primaryColor)
           );
        }
      } catch (e) {
         debugPrint("Error saving template: $e");
         if(mounted){
             ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(content: Text('Error saving routine: $e'), backgroundColor: Colors.red)
            );
             setState(() => _isLoading = false);
         }
      }
  }

  // Confirm discard changes
  Future<bool> _onWillPop() async {
    if (!_hasChanges) {
      return true; // Allow back navigation if no changes
    }
    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Changes?'),
        content: const Text('You have unsaved changes. Are you sure you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), // Don't discard
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true), // Discard
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return shouldDiscard ?? false; // Allow back if dialog dismissed or 'Discard' chosen
  }


  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Routine Template'),
          backgroundColor: _primaryColor, // Purple AppBar
          actions: [
            if (_isLoading)
               const Padding(
                 padding: EdgeInsets.only(right: 16.0),
                 child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2,))),
               )
             else
               IconButton(
                 icon: const Icon(Icons.save),
                 tooltip: 'Save Changes',
                 onPressed: _saveChanges,
               ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _templateTasks.isEmpty
                ? const Center(child: Text('No tasks in the template. Add one!'))
                : ReorderableListView.builder(
                    itemCount: _templateTasks.length,
                    itemBuilder: (context, index) {
                      final task = _templateTasks[index];
                      return Card(
                         key: ValueKey(task.id ?? index), // Use ID if available, otherwise index
                         margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                         child: ListTile(
                           leading: CircleAvatar(
                             backgroundColor: _primaryColor.withOpacity(0.1),
                             foregroundColor: _primaryColor,
                             child: Text('${index + 1}'), // Number the tasks
                           ),
                           title: Text(task.taskTitle),
                           subtitle: Text('${task.startTime} - ${task.endTime} (${task.category})'),
                           trailing: Row(
                             mainAxisSize: MainAxisSize.min,
                             children: [
                               IconButton(
                                 icon: Icon(Icons.edit_outlined, color: Colors.grey[600]),
                                 onPressed: () => _editTask(index),
                               ),
                               IconButton(
                                 icon: Icon(Icons.delete_outline, color: Colors.red[400]),
                                 onPressed: () => _deleteTask(index),
                               ),
                               // Reorder handle - implicit with ReorderableListView
                               // Icon(Icons.drag_handle, color: Colors.grey),
                             ],
                           ),
                         ),
                      );
                    },
                    onReorder: _onReorder,
                  ),
         floatingActionButton: FloatingActionButton.extended(
            onPressed: _addNewTask,
            icon: const Icon(Icons.add),
            label: const Text('Add Task'),
            backgroundColor: _accentColor, // Purple FAB
         ),
      ),
    );
  }
}


// --- Dialog for Adding/Editing a Task ---
class _EditTaskDialog extends StatefulWidget {
  final RoutineTask? task; // Null if adding new
  final Color primaryColor;

  const _EditTaskDialog({this.task, required this.primaryColor});

  @override
  _EditTaskDialogState createState() => _EditTaskDialogState();
}

class _EditTaskDialogState extends State<_EditTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late String _category;

  final List<String> _categories = ['Work', 'Health', 'Personal', 'Focus', 'Meal', 'Commute', 'Break', 'Other'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.taskTitle ?? '');
    _startTime = widget.task?.startTimeOfDay ?? TimeOfDay.now();
    _endTime = widget.task?.endTimeOfDay ?? TimeOfDay(hour: TimeOfDay.now().hour + 1, minute: TimeOfDay.now().minute);
    _category = widget.task?.category ?? _categories.first;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(bool isStart) async {
     final TimeOfDay initialTime = isStart ? _startTime : _endTime;
     final TimeOfDay? picked = await showTimePicker(
       context: context,
       initialTime: initialTime,
        builder: (context, child) { // Theme the picker
            return Theme(
              data: ThemeData.light().copyWith(
                 colorScheme: ColorScheme.light(primary: widget.primaryColor),
                 buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
              ),
              child: child!,
            );
          },
     );
     if (picked != null) {
       setState(() {
         if (isStart) {
           _startTime = picked;
           // Auto-adjust end time if it's before start time
           if ((_endTime.hour * 60 + _endTime.minute) <= (_startTime.hour * 60 + _startTime.minute)) {
              _endTime = TimeOfDay(hour: _startTime.hour + 1, minute: _startTime.minute); // Default to 1 hour later
           }
         } else {
            // Ensure end time is after start time
           if ((picked.hour * 60 + picked.minute) > (_startTime.hour * 60 + _startTime.minute)) {
              _endTime = picked;
           } else {
             // Show error or automatically adjust? Let's show snackbar for now.
             ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('End time must be after start time.'), backgroundColor: Colors.orange)
             );
           }
         }
       });
     }
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final editedTask = RoutineTask(
        id: widget.task?.id, // Preserve ID if editing
        taskTitle: _titleController.text.trim(),
        startTime: RoutineTask.formatTime(_startTime),
        endTime: RoutineTask.formatTime(_endTime),
        category: _category,
      );
      Navigator.pop(context, editedTask);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.task == null ? 'Add New Task' : 'Edit Task'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'Task Title', focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: widget.primaryColor))),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Text('Start: ${RoutineTask.formatTime(_startTime)}'),
                  OutlinedButton(onPressed: () => _selectTime(true), child: const Text('Select Time')),
                ],
              ),
               Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Text('End:   ${RoutineTask.formatTime(_endTime)}'),
                  OutlinedButton(onPressed: () => _selectTime(false), child: const Text('Select Time')),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: InputDecoration(labelText: 'Category', focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: widget.primaryColor))),
                items: _categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                onChanged: (value) => setState(() => _category = value!),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
           onPressed: _save,
           style: ElevatedButton.styleFrom(backgroundColor: widget.primaryColor),
           child: const Text('Save')
        ),
      ],
    );
  }
}
