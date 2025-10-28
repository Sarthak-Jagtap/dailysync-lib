import 'package:dailysync/views/finance_summary_card.dart';
import 'package:dailysync/views/health_summary_card.dart';
import 'package:dailysync/views/routine_summary_card.dart';
import 'package:dailysync/views/todolist_summary_card.dart';
import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  // Mock Data (In a real app, this would come from a provider/API)
  final double _waterLevel = 0.65;
  final int _caloriesConsumed = 1500;
  final int _caloriesTarget = 2200;
  final double _sleepHours = 7.0;
  final double _sleepTarget = 8.0;
  final int _stepsCount = 7850;
  final int _stepsTarget = 10000;


  // Helper for the dynamic status bar
  String getDailyStatus() {
    final calProgress = (_caloriesConsumed / _caloriesTarget);
    final waterProgress = _waterLevel;
    final sleepProgress = (_sleepHours / _sleepTarget);
    
    if (calProgress >= 1.0) return "🎉 Calorie Goal Achieved!";
    if (waterProgress >= 1.0) return "💧 Perfectly Hydrated!";
    if (sleepProgress >= 1.0) return "😴 Sleep Target Met!";
    
    if (calProgress > 0.8) return "Almost There! Keep Going...";
    return ""; 
  }

  Widget greetingSection(BuildContext context) {
    const String username = "Alex"; 
    final hour = DateTime.now().hour;
    String greeting =
        hour < 12
            ? "Good Morning"
            : hour < 17
            ? "Good Afternoon"
            : "Good Evening";

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.blueAccent.withOpacity(0.2),
            child: const Icon(Icons.person, size: 30, color: Colors.blueAccent),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "$greeting 👋",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "Hello, $username!",
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Status Bar Widget
    final String statusMessage = getDailyStatus();
    Widget statusBar = statusMessage.isNotEmpty
        ? SizedBox(
            height: 30,
            child: AnimatedTextKit(
              key: ValueKey(statusMessage),
              repeatForever: true,
              animatedTexts: [
                FlickerAnimatedText(
                  statusMessage,
                  textStyle: TextStyle(
                    fontSize: 18.0, 
                    fontWeight: FontWeight.w800, 
                    color: statusMessage.contains('Achieved') || statusMessage.contains('Perfectly') || statusMessage.contains('Met')
                      ? Colors.green[700]!
                      : Colors.blueGrey[800]!,
                  ),
                  speed: const Duration(milliseconds: 3000),
                ),
              ],
            ),
          )
        : const SizedBox.shrink(); 

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            greetingSection(context),

            statusBar,
            if (statusMessage.isNotEmpty) const SizedBox(height: 16.0),

            // HEALTH SUMMARY CARD
            CombinedHealthSummaryCard(
              waterLevel: _waterLevel,
              caloriesConsumed: _caloriesConsumed,
              caloriesTarget: _caloriesTarget,
              stepsCount: _stepsCount,
              stepsTarget: _stepsTarget,
            ),
            
            const SizedBox(height: 20),

            // TO-DO SUMMARY CARD
            const TodoSummaryCard(),

            const SizedBox(height: 20),
            
            // ROUTINE SUMMARY CARD
            const RoutineSummaryCard(),
            
            const SizedBox(height: 20),

            // FINANCE SUMMARY CARD (Calling Concept 1: Circular)
            const FinanceSummaryCardCircular(),

            const SizedBox(height: 20),

            // Secondary Summary Cards (Keeping your original 'Routine' placeholder, now 'Sleep Goal')
            SummaryCard(
              title: "Sleep Goal", // Renamed from Routine to Sleep Goal
              subtitle: "${_sleepHours.toStringAsFixed(1)} / ${_sleepTarget.toStringAsFixed(1)} hours",
              icon: Icons.access_time,
              color: Colors.pinkAccent,
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }
}

// Keeping the original SummaryCard class for secondary metrics
class SummaryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isDark;

  const SummaryCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isDark ? Colors.grey[850] : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: isDark ? Colors.white70 : Colors.grey[700]),
        ),
      ),
    );
  }
}
