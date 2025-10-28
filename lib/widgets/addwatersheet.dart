
import 'package:dailysync/controllers/health_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AddWaterSheet extends StatelessWidget {
  const AddWaterSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final waterOptions = [250, 500, 750, 1000]; // in ml
    // final uuid = Uuid(); // REMOVED

    void _addWater(int amount) {
      // 1. Access Provider
      final healthProvider = Provider.of<HealthController>(context, listen: false);

      // 2. Call the centralized logic
      healthProvider.addWaterLog(amount); 
      
      // REMOVED old WaterLog creation and UUID logic

       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$amount ml of water added!'),
          backgroundColor: Colors.blue,
        ),
      );

      Navigator.of(context).pop(); // Close the sheet
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Add Water Intake',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ...waterOptions.map((amount) => Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: OutlinedButton.icon(
              icon: const Icon(Icons.local_drink),
              label: Text('$amount ml (a glass)'),
              onPressed: () => _addWater(amount),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue.shade700,
                side: BorderSide(color: Colors.blue.shade200),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          )).toList(),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
