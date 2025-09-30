import '../models/mood_entry.dart';
import '../models/habit.dart';
import '../models/todo.dart';
import '../models/daily_review.dart';

class AIInsightsService {
  static const List<String> _motivationalQuotes = [
    "Every small step counts towards your bigger goals! 🌟",
    "Your consistency is building something amazing! 💪",
    "Progress, not perfection, is the key to success! 🎯",
    "You're stronger than you think! Keep going! 🔥",
    "Every day is a new opportunity to grow! 🌱",
    "Your dedication is inspiring! Keep it up! ✨",
    "Small wins lead to big victories! 🏆",
    "You're creating positive change, one day at a time! 🌈",
  ];

  static const List<String> _moodInsights = [
    "Your mood patterns show you're most positive in the morning! ☀️",
    "Exercise seems to boost your mood significantly! 🏃‍♀️",
    "You tend to feel better after completing your habits! ✅",
    "Social activities appear to have a positive impact on you! 👥",
    "Your mood improves when you get enough sleep! 😴",
    "Meditation seems to help stabilize your emotions! 🧘‍♀️",
  ];

  static const List<String> _habitInsights = [
    "Your exercise habit has a 95% completion rate - amazing! 🏋️‍♀️",
    "Consider adding a morning routine to boost your productivity! 🌅",
    "Your meditation streak is impressive! Keep it up! 🧘‍♂️",
    "You might benefit from a bedtime routine for better sleep! 🌙",
    "Your reading habit is building great knowledge! 📚",
    "Consider linking habits together for better consistency! 🔗",
  ];

  static const List<String> _productivityInsights = [
    "You're most productive between 9-11 AM! ⏰",
    "Your completion rate increases when you break tasks into smaller steps! 📝",
    "You tend to accomplish more on days when you exercise! 🏃‍♂️",
    "Your focus improves when you limit distractions! 🎯",
    "You work better when you take regular breaks! ☕",
    "Your productivity peaks when you have a clear plan! 📋",
  ];

  static const List<String> _recommendations = [
    "Try logging your mood at the same time each day for better patterns! 📊",
    "Consider setting smaller, more achievable goals! 🎯",
    "Your sleep quality affects your mood - try a consistent bedtime! 😴",
    "Exercise in the morning might boost your entire day! 🌅",
    "Take 5 minutes to reflect on what went well each day! ✨",
    "Consider journaling about your triggers to understand them better! 📖",
  ];

  /// Generate personalized insights based on user data
  static Map<String, dynamic> generateInsights({
    required List<MoodEntry> moods,
    required List<Habit> habits,
    required List<Todo> todos,
    required List<DailyReview> reviews,
  }) {
    final insights = <String, dynamic>{};
    
    // Mood Analysis
    insights['mood'] = _analyzeMoodPatterns(moods);
    
    // Habit Analysis
    insights['habits'] = _analyzeHabitPatterns(habits);
    
    // Productivity Analysis
    insights['productivity'] = _analyzeProductivityPatterns(todos, reviews);
    
    // Personalized Recommendations
    insights['recommendations'] = _generateRecommendations(moods, habits, todos, reviews);
    
    // Motivational Content
    insights['motivation'] = _generateMotivationalContent(moods, habits, todos);
    
    return insights;
  }

  static Map<String, dynamic> _analyzeMoodPatterns(List<MoodEntry> moods) {
    if (moods.isEmpty) return {'message': 'Start logging your mood to see insights!'};
    
    final recentMoods = moods.take(7).toList();
    final avgIntensity = recentMoods.map((m) => m.intensity).reduce((a, b) => a + b) / recentMoods.length;
    
    // Find most common mood
    final moodCounts = <String, int>{};
    for (final mood in recentMoods) {
      moodCounts[mood.mood] = (moodCounts[mood.mood] ?? 0) + 1;
    }
    final dominantMood = moodCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    
    // Find common triggers
    final triggerCounts = <String, int>{};
    for (final mood in recentMoods) {
      for (final trigger in mood.triggers) {
        triggerCounts[trigger] = (triggerCounts[trigger] ?? 0) + 1;
      }
    }
    final topTriggers = triggerCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // Time-based analysis
    final morningMoods = recentMoods.where((m) => m.date.hour < 12).toList();
    final afternoonMoods = recentMoods.where((m) => m.date.hour >= 12 && m.date.hour < 18).toList();
    final eveningMoods = recentMoods.where((m) => m.date.hour >= 18).toList();
    
    String timeInsight = '';
    if (morningMoods.isNotEmpty && afternoonMoods.isNotEmpty && eveningMoods.isNotEmpty) {
      final morningAvg = morningMoods.map((m) => m.intensity).reduce((a, b) => a + b) / morningMoods.length;
      final afternoonAvg = afternoonMoods.map((m) => m.intensity).reduce((a, b) => a + b) / afternoonMoods.length;
      final eveningAvg = eveningMoods.map((m) => m.intensity).reduce((a, b) => a + b) / eveningMoods.length;
      
      if (morningAvg > afternoonAvg && morningAvg > eveningAvg) {
        timeInsight = 'You tend to feel best in the morning! ☀️';
      } else if (afternoonAvg > morningAvg && afternoonAvg > eveningAvg) {
        timeInsight = 'Your energy peaks in the afternoon! 🌤️';
      } else if (eveningAvg > morningAvg && eveningAvg > afternoonAvg) {
        timeInsight = 'You feel most positive in the evening! 🌙';
      }
    }
    
    return {
      'averageIntensity': avgIntensity.round(),
      'dominantMood': dominantMood,
      'topTriggers': topTriggers.take(3).map((e) => e.key).toList(),
      'timeInsight': timeInsight,
      'totalEntries': moods.length,
      'recentTrend': _calculateMoodTrend(recentMoods),
    };
  }

