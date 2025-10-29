// lib/routine_manager/views/routine_main_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
// Import WeeklyChart - ensure this path is correct based on your project structure
import '../../health_manager/views/widgets/weekly_chart.dart';
import '../controllers/routine_controller.dart';
import '../models/routine_models.dart';
import 'schedule_setup_screen.dart';
import 'edit_template_screen.dart'; // Import the new edit screen

class RoutineMainScreen extends StatefulWidget {
  const RoutineMainScreen({super.key});

  @override
  State<RoutineMainScreen> createState() => _RoutineMainScreenState();
}

class _RoutineMainScreenState extends State<RoutineMainScreen> {
  // Define the purple color scheme for this module
  final Color _primaryColor = Colors.deepPurple;
  final Color _accentColor = Colors.purpleAccent;
  final Color _lightBgColor = Colors.deepPurple.shade50;
  final Color _completedColor = Colors.green;
  final Color _skippedColor = Colors.grey.shade600;
  final Color _missedColor = Colors.red.shade700;


  @override
  void initState() {
    super.initState();
    // Fetch initial data - Controller's init should handle this
     WidgetsBinding.instance.addPostFrameCallback((_) {
        // Ensure data is loaded when the screen first builds
        // Use listen: false inside initState/callbacks
        final controller = Provider.of<RoutineController>(context, listen: false);
        controller.checkTemplateExists().then((_) { // Ensure template check completes first
           if (controller.hasMasterTemplate) {
              controller.loadTodayLog();
              controller.loadSummary();
           }
        });
     });
  }

