import 'package:flutter/material.dart';

import 'overview_screen.dart';
import 'exercise_screen.dart';
import 'nutrition_screen.dart';
import 'wellness_screen.dart';

// This widget is now designed to be a "page" inside another Scaffold.
class HealthManagerHome extends StatelessWidget {
  const HealthManagerHome({super.key});

  @override
  Widget build(BuildContext context) {
    // It returns a DefaultTabController and its contents directly,
    // WITHOUT a Scaffold or an AppBar.
    return DefaultTabController(
      length: 4,
      child: Column(
        children: <Widget>[
          // The TabBar now acts as a secondary header within the page.
          Container(
             // Adding a background color to the TabBar container to make it
             // visually distinct, matching the theme.
            color: Theme.of(context).appBarTheme.backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
            child: TabBar(
              labelColor: Colors.teal,
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: Colors.teal,
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Exercise'),
                Tab(text: 'Nutrition'),
                Tab(text: 'Wellness'),
              ],
            ),
          ),

          // The Expanded widget makes the TabBarView fill the remaining space.
          const Expanded(
            child: TabBarView(
              children: [
                OverviewScreen(),
                ExerciseScreen(),
                NutritionScreen(),
                WellnessScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

