import 'package:mongo_dart/mongo_dart.dart';

/// Represents a single subtask within a Todo.
class Subtask {
  final ObjectId? id;
  final String title;
  final bool isDone;

  const Subtask({
    this.id,
    required this.title,
    required this.isDone,
  });

  Subtask copyWith({
    ObjectId? id,
    String? title,
    bool? isDone,
  }) {
    return Subtask(
      id: id ?? this.id,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'title': title,
      'isDone': isDone,
    };
    if (id != null) {
      map['_id'] = id;
    }
    return map;
  }

  factory Subtask.fromMap(Map<String, dynamic> map) {
    return Subtask(
      id: map['_id'] is ObjectId ? map['_id'] as ObjectId : null,
      title: (map['title'] ?? '').toString(),
      isDone: map['isDone'] == true,
    );
  }
}

/// Represents a Todo with optional subtasks. Progress is derived from subtasks.
class Todo {
  final ObjectId? id;
  final DateTime date; // The day this todo belongs to
  final String title;
  final String? description;
  final String priority; // 'low' | 'medium' | 'high'
  final String status; // 'open' | 'in_progress' | 'done'
  final bool impactOnMood;
  final List<Subtask> subtasks;

  const Todo({
    this.id,
    required this.date,
    required this.title,
    this.description,
    this.priority = 'medium',
    this.status = 'open',
    this.impactOnMood = false,
    this.subtasks = const [],
  });

  /// Auto-calculated progress percentage based on completed subtasks.
  int get progressPercent {
    if (subtasks.isEmpty) {
      // If no subtasks, consider done only when status is done
      return status == 'done' ? 100 : 0;
    }
    final int total = subtasks.length;
    final int done = subtasks.where((s) => s.isDone).length;
    return ((done / total) * 100).round();
  }

  Todo copyWith({
    ObjectId? id,
    DateTime? date,
    String? title,
    String? description,
    String? priority,
    String? status,
    bool? impactOnMood,
    List<Subtask>? subtasks,
  }) {
    return Todo(
      id: id ?? this.id,
      date: date ?? this.date,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      impactOnMood: impactOnMood ?? this.impactOnMood,
      subtasks: subtasks ?? this.subtasks,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'date': date.toIso8601String(),
      'title': title,
      'description': description,
      'priority': priority,
      'status': status,
      'impactOnMood': impactOnMood,
      'subtasks': subtasks.map((s) => s.toMap()).toList(),
    };
    if (id != null) {
      map['_id'] = id;
    }
    return map;
  }

  factory Todo.fromMap(Map<String, dynamic> map) {
    return Todo(
      id: map['_id'] is ObjectId ? map['_id'] as ObjectId : null,
      date: DateTime.tryParse((map['date'] ?? '').toString()) ?? DateTime.now(),
      title: (map['title'] ?? '').toString(),
      description: map['description']?.toString(),
      priority: (map['priority'] ?? 'medium').toString(),
      status: (map['status'] ?? 'open').toString(),
      impactOnMood: map['impactOnMood'] == true,
      subtasks: (map['subtasks'] as List?)
              ?.map((e) => Subtask.fromMap((e as Map).cast<String, dynamic>()))
              .toList() ??
          const <Subtask>[],
    );
  }
}
