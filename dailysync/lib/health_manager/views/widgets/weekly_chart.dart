// lib/health_manager/views/widgets/weekly_chart.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class WeeklyChart extends StatelessWidget {
  final Map<String, int> dataMap; // date string -> value
  final String Function(double) valueLabel;
  final Color barColor;
  final bool showTarget;
  final int? target;

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
    final entries = dataMap.entries.toList(); // already in order (db returns oldest->newest)
    if (entries.isEmpty) {
      // show placeholder
      return const Center(child: Text('No data for the week'));
    }

    final maxVal = entries.map((e) => e.value).fold<int>(0, (p, n) => n > p ? n : p);
    final double maxY = (maxVal == 0) ? 5 : (maxVal * 1.2).ceilToDouble();

    final spots = <BarChartGroupData>[];
    for (var i = 0; i < entries.length; i++) {
      final val = entries[i].value.toDouble();
      spots.add(BarChartGroupData(
        x: i,
        barsSpace: 4,
        barRods: [BarChartRodData(toY: val, width: 18, color: barColor)],
      ));
    }

    final weekLabels = entries.map((e) {
      final dt = DateFormat('yyyy-MM-dd').parse(e.key);
      return DateFormat('E').format(dt); // Mon, Tue ...
    }).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: BarChart(
        BarChartData(
          maxY: maxY,
          minY: 0,
          barGroups: spots,
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= weekLabels.length) return const SizedBox();
                  return SideTitleWidget(child: Text(weekLabels[idx]), axisSide: meta.axisSide);
                },
                reservedSize: 28,
              ),
            ),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(show: true),
          barTouchData: BarTouchData(enabled: true),
          borderData: FlBorderData(show: false),
          extraLinesData: showTarget && target != null
              ? ExtraLinesData(horizontalLines: [
                  HorizontalLine(y: target!.toDouble(), color: Colors.redAccent, strokeWidth: 1.2, dashArray: [4, 4], label: HorizontalLineLabel(show: true, // label on right
                    alignment: Alignment.centerRight,
                    style: const TextStyle(color: Colors.red),
                    labelResolver: (line) => 'Target ${target.toString()}')),
                ])
              : ExtraLinesData(),
        ),
      ),
    );
  }
}
