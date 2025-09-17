import '../models/mood_entry.dart';
import 'mongodb_service.dart';

class StorageService {
  // Save a mood entry
  static Future<void> saveMoodEntry(MoodEntry entry) async {
    await MongoService.saveMoodEntry(entry);
  }

  // Get all mood entries
  static Future<List<MoodEntry>> getMoodEntries() async {
    return await MongoService.getMoodEntries();
  }

  // Get entries for a specific date
  static Future<MoodEntry?> getEntryForDate(DateTime date) async {
    return await MongoService.getEntryForDate(date);
  }

  // Delete mood entry
  static Future<void> deleteMoodEntry(MoodEntry entry) async {
    await MongoService.deleteMoodEntry(entry);
  }
}
