import 'package:dailysync/models/achievement_model.dart';
import 'package:flutter/material.dart';


class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample data - you can replace this with data from a database
    final List<Achievement> achievements = [
      Achievement(title: 'First Steps', description: 'Complete your first workout.', icon: Icons.directions_run, isUnlocked: true),
      Achievement(title: 'Perfect Week', description: 'Meet all your goals for 7 consecutive days.', icon: Icons.star, isUnlocked: true),
      Achievement(title: 'Early Bird', description: 'Log an activity before 7 AM.', icon: Icons.wb_sunny, isUnlocked: false),
      Achievement(title: 'Marathoner', description: 'Run a total of 42 kilometers.', icon: Icons.emoji_events, isUnlocked: true),
      Achievement(title: 'Hydration Hero', description: 'Drink 2 liters of water for 3 straight days.', icon: Icons.local_drink, isUnlocked: false),
      Achievement(title: 'Night Owl', description: 'Achieve 8 hours of sleep.', icon: Icons.bedtime, isUnlocked: true),
    ];

    final unlockedAchievements = achievements.where((a) => a.isUnlocked).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Achievements'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'All'),
              Tab(text: 'Unlocked'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildAchievementList(achievements),
            _buildAchievementList(unlockedAchievements),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementList(List<Achievement> achievements) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        final achievement = achievements[index];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: achievement.isUnlocked ? Colors.green.withOpacity(0.08) : Theme.of(context).cardColor,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: achievement.isUnlocked ? Colors.green : Colors.grey.shade400,
              foregroundColor: Colors.white,
              child: Icon(achievement.icon),
            ),
            title: Text(
              achievement.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: achievement.isUnlocked ? Colors.green.shade800 : null,
              ),
            ),
            subtitle: Text(achievement.description),
            trailing: achievement.isUnlocked
                ? const Icon(Icons.check_circle, color: Colors.green)
                : const Icon(Icons.lock, color: Colors.grey),
          ),
        );
      },
    );
  }
}

