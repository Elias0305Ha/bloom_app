import 'package:mongo_dart/mongo_dart.dart';
import '../models/habit.dart';

class HabitMongoService {
  static Db? _db;
  static DbCollection? _collection;
  
  static const String _connectionString = 'mongodb+srv://bloom_user:Bloom123@cluster0.unn7b.mongodb.net/bloom_app?retryWrites=true&w=majority&appName=Cluster0';
  static const String _databaseName = 'bloom_app';
  static const String _collectionName = 'habits';

  static Future<void> initialize() async {
    try {
      print('=== INITIALIZING HABIT MONGODB CONNECTION ===');
      _db = await Db.create(_connectionString);
      await _db!.open();
      _collection = _db!.collection(_collectionName);
      print('Habit MongoDB connected successfully to $_databaseName database!');
    } catch (e) {
      print('Habit MongoDB connection error: $e');
      // Retry once
      try {
        await Future.delayed(const Duration(seconds: 2));
        _db = await Db.create(_connectionString);
        await _db!.open();
        _collection = _db!.collection(_collectionName);
        print('Habit MongoDB reconnected successfully!');
      } catch (retryError) {
        print('Habit MongoDB retry failed: $retryError');
        rethrow;
      }
    }
  }

  static Future<ObjectId> createHabit(Habit habit) async {
    try {
      if (_collection == null) await initialize();
      
      final habitMap = habit.toMap();
      final result = await _collection!.insertOne(habitMap);
      print('Habit created successfully! ID: ${result.id}');
      return result.id as ObjectId;
    } catch (e) {
      print('Error creating habit: $e');
      // Retry once
      try {
        await initialize();
        final habitMap = habit.toMap();
        final result = await _collection!.insertOne(habitMap);
        print('Habit created successfully on retry! ID: ${result.id}');
        return result.id as ObjectId;
      } catch (retryError) {
        print('Error creating habit on retry: $retryError');
        rethrow;
      }
    }
  }

  static Future<void> updateHabit(Habit habit) async {
    try {
      if (_collection == null) await initialize();
      if (habit.id == null) throw Exception('Habit ID is required for update');
      
      final habitMap = habit.toMap();
      await _collection!.updateOne(
        where.eq('_id', habit.id),
        modify.set('title', habitMap['title'])
            .set('description', habitMap['description'])
            .set('category', habitMap['category'])
            .set('difficulty', habitMap['difficulty'])
            .set('triggers', habitMap['triggers'])
            .set('rewards', habitMap['rewards'])
            .set('frequency', habitMap['frequency'])
            .set('customDays', habitMap['customDays'])
            .set('preferredTime', habitMap['preferredTime'])
            .set('targetStreak', habitMap['targetStreak'])
            .set('isActive', habitMap['isActive'])
            .set('lastCompleted', habitMap['lastCompleted'])
            .set('currentStreak', habitMap['currentStreak'])
            .set('longestStreak', habitMap['longestStreak'])
            .set('completions', habitMap['completions'])
            .set('linkedHabitId', habitMap['linkedHabitId'])
            .set('impactOnMood', habitMap['impactOnMood'])
      );
      print('Habit updated successfully!');
    } catch (e) {
      print('Error updating habit: $e');
      // Retry once
      try {
        await initialize();
        if (habit.id == null) throw Exception('Habit ID is required for update');
        
        final habitMap = habit.toMap();
        await _collection!.updateOne(
          where.eq('_id', habit.id),
          modify.set('title', habitMap['title'])
              .set('description', habitMap['description'])
              .set('category', habitMap['category'])
              .set('difficulty', habitMap['difficulty'])
              .set('triggers', habitMap['triggers'])
              .set('rewards', habitMap['rewards'])
              .set('frequency', habitMap['frequency'])
              .set('customDays', habitMap['customDays'])
              .set('preferredTime', habitMap['preferredTime'])
              .set('targetStreak', habitMap['targetStreak'])
              .set('isActive', habitMap['isActive'])
              .set('lastCompleted', habitMap['lastCompleted'])
              .set('currentStreak', habitMap['currentStreak'])
              .set('longestStreak', habitMap['longestStreak'])
              .set('completions', habitMap['completions'])
              .set('linkedHabitId', habitMap['linkedHabitId'])
              .set('impactOnMood', habitMap['impactOnMood'])
        );
        print('Habit updated successfully on retry!');
      } catch (retryError) {
        print('Error updating habit on retry: $retryError');
        rethrow;
      }
    }
  }

  static Future<void> deleteHabit(ObjectId id) async {
    try {
      if (_collection == null) await initialize();
      
      await _collection!.deleteOne(where.eq('_id', id));
      print('Habit deleted successfully!');
    } catch (e) {
      print('Error deleting habit: $e');
      // Retry once
      try {
        await initialize();
        await _collection!.deleteOne(where.eq('_id', id));
        print('Habit deleted successfully on retry!');
      } catch (retryError) {
        print('Error deleting habit on retry: $retryError');
        rethrow;
      }
    }
  }

