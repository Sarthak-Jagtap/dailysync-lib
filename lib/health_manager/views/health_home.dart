// lib/health_manager/views/health_home.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/health_controller.dart';
import 'water_screen.dart';
import 'diet_screen.dart';
import 'steps_screen.dart';
import 'history_screen.dart';

class HealthHome extends StatelessWidget {
  const HealthHome({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: Provider.of<HealthController>(context, listen: false),
      child: const HealthTabs(),
    );
  }
}

class HealthTabs extends StatefulWidget {
  const HealthTabs({super.key});
  @override
  State<HealthTabs> createState() => _HealthTabsState();
}

class _HealthTabsState extends State<HealthTabs> {
  int _index = 0;
  final _pages = const [
    WaterScreen(),
    DietScreen(),
    StepsScreen(),
    HistoryScreen(),
  ];

  final _titles = const ['Water', 'Diet', 'Steps', 'History'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Health Manager - ${_titles[_index]}'),
        backgroundColor: Colors.indigo,
      ),
      body: _pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey[600],
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.local_drink), label: 'Water'),
          BottomNavigationBarItem(icon: Icon(Icons.food_bank), label: 'Diet'),
          BottomNavigationBarItem(icon: Icon(Icons.directions_walk), label: 'Steps'),
          BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: 'History'),
        ],
      ),
    );
  }
}
