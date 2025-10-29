// lib/health_manager/views/widgets/weekly_chart.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
// import '../../db/db_helper.dart'; // No longer needed here

class WeeklyChart extends StatelessWidget {
  final Map<String, int> dataMap; // date string -> value (e.g., '2025-10-26' -> 1000)
  final String Function(double) valueLabel; // Formatter for Y-axis labels and bar labels
  final Color barColor;
  final bool showTarget;
  final int? target; // Optional target value

  const WeeklyChart({
    super.key,
    required this.dataMap,
    required this.valueLabel,
    required this.barColor,
    this.showTarget = false,
    this.target,
  });

  @override
  Widget build(BuildContext context) {
    // Ensure dataMap keys are sorted if they aren't already
    final sortedEntries = dataMap.entries.toList()
                          ..sort((a, b) => a.key.compareTo(b.key));

    if (sortedEntries.isEmpty) {
      return const Center(child: Text('No data for the week'));
    }

    // Determine max Y value for chart scaling
    int maxVal = sortedEntries.map((e) => e.value).fold<int>(0, (p, n) => n > p ? n : p);
    if (showTarget && target != null && target! > maxVal) {
      maxVal = target!; // Ensure target line is visible if it's higher than data
    }
    final double maxY = (maxVal == 0) ? 5 : (maxVal * 1.2).ceilToDouble(); // Add 20% padding

    // Create BarChartGroupData list
    final List<BarChartGroupData> barGroups = [];
    for (var i = 0; i < sortedEntries.length; i++) {
      final value = sortedEntries[i].value.toDouble();
      barGroups.add(
        BarChartGroupData(
          x: i, // Index represents the day of the week (0=Sun, 1=Mon, ...)
          barRods: [
            BarChartRodData(
              toY: value,
              color: barColor,
              width: 16, // Bar width
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
               // Display value on top of the bar using stack items (optional visual cue)
               rodStackItems: [
                 BarChartRodStackItem(0, value, barColor.withOpacity(0.3), // Slightly transparent base
                   BorderSide(color: Colors.grey.shade300, width: 0.5) // Optional subtle border
                 ),
               ],
            ),
          ],
           // --- REMOVED this line to disable constant tooltip display ---
           // showingTooltipIndicators: value > 0 ? [0] : [],
        ),
      );
    }

    // Create labels for the bottom axis (days of the week)
    final List<String> weekLabels = sortedEntries.map((entry) {
        // Parse the date string key and format it as 'E' (e.g., 'Sun')
        final dt = DateFormat('yyyy-MM-dd').parse(entry.key);
        return DateFormat('E').format(dt).substring(0,1); // Use single letter S, M, T...
    }).toList();


    return Padding(
      // Adjust padding if labels were overlapping
      padding: const EdgeInsets.only(top: 16, right: 16, left: 8, bottom: 8),
      child: BarChart(
        BarChartData(
          maxY: maxY,
          minY: 0,
          barGroups: barGroups,
          titlesData: FlTitlesData(
            // Bottom Axis Titles (Days of Week)
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= weekLabels.length) return const SizedBox.shrink();
                  return SideTitleWidget(
                     axisSide: meta.axisSide,
                     space: 4, // Space between axis and label
                     child: Text(weekLabels[index], style: const TextStyle(fontSize: 10))
                  );
                },
                reservedSize: 22, // Space reserved for labels
              ),
            ),
            // Left Axis Titles (Values)
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40, // Space for labels
                interval: maxY / 4 > 1 ? (maxY / 4).ceilToDouble() : 1, // Adjusted interval
                 getTitlesWidget: (value, meta) {
                   // Show labels at intervals
                   if (value % meta.appliedInterval == 0) {
                      return Text(valueLabel(value), style: const TextStyle(fontSize: 10));
                   }
                   return const SizedBox.shrink();
                  },
              ),
            ),
            // Hide Top and Right Axis Titles
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          // Grid lines
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false, // Hide vertical grid lines
            horizontalInterval: maxY / 4 > 1 ? (maxY / 4).ceilToDouble() : 1, // Match left titles interval
             getDrawingHorizontalLine: (value) {
               return FlLine(
                 color: Colors.grey.shade300, // Light grey grid lines
                 strokeWidth: 0.5,
               );
             },
          ),
          // Bar touch interactions & Tooltips (This section handles the on-hold display)
          barTouchData: BarTouchData(
             enabled: true, // Enable tooltips on touch/hold
             touchTooltipData: BarTouchTooltipData(
                // Use getTooltipColor for background
                getTooltipColor: (group) => Colors.blueGrey,
                 // Tooltip text formatting
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                   // Ensure groupIndex is within bounds before accessing sortedEntries
                   String weekDay = '';
                   if (groupIndex >= 0 && groupIndex < sortedEntries.length) {
                      weekDay = DateFormat('EEEE').format(DateFormat('yyyy-MM-dd').parse(sortedEntries[groupIndex].key));
                   }
                   return BarTooltipItem(
                      '$weekDay\n',
                      const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14,),
                      children: <TextSpan>[
                         TextSpan(
                           text: valueLabel(rod.toY), // Use the provided valueLabel function
                           style: const TextStyle( // Keep style distinct
                             color: Colors.yellow,
                             fontSize: 12,
                             fontWeight: FontWeight.w500,
                           ),
                         ),
                       ],
                   );
                 },
                 tooltipPadding: const EdgeInsets.all(8), // Add some padding
                 tooltipMargin: 8, // Margin above bar
                 // Use tooltipHorizontalAlignment
                 tooltipHorizontalAlignment: FLHorizontalAlignment.center,
                 fitInsideHorizontally: true,
                 fitInsideVertically: true,
                 tooltipRoundedRadius: 4,
             ),
             // Optional: Handle touch events if needed
             // touchCallback: (FlTouchEvent event, BarTouchResponse? response) {},
          ),
          // Chart border
          borderData: FlBorderData(
            show: true, // Show border
             border: Border(
               bottom: BorderSide(color: Colors.grey.shade400, width: 1), // Only bottom border
               left: BorderSide(color: Colors.grey.shade400, width: 1), // Only left border
             ),
          ),
          // Target Line (if enabled)
          extraLinesData: (showTarget && target != null && target! > 0)
              ? ExtraLinesData(horizontalLines: [
                  HorizontalLine(
                    y: target!.toDouble(),
                    color: Colors.redAccent.withOpacity(0.8),
                    strokeWidth: 1.5,
                    // dashArray: [], // Ensure solid line
                    label: HorizontalLineLabel(
                      show: true,
                      alignment: Alignment.topRight, // Position label
                      padding: const EdgeInsets.only(right: 5, bottom: 2),
                      style: TextStyle(color: Colors.redAccent.shade700, fontSize: 10, fontWeight: FontWeight.bold),
                      labelResolver: (line) => 'Target: $target' // Display target value
                    ),
                  ),
                ])
              : ExtraLinesData(), // Empty if target line not shown
        ),
        swapAnimationDuration: const Duration(milliseconds: 150), // Optional animation
        swapAnimationCurve: Curves.linear, // Optional animation
      ),
    );
  }
}