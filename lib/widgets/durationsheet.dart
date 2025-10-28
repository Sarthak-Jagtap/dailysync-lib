import 'package:flutter/material.dart';

class SelectDurationSheet extends StatelessWidget {
  const SelectDurationSheet({super.key});

  @override
  Widget build(BuildContext context) {
    // A list of common meditation durations in minutes
    final durations = [5, 10, 15, 20, 30];

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Select Meditation Duration',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          // Create a button for each duration option
          ...durations.map((minutes) => Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: OutlinedButton(
                  onPressed: () {
                    // When a duration is tapped, close the sheet and
                    // return the selected number of minutes.
                    Navigator.of(context).pop(minutes);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.deepPurple,
                    side: BorderSide(color: Colors.deepPurple.shade200),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text('$minutes Minutes'),
                ),
              )),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
