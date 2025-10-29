// [MODIFIED FILE: lib/view/home_screen.dart]

import 'package:dailysync/views/dashboard.dart';
import 'package:dailysync/health_manager/views/health_home.dart';
// [NEW IMPORTS]
import 'package:dailysync/routine_manager/views/routine_main_screen.dart'; // <--- UPDATED
import 'package:dailysync/views/productivity_main_screen.dart'; 

import 'package:dailysync/controllers/theme_controller.dart';
import 'package:dailysync/views/todo_main.dart';
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
    _pages = [
      const HomeDashboard(), // Dashboard summary
      const HealthHome(), // Health component
      const Center(child: Text("Finance Screen")), // Your Expense/Finance Manager Placeholder
      const ProductivityMainScreen(), 
      const TodoMain(),
      const RoutineMainScreen(), // <--- MODIFIED TO USE NEW SCREEN
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
        // Ensure the title reflects the current screen
        title: Text(_getAppBarTitle(_selectedIndex)), 
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),

      // The main body of the screen, which changes based on the selected tab
      // Use an IndexedStack to preserve the state of each tab
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),


      // Your bottom navigation bar remains the same
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: isDark ? Colors.white54 : Colors.grey[600],
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: "Health"),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: "Finance"),
          BottomNavigationBarItem(icon: Icon(Icons.trending_up), label: "Productivity"),
          BottomNavigationBarItem(icon: Icon(Icons.check_circle), label: "To-Do"),
          BottomNavigationBarItem(icon: Icon(Icons.access_time), label: "Routine"),
        ],
      ),

 
    );
  }

  // Helper method to dynamically change the AppBar title
  String _getAppBarTitle(int index) {
    switch (index) {
      case 0: return "Dashboard";
      case 1: return "Health Manager";
      case 2: return "Finance Manager";
      case 3: return "Productivity Manager";
      case 4: return "To-Do List";
      case 5: return "Routine Manager";
      default: return "DailySync";
    }
  }
}