  static Future<List<Habit>> getAllHabits() async {
    try {
      if (_collection == null) await initialize();
      
      final cursor = await _collection!.find(where.eq('isActive', true));
      final habits = await cursor.toList();
      print('Retrieved ${habits.length} habits');
      return habits.map((h) => Habit.fromMap(h)).toList();
    } catch (e) {
      print('Error getting habits: $e');
      // Retry once
      try {
        await initialize();
        final cursor = await _collection!.find(where.eq('isActive', true));
        final habits = await cursor.toList();
        print('Retrieved ${habits.length} habits on retry');
        return habits.map((h) => Habit.fromMap(h)).toList();
      } catch (retryError) {
        print('Error getting habits on retry: $retryError');
        return [];
      }
    }
  }

  static Future<Habit?> getHabitById(ObjectId id) async {
    try {
      if (_collection == null) await initialize();
      
      final habit = await _collection!.findOne(where.eq('_id', id));
      if (habit != null) {
        return Habit.fromMap(habit);
      }
      return null;
    } catch (e) {
      print('Error getting habit by ID: $e');
      return null;
    }
  }

  static Future<List<Habit>> getHabitsByCategory(String category) async {
    try {
      if (_collection == null) await initialize();
      
      final cursor = await _collection!.find(
        where.eq('isActive', true).eq('category', category)
      );
      final habits = await cursor.toList();
      return habits.map((h) => Habit.fromMap(h)).toList();
    } catch (e) {
      print('Error getting habits by category: $e');
      return [];
    }
  }

  static Future<void> completeHabit(ObjectId habitId, HabitCompletion completion) async {
    try {
      if (_collection == null) await initialize();
      
      final habit = await getHabitById(habitId);
      if (habit == null) throw Exception('Habit not found');
      
      // Add completion to habit
      final updatedCompletions = [...habit.completions, completion];
      
      // Calculate new streak
      int newStreak = habit.currentStreak;
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));
      
      // Check if habit was completed yesterday
      final wasCompletedYesterday = updatedCompletions.any((c) => 
        c.date.year == yesterday.year && 
        c.date.month == yesterday.month && 
        c.date.day == yesterday.day
      );
      
      if (wasCompletedYesterday) {
        newStreak++;
      } else {
        newStreak = 1; // Reset streak
      }
      
      // Update longest streak
      final newLongestStreak = newStreak > habit.longestStreak ? newStreak : habit.longestStreak;
      
      // Update habit
      final updatedHabit = habit.copyWith(
        completions: updatedCompletions,
        currentStreak: newStreak,
        longestStreak: newLongestStreak,
        lastCompleted: today,
      );
      
      await updateHabit(updatedHabit);
      print('Habit completed successfully! New streak: $newStreak');
    } catch (e) {
      print('Error completing habit: $e');
      rethrow;
    }
  }

  static Future<List<Habit>> getHabitsForDate(DateTime date) async {
    try {
      final allHabits = await getAllHabits();
      return allHabits.where((habit) {
        // Check if habit should be done on this date based on frequency
        switch (habit.frequency) {
          case 'daily':
            return true;
          case 'weekly':
            return date.weekday == 1; // Monday
          case 'custom':
            return habit.customDays.contains(date.weekday % 7);
          default:
            return true;
        }
      }).toList();
    } catch (e) {
      print('Error getting habits for date: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> getHabitStats() async {
    try {
      final habits = await getAllHabits();
      
      int totalHabits = habits.length;
      int activeHabits = habits.where((h) => h.isActive).length;
      int completedToday = habits.where((h) => h.isCompletedToday).length;
      
      double avgCompletionRate = habits.isEmpty ? 0.0 : 
        habits.map((h) => h.completionRate).reduce((a, b) => a + b) / habits.length;
      
      int totalStreaks = habits.map((h) => h.currentStreak).reduce((a, b) => a + b);
      int longestStreak = habits.isEmpty ? 0 : 
        habits.map((h) => h.longestStreak).reduce((a, b) => a > b ? a : b);
      
      return {
        'totalHabits': totalHabits,
        'activeHabits': activeHabits,
        'completedToday': completedToday,
        'avgCompletionRate': avgCompletionRate,
        'totalStreaks': totalStreaks,
        'longestStreak': longestStreak,
      };
    } catch (e) {
      print('Error getting habit stats: $e');
      return {
        'totalHabits': 0,
        'activeHabits': 0,
        'completedToday': 0,
        'avgCompletionRate': 0.0,
        'totalStreaks': 0,
        'longestStreak': 0,
      };
    }
  }
}