  static Map<String, dynamic> _analyzeHabitPatterns(List<Habit> habits) {
    if (habits.isEmpty) return {'message': 'Start building habits to see insights!'};
    
    final activeHabits = habits.where((h) => h.isActive).toList();
    final completedToday = activeHabits.where((h) => h.isCompletedToday).length;
    final completionRate = activeHabits.isNotEmpty ? (completedToday / activeHabits.length) * 100 : 0;
    
    // Find best performing habit
    Habit? bestHabit;
    double bestRate = 0;
    for (final habit in activeHabits) {
      if (habit.completions.length >= 7) {
        final rate = habit.completions.length / 7.0;
        if (rate > bestRate) {
          bestRate = rate;
          bestHabit = habit;
        }
      }
    }
    
    // Find struggling habits
    final strugglingHabits = activeHabits.where((h) {
      if (h.completions.length >= 7) {
        final rate = h.completions.length / 7.0;
        return rate < 0.3;
      }
      return false;
    }).toList();
    
    return {
      'totalHabits': habits.length,
      'activeHabits': activeHabits.length,
      'completedToday': completedToday,
      'completionRate': completionRate.round(),
      'bestHabit': bestHabit?.title,
      'bestHabitRate': (bestRate * 100).round(),
      'strugglingHabits': strugglingHabits.map((h) => h.title).toList(),
      'averageStreak': activeHabits.isNotEmpty 
          ? (activeHabits.map((h) => h.currentStreak).reduce((a, b) => a + b) / activeHabits.length).round()
          : 0,
    };
  }

  static Map<String, dynamic> _analyzeProductivityPatterns(List<Todo> todos, List<DailyReview> reviews) {
    if (todos.isEmpty && reviews.isEmpty) return {'message': 'Start tracking tasks to see productivity insights!'};
    
    final recentTodos = todos.where((t) => 
        DateTime.now().difference(t.date).inDays <= 7).toList();
    final completedTodos = recentTodos.where((t) => t.status == 'completed').length;
    final completionRate = recentTodos.isNotEmpty ? (completedTodos / recentTodos.length) * 100 : 0;
    
    // Analyze by priority
    final highPriorityTodos = recentTodos.where((t) => t.priority == 'high').toList();
    final highPriorityCompleted = highPriorityTodos.where((t) => t.status == 'completed').length;
    final highPriorityRate = highPriorityTodos.isNotEmpty 
        ? (highPriorityCompleted / highPriorityTodos.length) * 100 
        : 0;
    
    // Time-based productivity
    final morningTodos = recentTodos.where((t) => t.date.hour < 12).toList();
    final afternoonTodos = recentTodos.where((t) => t.date.hour >= 12 && t.date.hour < 18).toList();
    final eveningTodos = recentTodos.where((t) => t.date.hour >= 18).toList();
    
    String productiveTime = '';
    if (morningTodos.isNotEmpty && afternoonTodos.isNotEmpty && eveningTodos.isNotEmpty) {
      final morningRate = morningTodos.where((t) => t.status == 'completed').length / morningTodos.length;
      final afternoonRate = afternoonTodos.where((t) => t.status == 'completed').length / afternoonTodos.length;
      final eveningRate = eveningTodos.where((t) => t.status == 'completed').length / eveningTodos.length;
      
      if (morningRate > afternoonRate && morningRate > eveningRate) {
        productiveTime = 'You\'re most productive in the morning! 🌅';
      } else if (afternoonRate > morningRate && afternoonRate > eveningRate) {
        productiveTime = 'Your focus peaks in the afternoon! ☀️';
      } else if (eveningRate > morningRate && eveningRate > afternoonRate) {
        productiveTime = 'You get things done best in the evening! 🌙';
      }
    }
    
    return {
      'totalTasks': recentTodos.length,
      'completedTasks': completedTodos,
      'completionRate': completionRate.round(),
      'highPriorityRate': highPriorityRate.round(),
      'productiveTime': productiveTime,
      'averageTasksPerDay': recentTodos.length / 7,
    };
  }

