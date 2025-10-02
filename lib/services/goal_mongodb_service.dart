import 'package:mongo_dart/mongo_dart.dart';
import '../models/goal.dart';

class GoalMongoService {
  static const String _connectionString = 'mongodb+srv://bloom_user:Bloom123@cluster0.unn7b.mongodb.net/bloom_app?retryWrites=true&w=majority&appName=Cluster0';
  static const String _databaseName = 'bloom_app';
  static const String _collectionName = 'goals';

  static Db? _db;
  static DbCollection? _collection;

  static bool _shouldReconnect(Object e) {
    final msg = e.toString();
    return msg.contains('No master connection') ||
        msg.contains('SocketException') ||
        msg.contains('ConnectionException');
  }

  static Future<void> _ensureInit() async {
    if (_collection != null) return;
    _db = await Db.create(_connectionString);
    await _db!.open();
    _collection = _db!.collection(_collectionName);
  }

  static Future<void> _reconnect() async {
    try { await _db?.close(); } catch (_) {}
    _db = await Db.create(_connectionString);
    await _db!.open();
    _collection = _db!.collection(_collectionName);
  }

  static Future<ObjectId> createGoal(Goal goal) async {
    await _ensureInit();
    final result = await _collection!.insertOne(goal.toMap());
    if (result.isSuccess && result.id != null) {
      print('Goal created successfully: ${result.id}');
      return result.id!;
    } else {
      print('Failed to create goal: ${result.errmsg}');
      throw Exception('Failed to create goal');
    }
  }

  static Future<void> updateGoal(Goal goal) async {
    await _ensureInit();
    if (goal.id == null) {
      throw Exception('Goal ID cannot be null for update operation.');
    }
    
    final updatedGoal = goal.copyWith(updatedAt: DateTime.now());
    final result = await _collection!.replaceOne(
      where.id(goal.id!),
      updatedGoal.toMap(),
    );
    if (result.isSuccess) {
      print('Goal updated successfully: ${goal.id}');
    } else {
      print('Failed to update goal: ${result.errmsg}');
      throw Exception('Failed to update goal');
    }
  }

  static Future<void> deleteGoal(ObjectId id) async {
    await _ensureInit();
    final result = await _collection!.deleteOne(where.id(id));
    if (result.isSuccess) {
      print('Goal deleted successfully: $id');
    } else {
      print('Failed to delete goal: ${result.errmsg}');
      throw Exception('Failed to delete goal');
    }
  }

  static Future<List<Goal>> getAllGoals() async {
    await _ensureInit();
    final goals = await _collection!.find().toList();
    return goals.map((json) => Goal.fromMap(json)).toList();
  }

  static Future<Goal?> getGoalById(ObjectId id) async {
    await _ensureInit();
    final json = await _collection!.findOne(where.id(id));
    return json != null ? Goal.fromMap(json) : null;
  }

  static Future<List<Goal>> getGoalsByCategory(String category) async {
    await _ensureInit();
    final goals = await _collection!.find(where.eq('category', category)).toList();
    return goals.map((json) => Goal.fromMap(json)).toList();
  }

  static Future<List<Goal>> getActiveGoals() async {
    await _ensureInit();
    final goals = await _collection!.find(where.eq('status', 'active')).toList();
    return goals.map((json) => Goal.fromMap(json)).toList();
  }

  static Future<List<Goal>> getGoalsByPriority(String priority) async {
    await _ensureInit();
    final goals = await _collection!.find(where.eq('priority', priority)).toList();
    return goals.map((json) => Goal.fromMap(json)).toList();
  }

  static Future<List<Goal>> getOverdueGoals() async {
    await _ensureInit();
    final now = DateTime.now();
    final goals = await _collection!.find(
      where.eq('status', 'active').and(where.lt('targetDate', now.toIso8601String()))
    ).toList();
    return goals.map((json) => Goal.fromMap(json)).toList();
  }

