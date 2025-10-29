// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

// existing app controllers / screens
import 'package:dailysync/controllers/theme_controller.dart';
import 'package:dailysync/views/splash_screen.dart';

// Health manager imports
import 'health_manager/controllers/health_controller.dart';
import 'health_manager/views/health_home.dart';

// --- NEW Routine Manager Import ---
import 'routine_manager/controllers/routine_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize & prepare the health controller
  final healthController = HealthController();
  await healthController.init();

  // --- NEW: Initialize & prepare the routine controller ---
  final routineController = RoutineController();
  await routineController.init();

  // Initialize Firebase (keep your existing config)
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyBpr_LhYBMH1NPVvHkNuoJ775Wtw4NORAY",
      appId: "1:184902571321:android:d9d124a16e2c97b51f84e8",
      messagingSenderId: "184902571321",
      projectId: "dailysync-9f0e8",
    ),
  );

  // Initialize theme controller
  final themeController = ThemeController();

  runApp(
    MultiProvider(
      providers: [
        // Use the existing instance of HealthController so there's only one.
        ChangeNotifierProvider<HealthController>.value(value: healthController),
        
        // --- NEW: Add the RoutineController ---
        ChangeNotifierProvider<RoutineController>.value(value: routineController),
        
        ChangeNotifierProvider<ThemeController>.value(value: themeController),
        // Keep other providers here if you have them
      ],
      child: const HealthApp(), // Renamed from DailySyncApp to HealthApp
    ),
  );
}

class HealthApp extends StatelessWidget { // Renamed from DailySyncApp
  const HealthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeController>(
      builder: (context, themeNotifier, child) {
        return MaterialApp(
          title: 'DailySync', // Changed title back
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: Brightness.light,
            primarySwatch: Colors.teal,
            scaffoldBackgroundColor: const Color(0xFFF5F5F5),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFFF5F5F5),
              foregroundColor: Colors.black,
              elevation: 0,
            ),
            fontFamily: 'Roboto',
            cardTheme: CardTheme(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: Colors.white,
            ),
            chipTheme: ChipThemeData(backgroundColor: Colors.teal.withOpacity(0.1), labelStyle: TextStyle(color: Colors.teal[800])),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primarySwatch: Colors.teal,
            scaffoldBackgroundColor: const Color(0xFF121212),
            cardTheme: CardTheme(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: const Color(0xFF1E1E1E),
            ),
            appBarTheme: const AppBarTheme(elevation: 0, backgroundColor: Color(0xFF121212)),
            chipTheme: ChipThemeData(backgroundColor: Colors.teal.withOpacity(0.2), labelStyle: const TextStyle(color: Colors.tealAccent)),
            fontFamily: 'Roboto',
          ),
          themeMode: themeNotifier.themeMode,
          home: const SplashScreen(),

          routes: {
            '/health': (_) => const HealthHome(),
            // add other app routes here as needed
          },
        );
      },
    );
  }
}
