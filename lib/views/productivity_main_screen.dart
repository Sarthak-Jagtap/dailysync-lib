import 'dart:async';
import 'package:flutter/material.dart';
// Note: This uses fl_chart, which is already a dependency in your pubspec.yaml.
import 'package:fl_chart/fl_chart.dart'; 

class ProductivityMainScreen extends StatefulWidget {
  const ProductivityMainScreen({super.key});

  @override
  State<ProductivityMainScreen> createState() => _ProductivityMainScreenState();
}

class _ProductivityMainScreenState extends State<ProductivityMainScreen> {
  // Pomodoro Timer State
  static const int _focusDuration = 25; // in minutes
  static const int _breakDuration = 5;  // in minutes
  int _currentDurationInSeconds = _focusDuration * 60;
  Timer? _timer;
  bool _isRunning = false;
  bool _isFocusMode = true; // true for focus, false for break
  int _pomodoroCount = 0; // Pomodoros completed

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startStopTimer() {
    if (_isRunning) {
      _timer?.cancel();
      setState(() => _isRunning = false);
    } else {
      _startTimer();
    }
  }

  void _startTimer() {
    setState(() => _isRunning = true);
    
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_currentDurationInSeconds > 0) {
        setState(() => _currentDurationInSeconds--);
      } else {
        _timer?.cancel();
        _sessionComplete();
      }
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _isFocusMode = true;
      _currentDurationInSeconds = _focusDuration * 60;
    });
  }

  void _sessionComplete() {
    if (_isFocusMode) {
      // Focus session done, start break
      setState(() {
        _isFocusMode = false;
        _pomodoroCount++;
        _currentDurationInSeconds = _breakDuration * 60;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Focus Complete! Take a break.')),
      );
    } else {
      // Break session done, go back to focus
      setState(() {
        _isFocusMode = true;
        _currentDurationInSeconds = _focusDuration * 60;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Break Complete! Start your next focus session.')),
      );
    }
    _startTimer();
  }

  String _formatDuration() {
    final minutes = (_currentDurationInSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_currentDurationInSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Productivity Manager'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Pomodoro Timer Card ---
            _buildPomodoroTimer(isDark),
            const SizedBox(height: 24),

            // --- Productivity Charts Section ---
            Text(
              'Weekly Focus & Flow',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildWeeklyChartCard(isDark),
            const SizedBox(height: 24),

            // --- Stats & Achievements ---
            _buildStatsGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildPomodoroTimer(bool isDark) {
    final Color timerColor = _isFocusMode ? Colors.redAccent : Colors.teal;
    final double progress = (_isFocusMode ? _currentDurationInSeconds / (_focusDuration * 60) : _currentDurationInSeconds / (_breakDuration * 60));

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              _isFocusMode ? 'FOCUS TIME' : 'BREAK TIME',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: timerColor),
            ),
            const SizedBox(height: 20),
            
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 180,
                  width: 180,
                  child: CircularProgressIndicator(
                    value: 1.0 - progress,
                    strokeWidth: 10,
                    backgroundColor: timerColor.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(timerColor),
                  ),
                ),
                Text(
                  _formatDuration(),
                  style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(_isRunning ? Icons.pause_circle_filled : Icons.play_circle_filled),
                  iconSize: 60,
                  color: timerColor,
                  onPressed: _startStopTimer,
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.stop_circle_outlined),
                  iconSize: 60,
                  color: Colors.grey,
                  onPressed: _resetTimer,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Pomodoros Completed: $_pomodoroCount',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyChartCard(bool isDark) {
    // Mock data for weekly focus time (hours)
    final List<double> weeklyData = [4.5, 6.0, 5.2, 7.5, 6.8, 3.0, 0.0];
    const List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: 8, // Max daily working hours
              barTouchData: BarTouchData(enabled: false),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return Padding(padding: const EdgeInsets.only(top: 8.0), child: Text(days[value.toInt()]));
                    },
                    reservedSize: 30,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return Text('${value.toInt()}h', style: TextStyle(fontSize: 10));
                    },
                    interval: 2,
                    reservedSize: 30,
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                    strokeWidth: 1,
                  );
                },
              ),
              borderData: FlBorderData(
                show: true,
                border: Border(
                  bottom: BorderSide(color: isDark ? Colors.white : Colors.black, width: 1),
                  left: BorderSide(color: isDark ? Colors.white : Colors.black, width: 1),
                ),
              ),
              barGroups: weeklyData.asMap().entries.map((entry) {
                return BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    BarChartRodData(
                      toY: entry.value,
                      color: Colors.blueAccent.shade400,
                      width: 16,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(5),
                        topRight: Radius.circular(5),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Productivity Insights',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 2.5,
          children: const [
            _StatTile(
              label: 'Total Focus Time',
              value: '33.0h',
              icon: Icons.access_time_filled,
              color: Colors.blue,
            ),
            _StatTile(
              label: 'Avg. Daily Focus',
              value: '5.5h',
              icon: Icons.timer_sharp,
              color: Colors.purple,
            ),
            _StatTile(
              label: 'Pomodoros Done',
              value: '42',
              icon: Icons.check_circle_outline,
              color: Colors.red,
            ),
            _StatTile(
              label: 'Avg. Task Completion',
              value: '85%',
              icon: Icons.trending_up,
              color: Colors.green,
            ),
          ],
        ),
      ],
    );
  }
}

// Helper Widget for Stats
class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}