import 'package:mongo_dart/mongo_dart.dart';

class MoodEntry {
  final ObjectId? id;
  final String mood;
  final List<String> activities;
  final DateTime date;
  final String? note;

  MoodEntry({
    this.id,
    required this.mood,
    required this.activities,
    required this.date,
    this.note,
  });

  // Convert to Map for storage
  Map<String, dynamic> toMap() {
    final map = {
      'mood': mood,
      'activities': activities,
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
      activities: List<String>.from(map['activities'] ?? []),
      date: DateTime.parse(map['date']),
      note: map['note'],
    );
  }
}
