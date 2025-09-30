import 'package:mongo_dart/mongo_dart.dart';

class Habit {
  final ObjectId? id;
  final String title;
  final String description;
  final String category; // health, productivity, learning, etc.
  final int difficulty; // 1-5 scale (1=easy, 5=very hard)
  final List<String> triggers; // what triggers this habit
  final List<String> rewards; // what rewards you get
  final String frequency; // daily, weekly, custom
  final List<int> customDays; // for custom frequency (0=Sunday, 6=Saturday)
  final TimeOfDay? preferredTime; // when you prefer to do it
  final int targetStreak; // target streak length
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastCompleted;
  final int currentStreak;
  final int longestStreak;
  final List<HabitCompletion> completions; // daily completions
  final ObjectId? linkedHabitId; // for habit stacking
  final int impactOnMood; // 1-5 scale (how much this affects mood)

  Habit({
    this.id,
    required this.title,
    this.description = '',
    required this.category,
    this.difficulty = 3,
    this.triggers = const [],
    this.rewards = const [],
    this.frequency = 'daily',
    this.customDays = const [],
    this.preferredTime,
    this.targetStreak = 30,
    this.isActive = true,
    required this.createdAt,
    this.lastCompleted,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.completions = const [],
    this.linkedHabitId,
    this.impactOnMood = 3,
  });

  // Calculate completion rate for last 30 days
  double get completionRate {
    if (completions.isEmpty) return 0.0;
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final recentCompletions = completions.where((c) => c.date.isAfter(thirtyDaysAgo)).length;
    return recentCompletions / 30.0;
  }

  // Check if habit was completed today
  bool get isCompletedToday {
    final today = DateTime.now();
    return completions.any((c) => 
      c.date.year == today.year && 
      c.date.month == today.month && 
      c.date.day == today.day
    );
  }

  // Get habit status for today
  String get todayStatus {
    if (isCompletedToday) return 'completed';
    final now = DateTime.now();
    if (preferredTime != null) {
      final preferredDateTime = DateTime(now.year, now.month, now.day, 
        preferredTime!.hour, preferredTime!.minute);
      if (now.isAfter(preferredDateTime.add(const Duration(hours: 2)))) {
        return 'missed';
      }
    }
    return 'pending';
  }

  // Calculate next difficulty level
  int get nextDifficultyLevel {
    if (completionRate >= 0.9 && difficulty < 5) return difficulty + 1;
    if (completionRate < 0.5 && difficulty > 1) return difficulty - 1;
    return difficulty;
  }

