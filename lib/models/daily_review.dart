import 'package:mongo_dart/mongo_dart.dart';

class DailyReview {
  final ObjectId? id;
  final DateTime date;
  final int completionPercent; // 0-100
  final String? wentWell;
  final String? improve;

  const DailyReview({
    this.id,
    required this.date,
    required this.completionPercent,
    this.wentWell,
    this.improve,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'date': date.toIso8601String(),
      'completionPercent': completionPercent,
      'wentWell': wentWell,
      'improve': improve,
    };
    if (id != null) map['_id'] = id;
    return map;
  }

  factory DailyReview.fromMap(Map<String, dynamic> map) {
    return DailyReview(
      id: map['_id'] is ObjectId ? map['_id'] as ObjectId : null,
      date: DateTime.tryParse('${map['date']}') ?? DateTime.now(),
      completionPercent: map['completionPercent'] is int
          ? map['completionPercent'] as int
          : int.tryParse('${map['completionPercent']}') ?? 0,
      wentWell: map['wentWell']?.toString(),
      improve: map['improve']?.toString(),
    );
  }
}
