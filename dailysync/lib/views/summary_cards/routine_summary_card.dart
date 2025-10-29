import 'package:flutter/material.dart';

// --- Model for Routine Data ---
class RoutineStep {
  final String title;
  final TimeOfDay startTime;
  final bool isCompleted;

  const RoutineStep(this.title, this.startTime, this.isCompleted);

  // Helper method to create a copy with a toggled state
  RoutineStep toggleCompletion() {
    return RoutineStep(title, startTime, !isCompleted);
  }
}

// --- Main Routine Summary Card Component (Stateful) ---
class RoutineSummaryCard extends StatefulWidget {
  const RoutineSummaryCard({super.key});

  @override
  State<RoutineSummaryCard> createState() => _RoutineSummaryCardState();
}

class _RoutineSummaryCardState extends State<RoutineSummaryCard> {
  final ScrollController _scrollController = ScrollController();
  final double _stepWidth = 160.0; // Fixed width for each step tile
  final double _itemSpacing = 12.0; 
  // The padding applied to the SingleChildScrollView
  final double _horizontalPadding = 16.0; 

  // Mock routine data with start times
  List<RoutineStep> routineSteps = [
    const RoutineStep("Wake Up & Hydrate", TimeOfDay(hour: 7, minute: 0), false),
    const RoutineStep("Morning Workout", TimeOfDay(hour: 7, minute: 30), false),
    const RoutineStep("Shower & Dress", TimeOfDay(hour: 8, minute: 30), false),
    const RoutineStep("Breakfast & News", TimeOfDay(hour: 9, minute: 0), false),
    const RoutineStep("Start Deep Work", TimeOfDay(hour: 9, minute: 30), false),
    const RoutineStep("Lunch Break", TimeOfDay(hour: 13, minute: 0), false),
    const RoutineStep("Afternoon Focus", TimeOfDay(hour: 14, minute: 0), false),
    const RoutineStep("Evening Wind Down", TimeOfDay(hour: 18, minute: 0), false),
    const RoutineStep("Dinner & Family Time", TimeOfDay(hour: 19, minute: 30), false),
    const RoutineStep("Read & Journal", TimeOfDay(hour: 21, minute: 0), false),
    const RoutineStep("Bedtime Prep", TimeOfDay(hour: 22, minute: 0), false),
  ];

  // Logic to find the current/next step based on time
  int _getActiveStepIndex() {
    final now = TimeOfDay.fromDateTime(DateTime.now());
    
    final nextUpIndex = routineSteps.indexWhere((step) {
      final stepMinutes = step.startTime.hour * 60 + step.startTime.minute;
      final nowMinutes = now.hour * 60 + now.minute;
      return stepMinutes >= nowMinutes;
    });

    if (nextUpIndex == -1) {
      return routineSteps.length - 1; 
    }
    
    if (nextUpIndex == 0) {
      return 0;
    }

    return nextUpIndex - 1;
  }

  // Function to toggle task completion and trigger setState
  void _toggleStep(RoutineStep step) {
    setState(() {
      final index = routineSteps.indexOf(step);
      if (index != -1) {
        routineSteps[index] = step.toggleCompletion();
      }
      _scrollToActiveStep();
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToActiveStep();
    });
  }

