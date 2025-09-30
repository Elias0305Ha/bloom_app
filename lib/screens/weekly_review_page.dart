import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/mood_entry.dart';
import '../models/todo.dart';
import '../services/storage_service.dart';

class WeeklyReviewPage extends StatefulWidget {
  const WeeklyReviewPage({super.key});

  @override
  State<WeeklyReviewPage> createState() => _WeeklyReviewPageState();
}

class _WeeklyReviewPageState extends State<WeeklyReviewPage> {
  List<MoodEntry> _weeklyEntries = [];
  List<Todo> _weeklyTodos = [];
  bool _isLoading = true;
  DateTime _currentWeekStart = DateTime.now();

  @override
  void initState() {
    super.initState();
    _initializeCurrentWeek();
    _loadWeeklyData();
  }

  void _initializeCurrentWeek() {
    final now = DateTime.now();
    _currentWeekStart = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
  }

  Future<void> _loadWeeklyData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final allEntries = await StorageService.getMoodEntries();
      final weekEnd = _currentWeekStart.add(const Duration(days: 6));

      _weeklyEntries = allEntries.where((entry) {
        return entry.date.isAfter(_currentWeekStart.subtract(const Duration(days: 1))) &&
               entry.date.isBefore(weekEnd.add(const Duration(days: 1)));
      }).toList();

