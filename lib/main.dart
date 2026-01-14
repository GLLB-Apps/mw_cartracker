import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'car_tracker_page.dart';

void main() {
  runApp(const MakeWayTrackerApp());
}

class MakeWayTrackerApp extends StatefulWidget {
  const MakeWayTrackerApp({super.key});

  @override
  State<MakeWayTrackerApp> createState() => _MakeWayTrackerAppState();
}

class _MakeWayTrackerAppState extends State<MakeWayTrackerApp> {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkMode') ?? false;
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  Future<void> _toggleTheme(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDark);
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MakeWay Car Tracker',
      themeMode: _themeMode,
      theme: ThemeData(
        primaryColor: const Color(0xFF4A9FD8),
        scaffoldBackgroundColor: const Color(0xFFFFA842),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4A9FD8),
          secondary: const Color(0xFFFF6B4A),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Arial',
      ),
      darkTheme: ThemeData(
        primaryColor: const Color(0xFF5A8FAF),
        scaffoldBackgroundColor: const Color(0xFF2A2A2A),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5A8FAF),
          secondary: const Color(0xFFCC6B5A),
          brightness: Brightness.dark,
          surface: const Color(0xFF353535),
          onSurface: const Color(0xFFE0E0E0),
        ),
        cardColor: const Color(0xFF353535),
        useMaterial3: true,
        fontFamily: 'Arial',
      ),
      home: CarTrackerPage(
        onThemeChanged: _toggleTheme,
      ),
    );
  }
}