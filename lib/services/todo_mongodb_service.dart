import 'package:mongo_dart/mongo_dart.dart';
import '../models/todo.dart';

class TodoMongoService {
  static const String _connectionString = 'mongodb+srv://bloom_user:Bloom123@cluster0.unn7b.mongodb.net/bloom_app?retryWrites=true&w=majority&appName=Cluster0';
  static const String _databaseName = 'bloom_app';
  static const String _collectionName = 'todos';

  static Db? _db;
  static DbCollection? _collection;

  static Future<void> _ensureInit() async {
    if (_collection != null) return;
    _db = await Db.create(_connectionString);
    await _db!.open();
    _collection = _db!.collection(_collectionName);
  }

  static Future<ObjectId> createTodo(Todo todo) async {
    await _ensureInit();
    final map = todo.toMap();
    final result = await _collection!.insertOne(map);
    return result.id as ObjectId;
  }

  static Future<void> updateTodo(Todo todo) async {
    if (todo.id == null) {
      throw ArgumentError('Todo id is required for update');
    }
    await _ensureInit();
    await _collection!.replaceOne(where.id(todo.id!), todo.toMap());
  }

  static Future<void> deleteTodo(ObjectId id) async {
    await _ensureInit();
    await _collection!.remove(where.id(id));
  }

  static Future<List<Todo>> getTodosForDate(DateTime date) async {
    await _ensureInit();
    // Match by day-only (YYYY-MM-DD) prefix of ISO string
    final dayIsoPrefix = DateTime(date.year, date.month, date.day).toIso8601String().substring(0, 10);
    final cursor = await _collection!.find(where.match('date', '^$dayIsoPrefix'));
    final docs = await cursor.toList();
    return docs.map((e) => Todo.fromMap(e)).toList();
  }

  static Future<List<Todo>> getTodosInRange(DateTime start, DateTime end) async {
    await _ensureInit();
    final cursor = await _collection!.find(where.gte('date', start.toIso8601String()).lte('date', end.toIso8601String()));
    final docs = await cursor.toList();
    return docs.map((e) => Todo.fromMap(e)).toList();
  }

  static Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
      _collection = null;
    }
  }
}
