// lib/routine_manager/views/schedule_setup_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/routine_controller.dart';
import '../models/routine_models.dart';
import 'schedule_review_screen.dart'; // Import review screen
import 'package:intl/intl.dart'; // For DateFormat if needed for display

class ScheduleSetupScreen extends StatefulWidget {
  const ScheduleSetupScreen({super.key});

  @override
  State<ScheduleSetupScreen> createState() => _ScheduleSetupScreenState();
}

class _ScheduleSetupScreenState extends State<ScheduleSetupScreen> {
  TimeOfDay _wakeUpTime = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _sleepTime = const TimeOfDay(hour: 22, minute: 30);
  final List<FixedTaskInput> _fixedTasks = [];
  final TextEditingController _goalsController = TextEditingController();
  final _formKey = GlobalKey<FormState>(); // For commitment title validation
  bool _isGenerating = false;

  // Define the purple color scheme
  final Color _primaryColor = Colors.deepPurple;
  final Color _accentColor = Colors.purpleAccent;
  // final Color _lightBgColor = Colors.deepPurple.shade50; // Use if needed

  // --- Methods for Time Picking ---
  Future<void> _selectTime(BuildContext context, bool isWakeUp) async {
    final TimeOfDay initialTime = isWakeUp ? _wakeUpTime : _sleepTime;
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
       builder: (context, child) { // Theme the picker
            return Theme(
              data: ThemeData.light().copyWith(
                 colorScheme: ColorScheme.light(primary: _primaryColor), // Purple header
                 buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
              ),
              child: child!,
            );
          },
    );
    if (picked != null && picked != initialTime) {
      setState(() {
        if (isWakeUp) {
          _wakeUpTime = picked;
        } else {
          _sleepTime = picked;
        }
      });
    }
  }

  // --- Methods for Fixed Commitments ---
  void _addCommitment() {
    setState(() {
      // Add a default commitment
      _fixedTasks.add(FixedTaskInput(
        title: '',
        startTime: const TimeOfDay(hour: 9, minute: 0),
        endTime: const TimeOfDay(hour: 17, minute: 0),
        tempId: DateTime.now().millisecondsSinceEpoch, // Unique temp ID
      ));
    });
  }

  void _removeCommitment(int tempId) {
    setState(() {
      _fixedTasks.removeWhere((task) => task.tempId == tempId);
    });
  }

  Future<void> _selectCommitmentTime(BuildContext context, int tempId, bool isStart) async {
      final taskIndex = _fixedTasks.indexWhere((t) => t.tempId == tempId);
      if (taskIndex == -1) return;

      final FixedTaskInput task = _fixedTasks[taskIndex];
      final TimeOfDay initialTime = isStart ? task.startTime : task.endTime;

      final TimeOfDay? picked = await showTimePicker(
        context: context,
        initialTime: initialTime,
         builder: (context, child) => Theme( // Theme the picker
              data: ThemeData.light().copyWith(
                 colorScheme: ColorScheme.light(primary: _primaryColor),
                 buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
              ), child: child!,
          ),
      );

      if (picked != null && picked != initialTime) {
          setState(() {
              if (isStart) {
                // Ensure start time is before end time
                if ((picked.hour * 60 + picked.minute) < (task.endTime.hour * 60 + task.endTime.minute)) {
                   _fixedTasks[taskIndex].startTime = picked;
                } else {
                  _showErrorSnackbar('Start time must be before end time.');
                }
              } else {
                 // Ensure end time is after start time
                 if ((picked.hour * 60 + picked.minute) > (task.startTime.hour * 60 + task.startTime.minute)) {
                   _fixedTasks[taskIndex].endTime = picked;
                 } else {
                   _showErrorSnackbar('End time must be after start time.');
                 }
              }
          });
      }
   }

  void _updateCommitmentTitle(int tempId, String title) {
     final taskIndex = _fixedTasks.indexWhere((t) => t.tempId == tempId);
     if (taskIndex != -1) {
        // No setState needed as TextEditingController handles UI update
        _fixedTasks[taskIndex].title = title.trim();
     }
  }


  // --- Generate Schedule Action ---
  Future<void> _generateSchedule() async {
    // Validate commitment titles
     bool allTitlesValid = true;
     for (var task in _fixedTasks) {
       if (task.title.trim().isEmpty) {
         allTitlesValid = false;
         break;
       }
     }
     if (!allTitlesValid) {
       _showErrorSnackbar('Please enter a title for all commitments.');
       return;
     }
     if (_goalsController.text.trim().isEmpty) {
        _showErrorSnackbar('Please describe your goals.');
        return;
     }

    setState(() => _isGenerating = true);
    final controller = Provider.of<RoutineController>(context, listen: false);

    try {
      final List<RoutineTask>? generatedTasks = await controller.generateScheduleFromInput(
        _fixedTasks,
        _wakeUpTime,
        _sleepTime,
        _goalsController.text.trim(),
      );

      if (mounted && generatedTasks != null && generatedTasks.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ScheduleReviewScreen(
                  generatedTasks: generatedTasks,
                  // Pass colors to the review screen
                  primaryColor: _primaryColor,
                  accentColor: _accentColor,
              ),
            ),
          );
      } else if (mounted && generatedTasks != null && generatedTasks.isEmpty) {
         _showErrorSnackbar('AI could not generate tasks. Try adjusting inputs.');
      }
      // If generatedTasks is null, the controller should have thrown an error already

    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('Error: ${e.toString().replaceFirst("Exception: ", "")}');
      }
    } finally {
       if (mounted) {
         setState(() => _isGenerating = false);
       }
    }
  }

  void _showErrorSnackbar(String message) {
     ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(message),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating
        )
     );
  }

  @override
  void dispose() {
    _goalsController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Your Routine'),
        backgroundColor: _primaryColor, // Purple AppBar
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form( // Wrap with Form for validation if needed later
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Step 1: Wake/Sleep Times ---
              Text('Step 1: Set Your Times', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              _buildTimeSelectorCard('Wake Up Time', _wakeUpTime, () => _selectTime(context, true)),
              const SizedBox(height: 12),
              _buildTimeSelectorCard('Sleep Time', _sleepTime, () => _selectTime(context, false)),
              const SizedBox(height: 24),

              // --- Step 2: Fixed Commitments ---
              Text('Step 2: Add Fixed Commitments', style: Theme.of(context).textTheme.titleLarge),
              Text('Add your non-negotiable times like work, school, or commute.', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 12),
              if (_fixedTasks.isEmpty)
                 const Center(child: Text('No commitments added yet.', style: TextStyle(color: Colors.grey))),
              ..._fixedTasks.map((task) => _buildCommitmentInputCard(task)).toList(),
              const SizedBox(height: 12),
              Center(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add Commitment'),
                  style: OutlinedButton.styleFrom(foregroundColor: _primaryColor), // Purple button text
                  onPressed: _addCommitment,
                ),
              ),
              const SizedBox(height: 24),

              // --- Step 3: Goals ---
              Text('Step 3: What are your goals?', style: Theme.of(context).textTheme.titleLarge),
              Text('e.g., Exercise 30 minutes, Study for 1 hour, Read 20 pages', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 12),
              TextField(
                controller: _goalsController,
                decoration: InputDecoration(
                  hintText: 'What do you want to make time for?',
                  border: const OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: _primaryColor)), // Purple focus border
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 32),

              // --- Generate Button ---
              Center(
                child: ElevatedButton.icon(
                  icon: _isGenerating
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.auto_awesome), // Sparkle icon
                  label: Text(_isGenerating ? 'Generating...' : 'Generate My Schedule'),
                   style: ElevatedButton.styleFrom(
                      backgroundColor: _accentColor, // Purple accent button
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      textStyle: const TextStyle(fontSize: 16)
                   ),
                  onPressed: _isGenerating ? null : _generateSchedule,
                ),
              ),
               const SizedBox(height: 20), // Bottom padding
            ],
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildTimeSelectorCard(String label, TimeOfDay time, VoidCallback onTap) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(label),
        trailing: Text(
          RoutineTask.formatTime(time), // Use formatter
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: _primaryColor), // Purple time
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildCommitmentInputCard(FixedTaskInput task) {
    // Need controllers for title persistence during rebuilds
     final titleController = TextEditingController(text: task.title);
     // Update the model when text changes
     titleController.addListener(() {
        _updateCommitmentTitle(task.tempId!, titleController.text);
     });


    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            TextFormField(
               // Use controller here
               controller: titleController,
               decoration: InputDecoration(
                  labelText: 'Commitment Title',
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: _primaryColor)), // Purple focus line
                  suffixIcon: IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.red[300]),
                    onPressed: () => _removeCommitment(task.tempId!),
                  ),
               ),
               // No need for onChanged, listener handles it
               // onChanged: (value) => _updateCommitmentTitle(task.tempId!, value),
               validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                     onTap: () => _selectCommitmentTime(context, task.tempId!, true),
                     child: InputDecorator(
                       decoration: const InputDecoration(labelText: 'Start', border: InputBorder.none),
                       child: Text(RoutineTask.formatTime(task.startTime), style: const TextStyle(fontWeight: FontWeight.bold)),
                     ),
                  )
                ),
                 const SizedBox(width: 16),
                 Expanded(
                   child: InkWell(
                      onTap: () => _selectCommitmentTime(context, task.tempId!, false),
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'End', border: InputBorder.none),
                        child: Text(RoutineTask.formatTime(task.endTime), style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                   )
                 ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

