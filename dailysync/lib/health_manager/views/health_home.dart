// lib/health_manager/views/health_home.dart
import 'package:flutter/material.dart';
import 'water_screen.dart';
import 'diet_screen.dart';
import 'steps_screen.dart';
import 'sleep_screen.dart'; // Import Sleep Screen

class HealthHome extends StatelessWidget {
  const HealthHome({super.key});

  @override
  Widget build(BuildContext context) {
    // No need to create a new provider here if one is already provided higher up the tree
    // Just ensure HealthController is available via Provider
    return const HealthTabs();
  }
}

class HealthTabs extends StatefulWidget {
  const HealthTabs({super.key});
  @override
  State<HealthTabs> createState() => _HealthTabsState();
}

class _HealthTabsState extends State<HealthTabs> with SingleTickerProviderStateMixin { // Added TickerProvider
  late TabController _tabController;

  final _pages = const [
    WaterScreen(),
    DietScreen(),
    StepsScreen(),
    SleepScreen(), // Added SleepScreen
  ];

  final _tabs = const [
    Tab(icon: Icon(Icons.local_drink), text: 'Water'),
    Tab(icon: Icon(Icons.food_bank_outlined), text: 'Diet'), // Changed icon
    Tab(icon: Icon(Icons.directions_walk), text: 'Steps'),
    Tab(icon: Icon(Icons.bedtime_outlined), text: 'Sleep'), // Added Sleep Tab
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

   @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
     final Color primaryColor = Colors.green.shade700;
     final Color indicatorColor = Colors.green.shade100; // Lighter color for indicator
     final Color labelColor = Colors.white;
     final Color unselectedLabelColor = Colors.white.withOpacity(0.7);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Don't show back button if nested
        backgroundColor: primaryColor,
        elevation: 0, // Remove shadow
        // title: null, // Removed title
        // toolbarHeight: kTextTabBarHeight, // Set height to match TabBar - causes layout issues
        bottom: PreferredSize( // Use PreferredSize to control height explicitly
            preferredSize: const Size.fromHeight(kToolbarHeight), // Standard AppBar height for the TabBar
            child: Container( // Container to allow background color for TabBar area
                 color: primaryColor, // Match AppBar color
                 child: TabBar(
                   controller: _tabController,
                   tabs: _tabs,
                   indicatorColor: indicatorColor,
                   indicatorWeight: 3.0,
                   labelColor: labelColor,
                   unselectedLabelColor: unselectedLabelColor,
                   labelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600), // Adjust font size if needed
                   unselectedLabelStyle: const TextStyle(fontSize: 10),
                 ),
            ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _pages,
      ),
      // Removed BottomNavigationBar
    );
  }
}

