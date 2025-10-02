import 'package:mongo_dart/mongo_dart.dart';

class GoalMilestone {
  final String title;
  final String description;
  final DateTime targetDate;
  final bool isCompleted;
  final DateTime? completedDate;
  final List<String> tasks; // Associated tasks
  final int progress; // 0-100

  GoalMilestone({
    required this.title,
    this.description = '',
    required this.targetDate,
    this.isCompleted = false,
    this.completedDate,
    this.tasks = const [],
    this.progress = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'targetDate': targetDate.toIso8601String(),
      'isCompleted': isCompleted,
      'completedDate': completedDate?.toIso8601String(),
      'tasks': tasks,
      'progress': progress,
    };
  }

  factory GoalMilestone.fromMap(Map<String, dynamic> map) {
    return GoalMilestone(
      title: map['title'],
      description: map['description'] ?? '',
      targetDate: DateTime.parse(map['targetDate']),
      isCompleted: map['isCompleted'] ?? false,
      completedDate: map['completedDate'] != null ? DateTime.parse(map['completedDate']) : null,
      tasks: List<String>.from(map['tasks'] ?? []),
      progress: map['progress'] ?? 0,
    );
  }

  GoalMilestone copyWith({
    String? title,
    String? description,
    DateTime? targetDate,
    bool? isCompleted,
    DateTime? completedDate,
    List<String>? tasks,
    int? progress,
  }) {
    return GoalMilestone(
      title: title ?? this.title,
      description: description ?? this.description,
      targetDate: targetDate ?? this.targetDate,
      isCompleted: isCompleted ?? this.isCompleted,
      completedDate: completedDate ?? this.completedDate,
      tasks: tasks ?? this.tasks,
      progress: progress ?? this.progress,
    );
  }
}

class Goal {
  final ObjectId? id;
  final String title;
  final String description;
  final String category; // personal, career, health, learning, etc.
  final String priority; // high, medium, low
  final DateTime startDate;
  final DateTime targetDate;
  final DateTime? completedDate;
  final String status; // active, completed, paused, cancelled
  final List<GoalMilestone> milestones;
  final List<String> tags;
  final String motivation; // Why this goal matters
  final List<String> obstacles; // Potential challenges
  final List<String> resources; // What you need to succeed
  final int impactOnMood; // 1-5 scale
  final bool isPublic; // For future social features
  final DateTime createdAt;
  final DateTime updatedAt;

  Goal({
    this.id,
    required this.title,
    this.description = '',
    required this.category,
    this.priority = 'medium',
    required this.startDate,
    required this.targetDate,
    this.completedDate,
    this.status = 'active',
    this.milestones = const [],
    this.tags = const [],
    this.motivation = '',
    this.obstacles = const [],
    this.resources = const [],
    this.impactOnMood = 3,
    this.isPublic = false,
    required this.createdAt,
    required this.updatedAt,
  });

  // Calculate overall progress based on milestones
  int get overallProgress {
    if (milestones.isEmpty) return 0;
    final totalProgress = milestones.fold(0, (sum, milestone) => sum + milestone.progress);
    return (totalProgress / milestones.length).round();
  }

  // Get days remaining until target date
  int get daysRemaining {
    final now = DateTime.now();
    final difference = targetDate.difference(now).inDays;
    return difference > 0 ? difference : 0;
  }

  // Check if goal is overdue
  bool get isOverdue {
    return DateTime.now().isAfter(targetDate) && status != 'completed';
  }

  // Get next milestone
  GoalMilestone? get nextMilestone {
    final incompleteMilestones = milestones.where((m) => !m.isCompleted).toList();
    if (incompleteMilestones.isEmpty) return null;
    
    incompleteMilestones.sort((a, b) => a.targetDate.compareTo(b.targetDate));
    return incompleteMilestones.first;
  }

  // Get completed milestones count
  int get completedMilestonesCount {
    return milestones.where((m) => m.isCompleted).length;
  }

  // Get total milestones count
  int get totalMilestonesCount {
    return milestones.length;
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'priority': priority,
      'startDate': startDate.toIso8601String(),
      'targetDate': targetDate.toIso8601String(),
      'completedDate': completedDate?.toIso8601String(),
      'status': status,
      'milestones': milestones.map((m) => m.toMap()).toList(),
      'tags': tags,
      'motivation': motivation,
      'obstacles': obstacles,
      'resources': resources,
      'impactOnMood': impactOnMood,
      'isPublic': isPublic,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Goal.fromMap(Map<String, dynamic> map) {
    return Goal(
      id: map['_id'],
      title: map['title'],
      description: map['description'] ?? '',
      category: map['category'],
      priority: map['priority'] ?? 'medium',
      startDate: DateTime.parse(map['startDate']),
      targetDate: DateTime.parse(map['targetDate']),
      completedDate: map['completedDate'] != null ? DateTime.parse(map['completedDate']) : null,
      status: map['status'] ?? 'active',
      milestones: (map['milestones'] as List<dynamic>?)
          ?.map((m) => GoalMilestone.fromMap(m as Map<String, dynamic>))
          .toList() ?? const [],
      tags: List<String>.from(map['tags'] ?? []),
      motivation: map['motivation'] ?? '',
      obstacles: List<String>.from(map['obstacles'] ?? []),
      resources: List<String>.from(map['resources'] ?? []),
      impactOnMood: map['impactOnMood'] ?? 3,
      isPublic: map['isPublic'] ?? false,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  Goal copyWith({
    ObjectId? id,
    String? title,
    String? description,
    String? category,
    String? priority,
    DateTime? startDate,
    DateTime? targetDate,
    DateTime? completedDate,
    String? status,
    List<GoalMilestone>? milestones,
    List<String>? tags,
    String? motivation,
    List<String>? obstacles,
    List<String>? resources,
    int? impactOnMood,
    bool? isPublic,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Goal(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      startDate: startDate ?? this.startDate,
      targetDate: targetDate ?? this.targetDate,
      completedDate: completedDate ?? this.completedDate,
      status: status ?? this.status,
      milestones: milestones ?? this.milestones,
      tags: tags ?? this.tags,
      motivation: motivation ?? this.motivation,
      obstacles: obstacles ?? this.obstacles,
      resources: resources ?? this.resources,
      impactOnMood: impactOnMood ?? this.impactOnMood,
      isPublic: isPublic ?? this.isPublic,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
