// lib/health_manager/views/widgets/weekly_chart.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class WeeklyChart extends StatelessWidget {
  final Map<String, int> dataMap; // date string -> value (e.g., '2025-10-26' -> 1000)
  final String Function(double) valueLabel; // Formatter for Y-axis labels and bar labels
  final Color barColor;
  final bool showTarget;
  final int? target; // Optional target value
  // --- NEW PARAMETERS ---
  final double? maxYValue; // Optional explicit max Y value
  final double? interval;  // Optional explicit Y axis interval

  const WeeklyChart({
    super.key,
    required this.dataMap,
    required this.valueLabel,
    required this.barColor,
    this.showTarget = false,
    this.target,
    this.maxYValue, // Added to constructor
    this.interval,   // Added to constructor
  });

  @override
  Widget build(BuildContext context) {
    // Ensure dataMap keys are sorted if they aren't already
    final sortedEntries = dataMap.entries.toList()
                          ..sort((a, b) => a.key.compareTo(b.key));

    if (sortedEntries.isEmpty) {
      return const Center(child: Text('No data for the week'));
    }

    // --- UPDATED Y-AXIS LOGIC ---
    // Determine max Y value for chart scaling
    double calculatedMaxY;
    if (maxYValue != null && maxYValue! > 0) {
      // Use provided maxYValue if valid
      calculatedMaxY = maxYValue!;
    } else {
      // Calculate max based on data and target otherwise
      int maxDataVal = sortedEntries.map((e) => e.value).fold<int>(0, (p, n) => n > p ? n : p);
      if (showTarget && target != null && target! > maxDataVal) {
        maxDataVal = target!;
      }
      calculatedMaxY = (maxDataVal == 0) ? 5 : (maxDataVal * 1.2).ceilToDouble(); // Add 20% padding if calculated
    }

    // Determine interval
    final double appliedInterval = interval ?? (calculatedMaxY / 4 > 1 ? (calculatedMaxY / 4).ceilToDouble() : 1);


    // Create BarChartGroupData list (No changes here)
    final List<BarChartGroupData> barGroups = [];
    for (var i = 0; i < sortedEntries.length; i++) {
      final value = sortedEntries[i].value.toDouble();
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: value,
              color: barColor,
              width: 16,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
               rodStackItems: [
                 BarChartRodStackItem(0, value, barColor.withOpacity(0.3),
                   BorderSide(color: Colors.grey.shade300, width: 0.5)
                 ),
               ],
            ),
          ],
        ),
      );
    }

    // Create labels for the bottom axis (No changes here)
    final List<String> weekLabels = sortedEntries.map((entry) {
        final dt = DateFormat('yyyy-MM-dd').parse(entry.key);
        return DateFormat('E').format(dt).substring(0,1);
    }).toList();


    return Padding(
      padding: const EdgeInsets.only(top: 16, right: 16, left: 8, bottom: 8),
      child: BarChart(
        BarChartData(
          // --- USE CALCULATED VALUES ---
          maxY: calculatedMaxY,
          minY: 0,
          barGroups: barGroups,
          titlesData: FlTitlesData(
            // Bottom Axis Titles (No changes here)
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= weekLabels.length) return const SizedBox.shrink();
                  return SideTitleWidget(
                     axisSide: meta.axisSide,
                     space: 4,
                     child: Text(weekLabels[index], style: const TextStyle(fontSize: 10))
                  );
                },
                reservedSize: 22,
              ),
            ),
            // Left Axis Titles (Values) - Use appliedInterval
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                // --- USE APPLIED INTERVAL ---
                interval: appliedInterval,
                 getTitlesWidget: (value, meta) {
                   // Show labels at intervals, ensuring 0 is shown
                   if (value == 0 || value % meta.appliedInterval == 0) {
                      // Ensure label fits, especially for 100%
                      return Text(valueLabel(value), style: const TextStyle(fontSize: 10), textAlign: TextAlign.right,);
                   }
                   return const SizedBox.shrink();
                  },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          // Grid lines - Use appliedInterval
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            // --- USE APPLIED INTERVAL ---
            horizontalInterval: appliedInterval,
             getDrawingHorizontalLine: (value) {
               return FlLine(
                 color: Colors.grey.shade300,
                 strokeWidth: 0.5,
               );
             },
          ),
          // Bar touch interactions & Tooltips (No changes here)
          barTouchData: BarTouchData(
             enabled: true,
             touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (group) => Colors.blueGrey,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                   String weekDay = '';
                   if (groupIndex >= 0 && groupIndex < sortedEntries.length) {
                      weekDay = DateFormat('EEEE').format(DateFormat('yyyy-MM-dd').parse(sortedEntries[groupIndex].key));
                   }
                   return BarTooltipItem(
                      '$weekDay\n',
                      const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14,),
                      children: <TextSpan>[
                         TextSpan(
                           text: valueLabel(rod.toY),
                           style: const TextStyle(
                             color: Colors.yellow,
                             fontSize: 12,
                             fontWeight: FontWeight.w500,
                           ),
                         ),
                       ],
                   );
                 },
                 tooltipPadding: const EdgeInsets.all(8),
                 tooltipMargin: 8,
                 tooltipHorizontalAlignment: FLHorizontalAlignment.center,
                 fitInsideHorizontally: true,
                 fitInsideVertically: true,
                 tooltipRoundedRadius: 4,
             ),
          ),
          // Chart border (No changes here)
          borderData: FlBorderData(
            show: true,
             border: Border(
               bottom: BorderSide(color: Colors.grey.shade400, width: 1),
               left: BorderSide(color: Colors.grey.shade400, width: 1),
             ),
          ),
          // Target Line (No changes here)
          extraLinesData: (showTarget && target != null && target! > 0)
              ? ExtraLinesData(horizontalLines: [
                  HorizontalLine(
                    y: target!.toDouble(),
                    color: Colors.redAccent.withOpacity(0.8),
                    strokeWidth: 1.5,
                    label: HorizontalLineLabel(
                      show: true,
                      alignment: Alignment.topRight,
                      padding: const EdgeInsets.only(right: 5, bottom: 2),
                      style: TextStyle(color: Colors.redAccent.shade700, fontSize: 10, fontWeight: FontWeight.bold),
                      labelResolver: (line) => 'Target: $target'
                    ),
                  ),
                ])
              : ExtraLinesData(),
        ),
        swapAnimationDuration: const Duration(milliseconds: 150),
        swapAnimationCurve: Curves.linear,
      ),
    );
  }
}