  // Get motivational message based on streak
  String get motivationalMessage {
    if (currentStreak == 0) return 'Start your journey! 🌟';
    if (currentStreak < 7) return 'Building momentum! 💪';
    if (currentStreak < 30) return 'Great consistency! 🔥';
    if (currentStreak < 100) return 'Incredible dedication! 🚀';
    return 'Legendary streak! 👑';
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'difficulty': difficulty,
      'triggers': triggers,
      'rewards': rewards,
      'frequency': frequency,
      'customDays': customDays,
      'preferredTime': preferredTime != null ? {
        'hour': preferredTime!.hour,
        'minute': preferredTime!.minute,
      } : null,
      'targetStreak': targetStreak,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'lastCompleted': lastCompleted?.toIso8601String(),
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'completions': completions.map((c) => c.toMap()).toList(),
      'linkedHabitId': linkedHabitId?.toHexString(),
      'impactOnMood': impactOnMood,
      if (id != null) '_id': id,
    };
  }

  factory Habit.fromMap(Map<String, dynamic> map) {
    return Habit(
      id: map['_id'],
      title: map['title'],
      description: map['description'] ?? '',
      category: map['category'],
      difficulty: map['difficulty'] ?? 3,
      triggers: List<String>.from(map['triggers'] ?? []),
      rewards: List<String>.from(map['rewards'] ?? []),
      frequency: map['frequency'] ?? 'daily',
      customDays: List<int>.from(map['customDays'] ?? []),
      preferredTime: map['preferredTime'] != null ? TimeOfDay(
        hour: map['preferredTime']['hour'],
        minute: map['preferredTime']['minute'],
      ) : null,
      targetStreak: map['targetStreak'] ?? 30,
      isActive: map['isActive'] ?? true,
      createdAt: DateTime.parse(map['createdAt']),
      lastCompleted: map['lastCompleted'] != null ? DateTime.parse(map['lastCompleted']) : null,
      currentStreak: map['currentStreak'] ?? 0,
      longestStreak: map['longestStreak'] ?? 0,
      completions: (map['completions'] as List<dynamic>? ?? [])
          .map((c) => HabitCompletion.fromMap(c))
          .toList(),
      linkedHabitId: map['linkedHabitId'] != null ? ObjectId.fromHexString(map['linkedHabitId'] as String) : null,
      impactOnMood: map['impactOnMood'] ?? 3,
    );
  }

  Habit copyWith({
    ObjectId? id,
    String? title,
    String? description,
    String? category,
    int? difficulty,
    List<String>? triggers,
    List<String>? rewards,
    String? frequency,
    List<int>? customDays,
    TimeOfDay? preferredTime,
    int? targetStreak,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastCompleted,
    int? currentStreak,
    int? longestStreak,
    List<HabitCompletion>? completions,
    ObjectId? linkedHabitId,
    int? impactOnMood,
  }) {
    return Habit(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      triggers: triggers ?? this.triggers,
      rewards: rewards ?? this.rewards,
      frequency: frequency ?? this.frequency,
      customDays: customDays ?? this.customDays,
      preferredTime: preferredTime ?? this.preferredTime,
      targetStreak: targetStreak ?? this.targetStreak,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastCompleted: lastCompleted ?? this.lastCompleted,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      completions: completions ?? this.completions,
      linkedHabitId: linkedHabitId ?? this.linkedHabitId,
      impactOnMood: impactOnMood ?? this.impactOnMood,
    );
  }
}

class HabitCompletion {
  final ObjectId? id;
  final DateTime date;
  final String? note;
  final int moodBefore; // 1-5 scale
  final int moodAfter; // 1-5 scale
  final int energyLevel; // 1-5 scale
  final List<String> obstacles; // what got in the way
  final List<String> successes; // what went well

  HabitCompletion({
    this.id,
    required this.date,
    this.note,
    this.moodBefore = 3,
    this.moodAfter = 3,
    this.energyLevel = 3,
    this.obstacles = const [],
    this.successes = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'note': note,
      'moodBefore': moodBefore,
      'moodAfter': moodAfter,
      'energyLevel': energyLevel,
      'obstacles': obstacles,
      'successes': successes,
      if (id != null) '_id': id,
    };
  }

  factory HabitCompletion.fromMap(Map<String, dynamic> map) {
    return HabitCompletion(
      id: map['_id'],
      date: DateTime.parse(map['date']),
      note: map['note'],
      moodBefore: map['moodBefore'] ?? 3,
      moodAfter: map['moodAfter'] ?? 3,
      energyLevel: map['energyLevel'] ?? 3,
      obstacles: List<String>.from(map['obstacles'] ?? []),
      successes: List<String>.from(map['successes'] ?? []),
    );
  }

  HabitCompletion copyWith({
    ObjectId? id,
    DateTime? date,
    String? note,
    int? moodBefore,
    int? moodAfter,
    int? energyLevel,
    List<String>? obstacles,
    List<String>? successes,
  }) {
    return HabitCompletion(
      id: id ?? this.id,
      date: date ?? this.date,
      note: note ?? this.note,
      moodBefore: moodBefore ?? this.moodBefore,
      moodAfter: moodAfter ?? this.moodAfter,
      energyLevel: energyLevel ?? this.energyLevel,
      obstacles: obstacles ?? this.obstacles,
      successes: successes ?? this.successes,
    );
  }
}

class TimeOfDay {
  final int hour;
  final int minute;

  const TimeOfDay({required this.hour, required this.minute});

  @override
  String toString() {
    final hourStr = hour.toString().padLeft(2, '0');
    final minuteStr = minute.toString().padLeft(2, '0');
    return '$hourStr:$minuteStr';
  }
}
