// [MODIFIED FILE: lib/views/home_screen.dart]

import 'package:dailysync/routine_manager/views/routine_main_screen.dart';
import 'package:dailysync/views/dashboard.dart';
import 'package:dailysync/health_manager/views/health_home.dart';
// Import the Finance Home Screen
import 'package:dailysync/finance_manager/views/finance_home_screen.dart'; // <--- ADD THIS
import 'package:dailysync/todo_manager/views/todo_main_screen.dart'; // <--- Ensure correct path

import 'package:dailysync/controllers/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'profile_screen.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _pages;
  @override
  void initState() {
    super.initState();
    // Update _pages list - Finance now points to FinanceHomeScreen
    _pages = [
      const HomeDashboard(),         // Index 0
      const HealthHome(),            // Index 1
      const FinanceHomeScreen(),     // Index 2  <--- MODIFIED HERE
      // const ProductivityMainScreen(),
      const TodoMainScreen(),        // Index 3
      const RoutineMainScreen(),     // Index 4
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {

    final themeProvider = Provider.of<ThemeController>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        // Ensure the title reflects the current *main* screen/module
        title: Text(_getAppBarTitle(_selectedIndex)), // <--- Uses updated helper
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: "Profile", // Add tooltip
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
        ],
        // Note: The TabBar for Finance will appear below this AppBar
        // when the Finance tab is selected.
      ),

      // The main body of the screen, which changes based on the selected tab
      body: IndexedStack( // Use IndexedStack to keep state of main pages
         index: _selectedIndex,
         children: _pages,
       ),

      // Your bottom navigation bar - Updated items
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Good for many items
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: isDark ? Colors.white54 : Colors.grey[600],
        items: const [
          // Updated Items - Removed specific Expenses/Reports
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.favorite_outline), activeIcon: Icon(Icons.favorite), label: "Health"),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_outlined), activeIcon: Icon(Icons.account_balance_wallet), label: "Finance"), // Keep Finance module entry
          // BottomNavigationBarItem(icon: Icon(Icons.trending_up), activeIcon: Icon(Icons.show_chart), label: "Productivity"), // Example icons
          BottomNavigationBarItem(icon: Icon(Icons.check_circle_outline), activeIcon: Icon(Icons.check_circle), label: "To-Do"),
          BottomNavigationBarItem(icon: Icon(Icons.access_time_outlined), activeIcon: Icon(Icons.access_time_filled), label: "Routine"),
        ],
      ),
    );
  }

  // Helper method to dynamically change the Main AppBar title
  String _getAppBarTitle(int index) {
    switch (index) {
      case 0: return "Dashboard";
      case 1: return "Health Manager";
      case 2: return "Finance Manager"; // Updated Title
      // case 3: return "Productivity";    // Simplified Title
      case 3: return "To-Do List";
      case 4: return "Routine";         // Simplified Title
      default: return "DailySync";
    }
  }
}