      _weeklyTodos = await StorageService.getTodosInRange(_currentWeekStart, weekEnd);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading weekly data: $e');
    }
  }

  void _goToPreviousWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.subtract(const Duration(days: 7));
    });
    _loadWeeklyData();
  }

  void _goToNextWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.add(const Duration(days: 7));
    });
    _loadWeeklyData();
  }

  void _goToCurrentWeek() {
    _initializeCurrentWeek();
    _loadWeeklyData();
  }

  String _getWeekDisplayText() {
    final weekEnd = _currentWeekStart.add(const Duration(days: 6));
    final now = DateTime.now();
    final currentWeekStart = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    
    final isCurrentWeek = _currentWeekStart.isAtSameMomentAs(currentWeekStart);
    final prefix = isCurrentWeek ? "This Week" : "Week of";
    
    return "$prefix ${_currentWeekStart.day}/${_currentWeekStart.month} - ${weekEnd.day}/${weekEnd.month}";
  }

  bool _isCurrentWeek() {
    final now = DateTime.now();
    final currentWeekStart = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    return _currentWeekStart.isAtSameMomentAs(currentWeekStart);
  }

  Widget _buildWeekCard(DateTime weekStart, String label) {
    final weekEnd = weekStart.add(const Duration(days: 6));
    final isCurrentWeek = _isCurrentWeek() && weekStart.isAtSameMomentAs(_currentWeekStart);
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentWeekStart = weekStart;
        });
        _loadWeeklyData();
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isCurrentWeek ? Colors.green.shade100 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCurrentWeek ? Colors.green : Colors.grey.shade300,
            width: isCurrentWeek ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isCurrentWeek ? Colors.green.shade800 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${weekStart.day}/${weekStart.month}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isCurrentWeek ? Colors.green.shade800 : Colors.black87,
              ),
            ),
            Text(
              'to ${weekEnd.day}/${weekEnd.month}',
              style: TextStyle(
                fontSize: 10,
                color: isCurrentWeek ? Colors.green.shade600 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentWeekCard() {
    final weekEnd = _currentWeekStart.add(const Duration(days: 6));
    final isCurrentWeek = _isCurrentWeek();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrentWeek ? Colors.green.shade100 : Colors.blue.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentWeek ? Colors.green : Colors.blue,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Text(
            isCurrentWeek ? 'This Week' : 'Selected Week',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isCurrentWeek ? Colors.green.shade800 : Colors.blue.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_currentWeekStart.day}/${_currentWeekStart.month} - ${weekEnd.day}/${weekEnd.month}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isCurrentWeek ? Colors.green.shade800 : Colors.blue.shade800,
            ),
          ),
          Text(
            '${_currentWeekStart.year}',
            style: TextStyle(
              fontSize: 12,
              color: isCurrentWeek ? Colors.green.shade600 : Colors.blue.shade600,
            ),
          ),
        ],
      ),
    );
  }

  void _showWeekPicker() {
    showDatePicker(
      context: context,
      initialDate: _currentWeekStart,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    ).then((selectedDate) {
      if (selectedDate != null) {
        // Calculate the week start for the selected date
        final weekStart = DateTime(selectedDate.year, selectedDate.month, selectedDate.day)
            .subtract(Duration(days: selectedDate.weekday - 1));
        setState(() {
          _currentWeekStart = weekStart;
        });
        _loadWeeklyData();
      }
    });
  }

  Map<String, int> _getMoodDistribution() {
    Map<String, int> distribution = {};
    for (var entry in _weeklyEntries) {
      distribution[entry.mood] = (distribution[entry.mood] ?? 0) + 1;
    }
    return distribution;
  }

  List<String> _getAllActivities() {
    Set<String> activities = {};
    for (var entry in _weeklyEntries) {
      activities.addAll(entry.activities);
    }
    return activities.toList();
  }

  Map<String, int> _getActivityCounts() {
    Map<String, int> counts = {};
    for (var entry in _weeklyEntries) {
      for (var activity in entry.activities) {
        counts[activity] = (counts[activity] ?? 0) + 1;
      }
    }
    return counts;
  }

  String _getMostCommonMood() {
    final distribution = _getMoodDistribution();
    if (distribution.isEmpty) return 'No data';
    
    String mostCommon = distribution.keys.first;
    int maxCount = distribution[mostCommon]!;
    
    for (var entry in distribution.entries) {
      if (entry.value > maxCount) {
        mostCommon = entry.key;
        maxCount = entry.value;
      }
    }
    
    return mostCommon;
  }

  String _getMoodEmoji(String mood) {
    switch (mood) {
      case 'Happy': return '😊';
      case 'Sad': return '😔';
      case 'Angry': return '😡';
      case 'Calm': return '😌';
      case 'Tired': return '😴';
      default: return '😊';
    }
  }

  List<double> _dailyTodoCompletionPercents() {
    // Build map date->list of todos
    Map<String, List<Todo>> byDay = {};
    for (final t in _weeklyTodos) {
      final key = DateTime(t.date.year, t.date.month, t.date.day).toIso8601String().substring(0, 10);
      (byDay[key] = byDay[key] ?? []).add(t);
    }
    final now = DateTime.now();
    final weekStart = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    List<double> values = [];
    for (int i = 0; i < 7; i++) {
      final d = weekStart.add(Duration(days: i));
      final key = d.toIso8601String().substring(0, 10);
      final todos = byDay[key] ?? const [];
      if (todos.isEmpty) {
        values.add(0);
        continue;
      }
      int sum = 0;
      for (final t in todos) {
        sum += t.progressPercent; // derived
      }
      values.add(sum / todos.length.toDouble());
    }
    return values;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final moodDistribution = _getMoodDistribution();
    final activityCounts = _getActivityCounts();
    final mostCommonMood = _getMostCommonMood();
    final completion = _dailyTodoCompletionPercents();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Review'),
        backgroundColor: Colors.green.shade100,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadWeeklyData,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Week Selector Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Select Week',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (!_isCurrentWeek())
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              'Past Week',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange.shade800,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Week Navigation
                    Row(
                      children: [
                        Expanded(
                          child: _buildWeekCard(_currentWeekStart.subtract(const Duration(days: 7)), 'Previous'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: _buildCurrentWeekCard(),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildWeekCard(_currentWeekStart.add(const Duration(days: 7)), 'Next'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Quick Jump Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _goToCurrentWeek,
                            icon: const Icon(Icons.today, size: 18),
                            label: const Text('Current Week'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _showWeekPicker,
                            icon: const Icon(Icons.calendar_month, size: 18),
                            label: const Text('Pick Week'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Week Summary Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Week Summary',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Entries',
                            '${_weeklyEntries.length}',
                            Icons.calendar_today,
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            'Most Common Mood',
                            mostCommonMood == 'No data' ? 'N/A' : '${_getMoodEmoji(mostCommonMood)} $mostCommonMood',
                            Icons.mood,
                            Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Activities Logged',
                            '${activityCounts.length}',
                            Icons.checklist,
                            Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            'Total Activities',
                            '${activityCounts.values.fold(0, (sum, count) => sum + count)}',
                            Icons.trending_up,
                            Colors.purple,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Mood Distribution Chart
            if (moodDistribution.isNotEmpty) ...[
              Text(
                'Mood Distribution',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    height: 200,
                    child: PieChart(
                      PieChartData(
                        sections: moodDistribution.entries.map((entry) {
                          final colors = [
                            Colors.green,
                            Colors.blue,
                            Colors.red,
                            Colors.orange,
                            Colors.purple,
                          ];
                          final colorIndex = moodDistribution.keys.toList().indexOf(entry.key);
                          return PieChartSectionData(
                            color: colors[colorIndex % colors.length],
                            value: entry.value.toDouble(),
                            title: '${_getMoodEmoji(entry.key)}\n${entry.value}',
                            radius: 60,
                            titleStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        }).toList(),
                        centerSpaceRadius: 40,
                        sectionsSpace: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Weekly completion bar chart
            if (completion.isNotEmpty) ...[
              Text(
                'Todo Completion % (This Week)',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    height: 200,
                    child: BarChart(
                      BarChartData(
                        borderData: FlBorderData(show: false),
                        gridData: FlGridData(show: false),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28, interval: 25)),
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                const labels = ['M','T','W','T','F','S','S'];
                                return Text(labels[value.toInt().clamp(0,6)]);
                              },
                            ),
                          ),
                        ),
                        barGroups: List.generate(7, (i) {
                          final v = i < completion.length ? completion[i] : 0.0;
                          return BarChartGroupData(x: i, barRods: [
                            BarChartRodData(toY: v.clamp(0, 100), color: Colors.green, width: 18, borderRadius: BorderRadius.circular(4)),
                          ]);
                        }),
                        maxY: 100,
                      ),
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Activity Breakdown
            if (activityCounts.isNotEmpty) ...[
              Text(
                'Activity Breakdown',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: activityCounts.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(entry.key),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text('${entry.value}'),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],

            // Empty State
            if (_weeklyEntries.isEmpty)
              Center(
                child: Column(
                  children: [
                    const SizedBox(height: 50),
                    Icon(
                      Icons.analytics_outlined,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No data for this week',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Start logging your moods and activities to see insights!',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
