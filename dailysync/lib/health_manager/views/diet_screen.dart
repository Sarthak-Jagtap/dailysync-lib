// lib/health_manager/views/diet_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../controllers/health_controller.dart';
import '../models/health_models.dart';

class DietScreen extends StatefulWidget {
  const DietScreen({super.key});

  @override
  State<DietScreen> createState() => _DietScreenState();
}

class _DietScreenState extends State<DietScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _morning = false, _breakfast = false, _lunch = false, _snacks = false, _dinner = false;
  bool _isLoadingDate = true; // Start as true

  // Colors for theme
  final Color _primaryColor = Colors.green.shade700; // Darker green for primary elements
  // final Color _secondaryColor = Colors.green.shade400; // Lighter green for accents/charts (unused for now)
  final Color _lightBgColor = Colors.green.shade50; // Very light green for card backgrounds


  @override
  void initState() {
    super.initState();
    // Load diet for the initially selected date *after* the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
       if (mounted) { // Ensure widget is still mounted
         _loadDietForSelectedDate(_selectedDate);
       }
    });
  }

  // Fetch and update checkboxes based on the selected date
  Future<void> _loadDietForSelectedDate(DateTime date) async {
     if (!mounted) return; // Check if widget is still in the tree
     setState(() => _isLoadingDate = true);
     final ctrl = Provider.of<HealthController>(context, listen: false);
     final dietEntry = await ctrl.getDietForDate(date);
     if (mounted) { // Check again after await
       setState(() {
         _selectedDate = date; // Update the selected date state
         if (dietEntry != null) {
           _morning = dietEntry.morningDryFruits;
           _breakfast = dietEntry.breakfast;
           _lunch = dietEntry.lunch;
           _snacks = dietEntry.snacks;
           _dinner = dietEntry.dinner;
         } else {
           // Reset checkboxes if no entry exists for the date
           _morning = false;
           _breakfast = false;
           _lunch = false;
           _snacks = false;
           _dinner = false;
         }
         _isLoadingDate = false;
       });
     }
  }

 Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)), // Allow past year
      lastDate: DateTime.now(), // Allow up to today
      builder: (context, child) { // Apply green theme to Date Picker
        return Theme(
          data: ThemeData.light().copyWith(
             colorScheme: ColorScheme.light(
               primary: _primaryColor, // header background color
               onPrimary: Colors.white, // header text color
               onSurface: Colors.black87, // body text color (calendar dates)
             ),
             dialogBackgroundColor: Colors.white,
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: _primaryColor, // button text color
                ),
              ),
           ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      // Load data for the newly selected date
      _loadDietForSelectedDate(picked);
    }
  }


  Future<void> _save(HealthController ctrl) async {
    await ctrl.addDiet(
      date: _selectedDate, // Use the currently selected date
      morningDryFruits: _morning,
      breakfast: _breakfast,
      lunch: _lunch,
      snacks: _snacks,
      dinner: _dinner,
    );
    if(mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
            content: const Text('Diet saved'),
            backgroundColor: _primaryColor, // Green snackbar
        )
      );
    }
     // Refresh weekly data in controller after saving
     ctrl.loadWeekly();
  }

  // Helper to build a row in the weekly summary table
  TableRow _buildDietTableRow(BuildContext context, String mealName, Map<String, DietEntry?> weeklyDataMap, bool Function(DietEntry) getMealStatus) {
    final ctrl = Provider.of<HealthController>(context, listen: false);
    final daysOfWeek = List.generate(7, (index) => ctrl.currentWeekStart.add(Duration(days: index)));

    return TableRow(
      children: [
        // Meal Name Cell
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          alignment: Alignment.centerLeft,
          child: Text(mealName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ),
        // Day Cells (Sun-Sat)
        ...daysOfWeek.map((day) {
          final entry = weeklyDataMap[dateToKey(day)];
          // Determine if the day is today or in the past
           final today = DateTime.now();
           // Simplified check for future date
           final isFutureDate = day.isAfter(DateTime(today.year, today.month, today.day));


          return Center(
             child: Padding(
               padding: const EdgeInsets.symmetric(vertical: 6.0), // Padding inside cell
               child: _getStatusIcon(entry, getMealStatus, !isFutureDate), // Pass !isFutureDate
             ),
          );
        }).toList(),
      ],
    );
  }

 // Helper to get the icon (tick, cross, or empty) based on meal status and date
  Widget _getStatusIcon(DietEntry? entry, bool Function(DietEntry) getStatus, bool isPastOrToday) {
     if (!isPastOrToday) {
       // If the date is in the future, show nothing
       return const SizedBox(width: 18, height: 18); // Empty placeholder
     }

     // If it's past or today, show tick or cross based on data
     bool hadMeal = entry != null && getStatus(entry);
     return Icon(
       hadMeal ? Icons.check_circle_outline : Icons.highlight_off,
       color: hadMeal ? _primaryColor : Colors.red.shade400,
       size: 18,
     );
  }


  @override
  Widget build(BuildContext context) {
    final ctrl = Provider.of<HealthController>(context);
    final weekStart = DateFormat.MMMd().format(ctrl.currentWeekStart);
    final weekEnd = DateFormat.MMMd().format(ctrl.currentWeekEnd);

    // Prepare data map for faster lookup in the table
    // Ensure keys match the format used in dateToKey
    final Map<String, DietEntry?> weeklyDataMap = {
       for (var entry in ctrl.dietEntriesWeekly) entry.date: entry
    };

     final List<DateTime> weekDays = List.generate(7, (i) => ctrl.currentWeekStart.add(Duration(days: i)));


    return SingleChildScrollView( // Make the whole screen scrollable
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch cards
          children: [
            // --- Weekly Summary Table ---
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                     Text(
                      'Weekly Diet Log ($weekStart - $weekEnd)',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView( // Make table horizontally scrollable if needed
                      scrollDirection: Axis.horizontal,
                      child: Table(
                        border: TableBorder.all(color: Colors.grey.shade300, width: 1),
                        columnWidths: const { // Use const map here
                          0: FixedColumnWidth(80), // Meal type column width
                          1: FixedColumnWidth(40), // Sun
                          2: FixedColumnWidth(40), // Mon
                          3: FixedColumnWidth(40), // Tue
                          4: FixedColumnWidth(40), // Wed
                          5: FixedColumnWidth(40), // Thu
                          6: FixedColumnWidth(40), // Fri
                          7: FixedColumnWidth(40), // Sat
                        },
                        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                        children: [
                          // Header Row (Days)
                          TableRow(
                            decoration: BoxDecoration(color: Colors.grey.shade100),
                            children: [
                              Container(height: 35, // Match row height
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                alignment: Alignment.centerLeft,
                                child: const Text('Meal', style: TextStyle(fontWeight: FontWeight.bold)),
                              ), // Empty cell top-left
                              ...weekDays.map((day) {
                                return Center(child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Text(DateFormat('E').format(day).substring(0,1), // S, M, T etc.
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                ));
                              }).toList(),
                            ],
                          ),
                          // Meal Rows
                           _buildDietTableRow(context, 'Morning', weeklyDataMap, (e) => e.morningDryFruits),
                           _buildDietTableRow(context, 'Breakfast', weeklyDataMap, (e) => e.breakfast),
                           _buildDietTableRow(context, 'Lunch', weeklyDataMap, (e) => e.lunch),
                           _buildDietTableRow(context, 'Snacks', weeklyDataMap, (e) => e.snacks),
                           _buildDietTableRow(context, 'Dinner', weeklyDataMap, (e) => e.dinner),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

             // --- Date Selection ---
             Card(
               elevation: 2,
               child: Padding(
                 padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                 child: Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                     Text('Log for: ${DateFormat.yMMMd().format(_selectedDate)}', style: const TextStyle(fontSize: 16)),
                     OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: const Text('Change Date'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _primaryColor, // Text/icon color
                          side: BorderSide(color: _primaryColor), // Border color
                           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                           textStyle: const TextStyle(fontSize: 14),
                        ),
                       onPressed: () => _selectDate(context),
                     )
                   ],
                 ),
               ),
             ),
             const SizedBox(height: 16),


            // --- Daily Diet Entry Section ---
            Card(
              color: _lightBgColor, // Use light green theme color
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: _isLoadingDate
                    ? const Padding( // Consistent loading indicator size
                        padding: EdgeInsets.symmetric(vertical: 40.0),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : Column(
                        children: [
                           // Use SwitchListTile instead of _buildCheckbox helper
                           _buildSwitchTile('Morning dry fruits', _morning, (v) => _morning = v),
                           _buildSwitchTile('Breakfast', _breakfast, (v) => _breakfast = v),
                           _buildSwitchTile('Lunch', _lunch, (v) => _lunch = v),
                           _buildSwitchTile('Snacks', _snacks, (v) => _snacks = v),
                           _buildSwitchTile('Dinner', _dinner, (v) => _dinner = v),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.save_alt),
                            label: const Text('Save Diet Log'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryColor, // Green button
                              foregroundColor: Colors.white, // White text/icon
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                            onPressed: () => _save(ctrl), // Use ctrl from build method scope
                          )
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- NEW Helper for SwitchListTile ---
  Widget _buildSwitchTile(String title, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(title),
      value: value,
      onChanged: (v) => setState(() => onChanged(v)), // Directly update state
      activeColor: _primaryColor, // Use primary green color for active state
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4.0), // Adjust padding slightly
    );
  }

  // Helper for CheckboxListTile - Keep original if needed elsewhere, but not used here anymore
  // Widget _buildCheckbox(String title, bool value, Function(bool) onChanged) {
  //   return CheckboxListTile(
  //     title: Text(title),
  //     value: value,
  //     onChanged: (v) => setState(() => onChanged(v ?? false)),
  //     activeColor: _primaryColor, // Green checkbox
  //     controlAffinity: ListTileControlAffinity.leading, // Checkbox on the left
  //     dense: true,
  //     contentPadding: EdgeInsets.zero, // Remove default padding
  //   );
  // }
}

