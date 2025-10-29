// lib/health_manager/views/sleep_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../controllers/health_controller.dart';
// import '../models/health_models.dart'; // No longer needed directly here
import '../db/db_helper.dart'; // Import for dateToKey
import 'widgets/weekly_chart.dart'; // Import chart widget


class SleepScreen extends StatefulWidget {
  const SleepScreen({super.key});

  @override
  State<SleepScreen> createState() => _SleepScreenState();
}

class _SleepScreenState extends State<SleepScreen> {
  DateTime _selectedDate = DateTime.now();
  TimeOfDay? _bedTime;
  TimeOfDay? _wakeTime;
  int? _loggedMinutes; // To display duration if already logged
  bool _isLoadingDate = true;

  // Theme Colors
  final Color _primaryColor = Colors.green.shade700;
  final Color _secondaryColor = Colors.green.shade400;
  final Color _lightBgColor = Colors.green.shade50;


 @override
 void initState() {
   super.initState();
   WidgetsBinding.instance.addPostFrameCallback((_) {
     if (mounted) {
       _loadSleepForSelectedDate(_selectedDate);
     }
   });
 }

 // Load existing sleep data for the selected date
 Future<void> _loadSleepForSelectedDate(DateTime date) async {
    if (!mounted) return;
    setState(() => _isLoadingDate = true);
    final ctrl = Provider.of<HealthController>(context, listen: false);
    final sleepData = await ctrl.getSleepForDate(date);
    if (mounted) {
      setState(() {
        _selectedDate = date;
        _loggedMinutes = sleepData?.minutes;
        // Clear time pickers if loading a new date without data
        // Only clear if no data is loaded, otherwise keep them disabled
        if (sleepData == null) {
          _bedTime = null;
          _wakeTime = null;
        }
        _isLoadingDate = false;
      });
    }
 }