  void _scrollToActiveStep() {
    final activeIndex = _getActiveStepIndex();
    
    final contextWidth = MediaQuery.of(context).size.width;
    
    // 1. Calculate the starting position (left edge) of the active item, including item spacing
    final double activeItemStartPos = activeIndex * (_stepWidth + _itemSpacing);

    // 2. Add half the step width to find the item's center point (relative to scroll start)
    final double activeItemCenterPos = activeItemStartPos + (_stepWidth / 2);

    // 3. Calculate the required scroll position to bring the item's center to the viewport center (contextWidth / 2)
    final double scrollPosition = activeItemCenterPos - (contextWidth / 2);
    
    // 4. FIX: Correct the scroll position by SUBTRACTING the left padding (16.0).
    // The content is visually shifted right by 16.0, so we need to shift the scroll offset left by 16.0.
    final double adjustedScrollPosition = scrollPosition - _horizontalPadding;

    // Clamp the position to prevent scrolling past the bounds
    final maxScrollExtent = (_stepWidth * routineSteps.length) + (_itemSpacing * (routineSteps.length - 1)) - contextWidth;
    
    final clampedScrollPosition = adjustedScrollPosition.clamp(0.0, maxScrollExtent.clamp(0.0, double.infinity));
    
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        clampedScrollPosition,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeIndex = _getActiveStepIndex();
    final completedCount = routineSteps.where((s) => s.isCompleted).length;
    final totalCount = routineSteps.length;
    final progress = totalCount > 0 ? completedCount / totalCount : 0.0;
    
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Time-Block Routine",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "${(progress * 100).toInt()}% Done",
                    style: TextStyle(fontSize: 14, color: Colors.pinkAccent.shade400, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Progress Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.pinkAccent.shade400),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),

            // Timeline Scroller
            SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: _horizontalPadding),
              child: Row(
                children: List.generate(routineSteps.length, (index) {
                  final step = routineSteps[index];
                  final isCurrent = index == activeIndex;
                  final isMissed = index < activeIndex && !step.isCompleted; 

                  // Use conditional height for emphasis on the current task
                  final tileHeight = isCurrent ? 140.0 : 120.0;
                  
                  return Padding(
                    padding: EdgeInsets.only(right: _itemSpacing), // Use the defined item spacing
                    child: SizedBox(
                      width: _stepWidth,
                      height: tileHeight,
                      child: _TimeStepTile(
                        step: step,
                        isCurrentTime: isCurrent,
                        isMissed: isMissed, 
                        onTap: () => _toggleStep(step),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Helper Widget for Individual Step in the Timeline ---
class _TimeStepTile extends StatelessWidget {
  final RoutineStep step;
  final bool isCurrentTime;
  final bool isMissed; 
  final VoidCallback onTap;

  const _TimeStepTile({
    required this.step,
    required this.isCurrentTime,
    required this.isMissed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Define Color Palette
    final Color activeColor = Colors.pinkAccent.shade400;
    final Color completedColor = Colors.green.shade600;
    final Color missedColor = Colors.red.shade700; 
    final Color defaultColor = Colors.blueGrey.shade400;

    // Determine primary color based on state
    final Color primaryColor = step.isCompleted 
        ? completedColor 
        : (isMissed ? missedColor : (isCurrentTime ? activeColor : defaultColor));
        
    // Determine background color based on state
    final Color backgroundColor = step.isCompleted 
        ? Colors.green.shade50! 
        : (isMissed ? Colors.red.withOpacity(0.1) : (isCurrentTime ? Colors.pink.withOpacity(0.1) : Colors.grey.shade100));

    // Determine status label text
    String statusText = "";
    if (isMissed) {
      statusText = "MISSED";
    } else if (isCurrentTime) {
      statusText = "CURRENT";
    } else if (step.isCompleted) {
      statusText = "COMPLETED";
    } else {
      statusText = "UP NEXT";
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCurrentTime || isMissed ? primaryColor : primaryColor.withOpacity(0.5),
            width: isCurrentTime ? 3.0 : 1.0, 
          ),
          boxShadow: [
            if (isCurrentTime) 
              BoxShadow(
                color: primaryColor.withOpacity(0.4),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Time
            Text(
              step.startTime.format(context),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: primaryColor,
              ),
            ),
            // Title
            Expanded(
              child: Text(
                step.title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: primaryColor,
                  decoration: step.isCompleted ? TextDecoration.lineThrough : null,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Checkbox/Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 10,
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(
                  step.isCompleted ? Icons.check_circle_outline : Icons.circle_outlined,
                  color: primaryColor,
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