  static List<String> _generateRecommendations(
    List<MoodEntry> moods,
    List<Habit> habits,
    List<Todo> todos,
    List<DailyReview> reviews,
  ) {
    final recommendations = <String>[];
    
    // Mood-based recommendations
    if (moods.isNotEmpty) {
      final recentMoods = moods.take(7).toList();
      final avgIntensity = recentMoods.map((m) => m.intensity).reduce((a, b) => a + b) / recentMoods.length;
      
      if (avgIntensity < 3) {
        recommendations.add('Your mood has been low recently. Consider adding more positive activities! 🌈');
      } else if (avgIntensity > 4) {
        recommendations.add('You\'ve been feeling great! Keep up the positive momentum! 🎉');
      }
    }
    
    // Habit-based recommendations
    final activeHabits = habits.where((h) => h.isActive).toList();
    if (activeHabits.length < 3) {
      recommendations.add('Consider adding 1-2 more habits to build a stronger routine! 💪');
    } else if (activeHabits.length > 7) {
      recommendations.add('You have many habits! Consider focusing on your top 5 for better consistency! 🎯');
    }
    
    // Productivity recommendations
    if (todos.isNotEmpty) {
      final recentTodos = todos.where((t) => 
          DateTime.now().difference(t.date).inDays <= 7).toList();
      final completionRate = recentTodos.where((t) => t.status == 'completed').length / recentTodos.length;
      
      if (completionRate < 0.5) {
        recommendations.add('Try breaking large tasks into smaller, manageable steps! 📝');
      }
    }
    
    // Add random recommendations if we don't have enough
    while (recommendations.length < 3) {
      final randomRec = _recommendations[recommendations.length % _recommendations.length];
      if (!recommendations.contains(randomRec)) {
        recommendations.add(randomRec);
      } else {
        break;
      }
    }
    
    return recommendations.take(3).toList();
  }

  static Map<String, dynamic> _generateMotivationalContent(
    List<MoodEntry> moods,
    List<Habit> habits,
    List<Todo> todos,
  ) {
    final content = <String, dynamic>{};
    
    // Generate personalized quote
    content['quote'] = _motivationalQuotes[DateTime.now().day % _motivationalQuotes.length];
    
    // Generate achievement message
    final completedHabits = habits.where((h) => h.isCompletedToday).length;
    final completedTodos = todos.where((t) => 
        t.date.day == DateTime.now().day && t.status == 'completed').length;
    
    if (completedHabits > 0 || completedTodos > 0) {
      content['achievement'] = 'Great job! You completed $completedHabits habits and $completedTodos tasks today! 🎉';
    } else {
      content['achievement'] = 'Ready to make today amazing? Start with one small step! 🌟';
    }
    
    // Generate streak motivation
    final longestStreak = habits.isNotEmpty 
        ? habits.map((h) => h.longestStreak).reduce((a, b) => a > b ? a : b)
        : 0;
    
    if (longestStreak > 7) {
      content['streakMotivation'] = 'Your longest streak is $longestStreak days - that\'s incredible! 🔥';
    } else if (longestStreak > 0) {
      content['streakMotivation'] = 'You\'re building momentum with a $longestStreak day streak! 💪';
    } else {
      content['streakMotivation'] = 'Every journey begins with a single step! 🌱';
    }
    
    return content;
  }

  static String _calculateMoodTrend(List<MoodEntry> recentMoods) {
    if (recentMoods.length < 2) return 'stable';
    
    final firstHalf = recentMoods.take(recentMoods.length ~/ 2).toList();
    final secondHalf = recentMoods.skip(recentMoods.length ~/ 2).toList();
    
    final firstAvg = firstHalf.map((m) => m.intensity).reduce((a, b) => a + b) / firstHalf.length;
    final secondAvg = secondHalf.map((m) => m.intensity).reduce((a, b) => a + b) / secondHalf.length;
    
    if (secondAvg > firstAvg + 0.5) return 'improving';
    if (secondAvg < firstAvg - 0.5) return 'declining';
    return 'stable';
  }
}
