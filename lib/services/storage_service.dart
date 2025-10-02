import 'package:mongo_dart/mongo_dart.dart';
import '../models/mood_entry.dart';
import '../models/todo.dart';
import '../models/daily_review.dart';
import '../models/habit.dart';
import '../models/goal.dart';
import 'mongodb_service.dart';
import 'todo_mongodb_service.dart';
import 'daily_review_mongodb_service.dart';
import 'habit_mongodb_service.dart';
import 'goal_mongodb_service.dart';

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

  // ------------------ TODOS ------------------
  static Future<ObjectId> createTodo(Todo todo) async {
    return await TodoMongoService.createTodo(todo);
  }

  static Future<void> updateTodo(Todo todo) async {
    await TodoMongoService.updateTodo(todo);
  }

  static Future<void> deleteTodo(ObjectId id) async {
    await TodoMongoService.deleteTodo(id);
  }

  static Future<List<Todo>> getTodosForDate(DateTime date) async {
    return await TodoMongoService.getTodosForDate(date);
  }

  static Future<List<Todo>> getTodosInRange(DateTime start, DateTime end) async {
    return await TodoMongoService.getTodosInRange(start, end);
  }

  // ------------------ DAILY REVIEW ------------------
  static Future<ObjectId> saveDailyReview(DailyReview review) async {
    return await DailyReviewMongoService.saveReview(review);
  }

  static Future<DailyReview?> getDailyReview(DateTime date) async {
    return await DailyReviewMongoService.getForDate(date);
  }

  static Future<List<DailyReview>> getDailyReviewsInRange(DateTime start, DateTime end) async {
    return await DailyReviewMongoService.getInRange(start, end);
  }

  // ------------------ HABITS ------------------
  static Future<ObjectId> createHabit(Habit habit) async {
    return await HabitMongoService.createHabit(habit);
  }

  static Future<void> updateHabit(Habit habit) async {
    await HabitMongoService.updateHabit(habit);
  }

  static Future<void> deleteHabit(ObjectId id) async {
    await HabitMongoService.deleteHabit(id);
  }

  static Future<List<Habit>> getAllHabits() async {
    return await HabitMongoService.getAllHabits();
  }

  static Future<Habit?> getHabitById(ObjectId id) async {
    return await HabitMongoService.getHabitById(id);
  }

  static Future<List<Habit>> getHabitsByCategory(String category) async {
    return await HabitMongoService.getHabitsByCategory(category);
  }

  static Future<void> completeHabit(ObjectId habitId, HabitCompletion completion) async {
    await HabitMongoService.completeHabit(habitId, completion);
  }

  static Future<List<Habit>> getHabitsForDate(DateTime date) async {
    return await HabitMongoService.getHabitsForDate(date);
  }

  static Future<Map<String, dynamic>> getHabitStats() async {
    return await HabitMongoService.getHabitStats();
  }

  // ------------------ GOALS ------------------
  static Future<ObjectId> createGoal(Goal goal) async {
    return await GoalMongoService.createGoal(goal);
  }

  static Future<void> updateGoal(Goal goal) async {
    await GoalMongoService.updateGoal(goal);
  }

  static Future<void> deleteGoal(ObjectId id) async {
    await GoalMongoService.deleteGoal(id);
  }

  static Future<List<Goal>> getAllGoals() async {
    return await GoalMongoService.getAllGoals();
  }

  static Future<Goal?> getGoalById(ObjectId id) async {
    return await GoalMongoService.getGoalById(id);
  }

  static Future<List<Goal>> getGoalsByCategory(String category) async {
    return await GoalMongoService.getGoalsByCategory(category);
  }

  static Future<List<Goal>> getActiveGoals() async {
    return await GoalMongoService.getActiveGoals();
  }

  static Future<List<Goal>> getGoalsByPriority(String priority) async {
    return await GoalMongoService.getGoalsByPriority(priority);
  }

  static Future<List<Goal>> getOverdueGoals() async {
    return await GoalMongoService.getOverdueGoals();
  }

  static Future<List<Goal>> getGoalsDueSoon({int days = 7}) async {
    return await GoalMongoService.getGoalsDueSoon(days: days);
  }

  static Future<void> completeGoal(ObjectId goalId) async {
    await GoalMongoService.completeGoal(goalId);
  }

  static Future<void> updateMilestoneProgress(ObjectId goalId, int milestoneIndex, int progress) async {
    await GoalMongoService.updateMilestoneProgress(goalId, milestoneIndex, progress);
  }

  static Future<void> completeMilestone(ObjectId goalId, int milestoneIndex) async {
    await GoalMongoService.completeMilestone(goalId, milestoneIndex);
  }

  static Future<Map<String, dynamic>> getGoalStats() async {
    return await GoalMongoService.getGoalStats();
  }

  static Future<List<Goal>> searchGoals(String query) async {
    return await GoalMongoService.searchGoals(query);
  }
}