 // Show Date Picker
 Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
       builder: (context, child) { // Theme the picker
            return Theme(
              data: ThemeData.light().copyWith(
                colorScheme: ColorScheme.light(primary: _primaryColor),
              ),
              child: child!,
            );
          },
    );
    if (picked != null && picked != _selectedDate) {
       _loadSleepForSelectedDate(picked); // Load data for new date
    }
 }

 // Show Time Picker - ONLY if sleep not already logged for the date
 Future<void> _selectTime(BuildContext context, bool isBedTime) async {
    // --- ADDED: Check if sleep is already logged ---
    if (_loggedMinutes != null) return; // Do nothing if already logged

    final TimeOfDay initialTime = isBedTime
        ? (_bedTime ?? TimeOfDay(hour: 22, minute: 0)) // Default bed time
        : (_wakeTime ?? TimeOfDay(hour: 7, minute: 0)); // Default wake time

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) { // Theme the picker
            return Theme(
              data: ThemeData.light().copyWith(
                 colorScheme: ColorScheme.light(primary: _primaryColor),
                 buttonTheme: ButtonThemeData(textTheme: ButtonTextTheme.primary),
              ),
              child: child!,
            );
          },
    );

    if (picked != null) {
      setState(() {
        if (isBedTime) {
          _bedTime = picked;
        } else {
          _wakeTime = picked;
        }
        // _loggedMinutes = null; // No need to clear loggedMinutes here anymore
      });
    }
 }

 // Calculate sleep duration in minutes
 int? _calculateDuration() {
    if (_bedTime == null || _wakeTime == null) {
      return null;
    }

    // Convert TimeOfDay to minutes from midnight
    int bedMinutes = _bedTime!.hour * 60 + _bedTime!.minute;
    int wakeMinutes = _wakeTime!.hour * 60 + _wakeTime!.minute;

    if (wakeMinutes >= bedMinutes) {
      // Woke up on the same day
      return wakeMinutes - bedMinutes;
    } else {
      // Woke up the next day (add 24 hours in minutes)
      return (24 * 60 - bedMinutes) + wakeMinutes;
    }
 }

 // Save sleep duration to DB - ONLY if not already logged
 Future<void> _saveSleep(HealthController ctrl) async {
   // --- ADDED: Check if sleep is already logged ---
   if (_loggedMinutes != null) {
      if(mounted){
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Sleep already logged for ${DateFormat.MMMd().format(_selectedDate)}.'),
          backgroundColor: Colors.orange.shade700,
        ));
      }
     return; // Don't save again
   }

   int? duration = _calculateDuration(); // Calculate duration from pickers

   if (duration == null || duration <= 0) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(
           content: const Text('Please select valid bed and wake times.'),
           backgroundColor: Colors.red.shade600,
         ));
      }
      return;
   }

    // Call with named parameters
    await ctrl.addSleep(
      duration,
      date: _selectedDate,
    );
     // Update the displayed logged minutes immediately after saving
     setState(() {
       _loggedMinutes = duration;
     });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Sleep for ${DateFormat.yMMMd().format(_selectedDate)} saved.'),
        backgroundColor: _primaryColor,
      ));
    }
     // Refresh weekly data (optional, but good practice)
     ctrl.loadWeekly();
 }

  // Helper to format minutes to hours string (e.g., 450 -> "7.5h")
  String _formatMinutesToHours(int minutes) {
    if (minutes <= 0) return "0h";
    double hours = minutes / 60.0;
    return '${hours.toStringAsFixed(1)}h'; // Format to one decimal place
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Provider.of<HealthController>(context);
    final weekStart = DateFormat.MMMd().format(ctrl.currentWeekStart);
    final weekEnd = DateFormat.MMMd().format(ctrl.currentWeekEnd);

    int? calculatedDuration = _calculateDuration();
    // Determine the text based on whether sleep is logged or being calculated
    String durationText = _loggedMinutes != null
       ? _formatMinutesToHours(_loggedMinutes!) // Format logged minutes
       : (calculatedDuration != null ? _formatMinutesToHours(calculatedDuration) : '--'); // Format calculated or show placeholder


    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
             // --- Weekly Sleep Chart ---
             Card(
               elevation: 2,
               child: Padding(
                 padding: const EdgeInsets.all(12),
                 child: Column(
                   children: [
                     Text(
                       'Weekly Sleep ($weekStart - $weekEnd)',
                       style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                     ),
                     const SizedBox(height: 8),
                     SizedBox(
                       height: 200,
                       child: WeeklyChart(
                         dataMap: ctrl.sleepWeekly, // This map contains minutes
                         // valueLabel converts minutes to hours string
                         valueLabel: (minutes) => _formatMinutesToHours(minutes.toInt()),
                         barColor: _secondaryColor, // Use theme color
                       ),
                     ),
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
                    Text('Log Sleep for: ${DateFormat.yMMMd().format(_selectedDate)}', style: const TextStyle(fontSize: 16)),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: const Text('Change Date'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _primaryColor,
                        side: BorderSide(color: _primaryColor),
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

             // --- Time Input Section ---
             Card(
               color: _lightBgColor,
               elevation: 2,
               child: Padding(
                 padding: const EdgeInsets.all(16),
                 child: _isLoadingDate
                     ? const Padding(
                         padding: EdgeInsets.symmetric(vertical: 40.0),
                         child: Center(child: CircularProgressIndicator()),
                       )
                     : Column(
                       children: [
                         Row(
                           mainAxisAlignment: MainAxisAlignment.spaceAround,
                           children: [
                             // --- Pass disabled status to time selector ---
                             _buildTimeSelector("Bed Time", _bedTime, true, disabled: _loggedMinutes != null),
                             _buildTimeSelector("Wake Time", _wakeTime, false, disabled: _loggedMinutes != null),
                           ],
                         ),
                         const SizedBox(height: 20),
                         // Display Duration
                         Text(
                           "Duration: $durationText",
                           style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                         ),
                         const SizedBox(height: 20),
                          // Save Button - Disable if already logged
                         ElevatedButton.icon(
                           icon: Icon(_loggedMinutes != null ? Icons.check_circle : Icons.save_alt), // Change icon when logged
                           label: Text(_loggedMinutes != null ? 'Sleep Logged' : 'Save Sleep Log'),
                           style: ElevatedButton.styleFrom(
                             backgroundColor: _loggedMinutes != null ? Colors.grey : _primaryColor, // Grey out if logged
                             foregroundColor: Colors.white,
                             padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                           ),
                           // --- Disable onPressed if logged ---
                           onPressed: _loggedMinutes != null ? null : () => _saveSleep(ctrl),
                         ),
                       ],
                     ),
               ),
             ),
          ],
        ),
      ),
    );
  }

 // Helper widget for selecting Bed Time or Wake Time
 // --- ADDED: disabled parameter ---
 Widget _buildTimeSelector(String label, TimeOfDay? selectedTime, bool isBedTime, {bool disabled = false}) {
   return Column(
     children: [
       Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: disabled ? Colors.grey : Colors.black87)),
       const SizedBox(height: 8),
       OutlinedButton(
         style: OutlinedButton.styleFrom(
           foregroundColor: disabled ? Colors.grey : _primaryColor,
           side: BorderSide(color: disabled ? Colors.grey.shade400 : _primaryColor),
         ),
         // --- Disable onPressed if disabled ---
         onPressed: disabled ? null : () => _selectTime(context, isBedTime),
         child: Text(selectedTime?.format(context) ?? (disabled ? '--:--' : 'Select Time')),
       ),
     ],
   );
 }
}