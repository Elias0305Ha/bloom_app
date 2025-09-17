import 'package:mongo_dart/mongo_dart.dart';

class MoodEntry {
  final ObjectId? id;
  final String mood;
  final int intensity; // 1–10 scale
  final List<String> activities;
  final List<String> triggers;
  final DateTime date;
  final String? note;

  MoodEntry({
    this.id,
    required this.mood,
    this.intensity = 5,
    required this.activities,
    this.triggers = const [],
    required this.date,
    this.note,
  });

  // Convert to Map for storage
  Map<String, dynamic> toMap() {
    final map = {
      'mood': mood,
      'intensity': intensity,
      'activities': activities,
      'triggers': triggers,
      'date': date.toIso8601String(),
      'note': note,
    };
    if (id != null) {
      map['_id'] = id;
    }
    return map;
  }

  // Create from Map (for loading from storage)
  factory MoodEntry.fromMap(Map<String, dynamic> map) {
    return MoodEntry(
      id: map['_id'],
      mood: map['mood'],
      intensity: (map['intensity'] is int)
          ? map['intensity'] as int
          : int.tryParse('${map['intensity']}') ?? 5,
      activities: List<String>.from(map['activities'] ?? []),
      triggers: List<String>.from(map['triggers'] ?? []),
      date: DateTime.parse(map['date']),
      note: map['note'],
    );
  }
}