  static Future<List<Goal>> getGoalsDueSoon({int days = 7}) async {
    await _ensureInit();
    final now = DateTime.now();
    final soonDate = now.add(Duration(days: days));
    final goals = await _collection!.find(
      where.eq('status', 'active')
        .and(where.gte('targetDate', now.toIso8601String()))
        .and(where.lte('targetDate', soonDate.toIso8601String()))
    ).toList();
    return goals.map((json) => Goal.fromMap(json)).toList();
  }

  static Future<void> completeGoal(ObjectId goalId) async {
    await _ensureInit();
    final goal = await getGoalById(goalId);
    if (goal == null) {
      throw Exception('Goal not found with ID: $goalId');
    }

    final updatedGoal = goal.copyWith(
      status: 'completed',
      completedDate: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await updateGoal(updatedGoal);
    print('Goal completed successfully: $goalId');
  }

  static Future<void> updateMilestoneProgress(ObjectId goalId, int milestoneIndex, int progress) async {
    await _ensureInit();
    final goal = await getGoalById(goalId);
    if (goal == null) {
      throw Exception('Goal not found with ID: $goalId');
    }

    if (milestoneIndex >= goal.milestones.length) {
      throw Exception('Milestone index out of range');
    }

    final updatedMilestones = List<GoalMilestone>.from(goal.milestones);
    updatedMilestones[milestoneIndex] = updatedMilestones[milestoneIndex].copyWith(progress: progress);
    
    final updatedGoal = goal.copyWith(
      milestones: updatedMilestones,
      updatedAt: DateTime.now(),
    );
    await updateGoal(updatedGoal);
    print('Milestone progress updated successfully');
  }

  static Future<void> completeMilestone(ObjectId goalId, int milestoneIndex) async {
    await _ensureInit();
    final goal = await getGoalById(goalId);
    if (goal == null) {
      throw Exception('Goal not found with ID: $goalId');
    }

    if (milestoneIndex >= goal.milestones.length) {
      throw Exception('Milestone index out of range');
    }

    final updatedMilestones = List<GoalMilestone>.from(goal.milestones);
    updatedMilestones[milestoneIndex] = updatedMilestones[milestoneIndex].copyWith(
      isCompleted: true,
      completedDate: DateTime.now(),
      progress: 100,
    );
    
    final updatedGoal = goal.copyWith(
      milestones: updatedMilestones,
      updatedAt: DateTime.now(),
    );
    await updateGoal(updatedGoal);
    print('Milestone completed successfully');
  }

  static Future<Map<String, dynamic>> getGoalStats() async {
    await _ensureInit();
    final allGoals = await getAllGoals();
    
    int totalGoals = allGoals.length;
    int activeGoals = allGoals.where((g) => g.status == 'active').length;
    int completedGoals = allGoals.where((g) => g.status == 'completed').length;
    int overdueGoals = allGoals.where((g) => g.isOverdue).length;
    int dueSoonGoals = allGoals.where((g) => g.daysRemaining <= 7 && g.status == 'active').length;
    
    double averageProgress = 0;
    if (activeGoals > 0) {
      final activeGoalsList = allGoals.where((g) => g.status == 'active').toList();
      averageProgress = activeGoalsList.fold(0.0, (sum, goal) => sum + goal.overallProgress) / activeGoalsList.length;
    }

    return {
      'totalGoals': totalGoals,
      'activeGoals': activeGoals,
      'completedGoals': completedGoals,
      'overdueGoals': overdueGoals,
      'dueSoonGoals': dueSoonGoals,
      'averageProgress': averageProgress.round(),
    };
  }

  static Future<List<Goal>> searchGoals(String query) async {
    await _ensureInit();
    // Simple text search - MongoDB regex might not be available in this version
    final allGoals = await getAllGoals();
    final lowercaseQuery = query.toLowerCase();
    
    return allGoals.where((goal) {
      return goal.title.toLowerCase().contains(lowercaseQuery) ||
             goal.description.toLowerCase().contains(lowercaseQuery) ||
             goal.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery));
    }).toList();
  }
}
