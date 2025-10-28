import 'package:dailysync/models/workoutlog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:uuid/uuid.dart';

class LogWorkoutSheet extends StatefulWidget {
  const LogWorkoutSheet({super.key});

  @override
  State<LogWorkoutSheet> createState() => _LogWorkoutSheetState();
}

class _LogWorkoutSheetState extends State<LogWorkoutSheet> {
  final _formKey = GlobalKey<FormState>();
  final _workoutNameController = TextEditingController();
  final _durationController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _uuid = Uuid();

  void _submitData() {
    if (_formKey.currentState!.validate()) {
      final newWorkout = WorkoutLog(
        id: _uuid.v4(),
        workoutName: _workoutNameController.text,
        durationInMinutes: int.parse(_durationController.text),
        caloriesBurned: int.parse(_caloriesController.text),
        date: DateTime.now(),
      );

      // --- DATABASE INTEGRATION POINT ---
      // Here, you would call your database service to save the `newWorkout`
      // For example: await DatabaseService.addWorkout(newWorkout);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${newWorkout.workoutName} logged successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop(); // Close the bottom sheet
    }
  }

  @override
  void dispose() {
    _workoutNameController.dispose();
    _durationController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 24,
          left: 24,
          right: 24,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text(
                'Log a Workout',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _workoutNameController,
                decoration: const InputDecoration(labelText: 'Workout Name (e.g., Morning Run)'),
                validator: (value) => value == null || value.isEmpty ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _durationController,
                decoration: const InputDecoration(labelText: 'Duration (minutes)'),
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                validator: (value) => value == null || value.isEmpty ? 'Please enter a duration' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _caloriesController,
                decoration: const InputDecoration(labelText: 'Calories Burned'),
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                validator: (value) => value == null || value.isEmpty ? 'Please enter calories' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Save Workout', style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
