import 'package:flutter/material.dart';
import 'services/notification_service.dart';
import 'screens/home_page.dart';
import 'screens/daily_hub_page.dart';
import 'screens/timeline_page.dart';
import 'screens/weekly_review_page.dart';
import 'screens/goals_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bloom - Emotional Growth Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const RootNav(),
    );
  }
}

class RootNav extends StatefulWidget {
  const RootNav({super.key});

  @override
  State<RootNav> createState() => _RootNavState();
}

class _RootNavState extends State<RootNav> {
  int _idx = 0;
  final _pages = const [
    HomePage(),
    DailyHubPage(),
    TimelinePage(),
    WeeklyReviewPage(),
    GoalsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_idx],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _idx,
        onDestinationSelected: (i) => setState(() => _idx = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.calendar_today_outlined), selectedIcon: Icon(Icons.calendar_today), label: 'Hub'),
          NavigationDestination(icon: Icon(Icons.history), label: 'Timeline'),
          NavigationDestination(icon: Icon(Icons.analytics), label: 'Weekly'),
          NavigationDestination(icon: Icon(Icons.flag_outlined), selectedIcon: Icon(Icons.flag), label: 'Goals'),
        ],
      ),
    );
  }
}