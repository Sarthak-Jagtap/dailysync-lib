import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


class LogMealSheet extends StatefulWidget {
  const LogMealSheet({super.key});

  @override
  State<LogMealSheet> createState() => _LogMealSheetState();
}

class _LogMealSheetState extends State<LogMealSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _timeController = TextEditingController();
  final _caloriesController = TextEditingController();

  bool _isInit = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // This check ensures the code only runs once.
    if (_isInit) {
      // Pre-fill the time with the current time, now that context is available.
      _timeController.text = TimeOfDay.now().format(context);
    }
    _isInit = false;
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // RETURN A MAP OF RAW DATA INSTEAD OF A MEAL OBJECT
      final newMealData = {
        "name": _nameController.text,
        "time": _timeController.text,
        "calories": int.parse(_caloriesController.text),
      };
      // Return the new meal DATA map to the nutrition screen
      // The calling screen (NutritionScreen) will now call the provider.
      Navigator.of(context).pop(newMealData);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _timeController.dispose();
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
            children: [
              const Text(
                'Log a New Meal',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Meal Name (e.g., Afternoon Snack)'),
                validator: (value) => value == null || value.trim().isEmpty ? 'Please enter a meal name.' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _timeController,
                decoration: const InputDecoration(labelText: 'Time'),
                readOnly: true, // Make it read-only and open a time picker on tap
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (time != null) {
                    setState(() {
                      _timeController.text = time.format(context);
                    });
                  }
                },
              ),
               const SizedBox(height: 12),
              TextFormField(
                controller: _caloriesController,
                decoration: const InputDecoration(labelText: 'Calories'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                 validator: (value) => value == null || value.isEmpty ? 'Please enter calories.' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Log Meal'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