  // Helper to build the summary chart
  Widget _buildWeeklySummaryChart(BuildContext context, Map<String, double> summaryData) {
     // Get today and calculate start/end of the week for display
     final now = DateTime.now();
     // Adjust to make Monday the start (weekday returns 1 for Mon, 7 for Sun)
     int daysToSubtract = (now.weekday == DateTime.sunday) ? 6 : now.weekday - 1;
     final weekStartDate = DateTime(now.year, now.month, now.day - daysToSubtract);
     final weekEndDate = weekStartDate.add(const Duration(days: 6));

     // Ensure data for all 7 days exists, defaulting to 0
     Map<String, int> chartData = {};
     for (int i = 0; i < 7; i++) {
        final day = weekStartDate.add(Duration(days: i));
        final dayString = DateFormat('yyyy-MM-dd').format(day);
        // Convert summary double (0.0-1.0) to integer percentage (0-100)
        chartData[dayString] = ((summaryData[dayString] ?? 0.0) * 100).round(); // Use round for cleaner int
     }

     final weekStartFormatted = DateFormat.MMMd().format(weekStartDate);
     final weekEndFormatted = DateFormat.MMMd().format(weekEndDate);


     return Card(
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                      'Weekly Completion ($weekStartFormatted - $weekEndFormatted)',
                      style: TextStyle(fontWeight: FontWeight.bold, color: _primaryColor, fontSize: 16)
                    ),
                    const SizedBox(height: 12),
                     SizedBox(
                        height: 150, // Adjust height as needed
                        // --- CHART FIXES ---
                        child: WeeklyChart(
                            dataMap: chartData, // Use prepared chartData
                            valueLabel: (v) => '${v.toInt()}%', // Show percentage
                            barColor: _accentColor, // Use accent purple
                            // Explicitly set Y-axis range and interval
                            maxYValue: 100, // Force max to 100
                            interval: 25,   // Set interval to 25 (0, 25, 50, 75, 100)
                        ),
                     ),
                ],
            ),
        ),
     );
  }

  @override
  Widget build(BuildContext context) {
    // Listen to the RoutineController using Consumer for targeted rebuilds
    return Consumer<RoutineController>(
       builder: (context, routineController, child) {

        // Show setup screen if no template exists and not loading
        if (!routineController.hasMasterTemplate && !routineController.isLoading) {
           WidgetsBinding.instance.addPostFrameCallback((_) {
               // Check if mounted before navigating
               if(mounted) {
                   Navigator.of(context).pushReplacement(
                       MaterialPageRoute(builder: (_) => const ScheduleSetupScreen())
                   );
               }
           });
           // Return a loading indicator while navigating
           return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        // Show loading screen while controller initializes
        else if (routineController.isLoading && !routineController.hasMasterTemplate) {
             return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }


        // Main UI when template exists
        return Scaffold(
          backgroundColor: Colors.grey[50],
          body: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      // --- Header ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                           Text(
                            'Today\'s Routine',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _primaryColor),
                          ),
                          IconButton(
                            icon: Icon(Icons.edit_note_outlined, color: Colors.grey[600]),
                            tooltip: 'Edit Master Routine',
                            // Disable button if still loading initial data
                            onPressed: routineController.isLoading ? null : () async {
                               final bool? routineChanged = await Navigator.push<bool>(
                                  context,
                                  MaterialPageRoute(builder: (_) => const EditTemplateScreen()),
                               );
                               if (routineChanged == true && mounted) {
                                  // Refresh data after returning from edit screen
                                   Provider.of<RoutineController>(context, listen: false).loadTodayLog();
                                   Provider.of<RoutineController>(context, listen: false).loadSummary();
                               }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // --- Weekly Summary Chart ---
                      // Only build chart if summary data exists and not loading
                      if (routineController.summary.isNotEmpty && !routineController.isLoading)
                          _buildWeeklySummaryChart(context, routineController.summary),


                       const SizedBox(height: 8),
                       Text(
                         "Interact with tasks only after their end time.", // Updated hint
                         textAlign: TextAlign.center,
                         style: TextStyle(color: Colors.grey[600], fontSize: 12),
                       ),
                       const SizedBox(height: 12),


                      // --- Today's Task List ---
                      if (routineController.isLoading && routineController.todayLog.isEmpty)
                         const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator()))
                      else if (routineController.todayLog.isEmpty && !routineController.isLoading)
                         const Center(child: Padding(padding: EdgeInsets.all(32.0), child: Text("No tasks found for today.")))
                      else
                         ListView.builder(
                           shrinkWrap: true,
                           physics: const NeverScrollableScrollPhysics(),
                           itemCount: routineController.todayLog.length,
                           itemBuilder: (context, index) {
                             final task = routineController.todayLog[index];
                             return _buildTaskTile(context, task);
                           },
                         ),

                       const SizedBox(height: 80), // Bottom padding
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }
    ); // End Consumer
  }

  // Builds the tile for each task in the list
  Widget _buildTaskTile(BuildContext context, DailyRoutineTask task) {
    final routineController = Provider.of<RoutineController>(context, listen: false);
    final bool isCompleted = task.isCompleted;
    final bool isSkipped = task.isSkipped;

    final currentTime = TimeOfDay.now();
    final taskStartTime = task.startTimeOfDay;
    final taskEndTime = task.endTimeOfDay;
    final currentMinutes = currentTime.hour * 60 + currentTime.minute;
    final startMinutes = taskStartTime.hour * 60 + taskStartTime.minute;
    final endMinutes = taskEndTime.hour * 60 + taskEndTime.minute;

    // --- UPDATED INTERACTION LOGIC ---
    final bool isFuture = currentMinutes < startMinutes; // Task hasn't started yet
    final bool isActive = currentMinutes >= startMinutes && currentMinutes < endMinutes; // Task is ongoing
    final bool isPast = currentMinutes >= endMinutes; // Task end time has passed

    // --- User can only interact if the task's end time is past ---
    final bool canInteract = isPast;

    Color tileColor = Colors.white;
    Color textColor = Colors.black87;
    TextDecoration textDecoration = TextDecoration.none;
    IconData leadingIcon = Icons.radio_button_unchecked;
    Color leadingColor = _primaryColor;
    FontWeight titleWeight = FontWeight.normal;

    if (isFuture) {
        tileColor = Colors.grey.shade50;
        textColor = Colors.grey.shade500;
        leadingIcon = Icons.watch_later_outlined;
        leadingColor = Colors.grey.shade400;
     } else if (isActive && !isCompleted && !isSkipped) { // Ongoing task, not yet interactable
        tileColor = _lightBgColor;
        titleWeight = FontWeight.bold;
        leadingIcon = Icons.hourglass_top_outlined; // Use hourglass for active
        leadingColor = _primaryColor;
        textColor = _primaryColor; // Make text purple for active task
     } else if (isSkipped) { // Past or current, but skipped (interactable if past)
       tileColor = Colors.grey.shade100;
       textColor = _skippedColor;
       textDecoration = TextDecoration.lineThrough;
       leadingIcon = Icons.remove_circle_outline;
       leadingColor = _skippedColor;
     } else if (isCompleted) { // Past or current, but completed (interactable if past)
       tileColor = _completedColor.withOpacity(0.05);
       textColor = _completedColor;
       textDecoration = TextDecoration.lineThrough;
       leadingIcon = Icons.check_circle_outline;
       leadingColor = _completedColor;
     } else if (isPast) { // Past task, not completed, not skipped -> Missed (interactable)
        tileColor = _missedColor.withOpacity(0.05);
        textColor = _missedColor;
        leadingIcon = Icons.error_outline;
        leadingColor = _missedColor;
     }
     // Default style remains for edge cases or unexpected states


    return IgnorePointer( // Still use IgnorePointer, now based on isPast
        ignoring: !canInteract, // Ignore touches if the task end time hasn't passed
        child: Opacity( // Dim non-interactable tasks
           opacity: canInteract ? 1.0 : 0.6,
           child: Dismissible(
             key: ValueKey('task_${task.logId}'),
             background: Container(
                color: _completedColor, // Green background for complete
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: 20),
                child: const Icon(Icons.check_circle, color: Colors.white, size: 30),
              ),
             secondaryBackground: Container(
                color: _skippedColor, // Grey background for skip
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                child: const Icon(Icons.remove_circle, color: Colors.white, size: 30),
              ),
             confirmDismiss: (direction) async {
                // Double check interaction lock, though IgnorePointer should handle it
                if (!canInteract) return false;

                if (direction == DismissDirection.startToEnd) { // Swipe Right (Complete/Uncomplete)
                   await routineController.toggleTaskStatus(task.logId, !isCompleted);
                } else if (direction == DismissDirection.endToStart) { // Swipe Left (Skip/Unskip)
                   await routineController.toggleTaskSkipped(task.logId, !isSkipped);
                }
                return false; // We manage state via controller
             },
             child: Card(
               elevation: isActive ? 2 : 1, // Elevate active task slightly
               margin: const EdgeInsets.only(bottom: 8),
               color: tileColor,
               shape: RoundedRectangleBorder(
                 borderRadius: BorderRadius.circular(12),
                 // Highlight active task with border, even if not interactable yet
                 side: isActive ? BorderSide(color: _primaryColor, width: 1.5) : BorderSide.none,
                 ),
               child: ListTile(
                 leading: Icon(leadingIcon, color: leadingColor, size: 28),
                 title: Text(
                   task.taskTitle,
                   style: TextStyle(
                     fontWeight: titleWeight,
                     color: textColor,
                     decoration: textDecoration,
                     decorationColor: textColor.withOpacity(0.7),
                   ),
                 ),
                 subtitle: Text(
                   '${task.startTime} - ${task.endTime} (${task.category})',
                    style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 12),
                 ),
                 // Disable onTap if interaction is not allowed yet
                 onTap: canInteract ? () {
                    // Toggle completion on tap ONLY if interactable
                    routineController.toggleTaskStatus(task.logId, !isCompleted);
                 } : null,
               ),
             ),
           ),
        ),
    );
  }
}

