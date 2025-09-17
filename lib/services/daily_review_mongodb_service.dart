import 'package:mongo_dart/mongo_dart.dart';
import '../models/daily_review.dart';

class DailyReviewMongoService {
  static const String _connectionString = 'mongodb+srv://bloom_user:Bloom123@cluster0.unn7b.mongodb.net/bloom_app?retryWrites=true&w=majority&appName=Cluster0';
  static const String _collectionName = 'daily_reviews';

  static Db? _db;
  static DbCollection? _collection;

  static bool _shouldReconnect(Object e) {
    final msg = e.toString();
    return msg.contains('No master connection') || msg.contains('SocketException') || msg.contains('ConnectionException');
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

  static Future<ObjectId> saveReview(DailyReview review) async {
    await _ensureInit();
    try {
      if (review.id == null) {
        final res = await _collection!.insertOne(review.toMap());
        return res.id as ObjectId;
      } else {
        await _collection!.replaceOne(where.id(review.id!), review.toMap());
        return review.id!;
      }
    } catch (e) {
      if (_shouldReconnect(e)) {
        await _reconnect();
        if (review.id == null) {
          final res = await _collection!.insertOne(review.toMap());
          return res.id as ObjectId;
        } else {
          await _collection!.replaceOne(where.id(review.id!), review.toMap());
          return review.id!;
        }
      }
      rethrow;
    }
  }

  static Future<DailyReview?> getForDate(DateTime date) async {
    await _ensureInit();
    final day = DateTime(date.year, date.month, date.day).toIso8601String().substring(0,10);
    try {
      final doc = await _collection!.findOne(where.match('date', '^$day'));
      return doc == null ? null : DailyReview.fromMap(doc);
    } catch (e) {
      if (_shouldReconnect(e)) {
        await _reconnect();
        final doc = await _collection!.findOne(where.match('date', '^$day'));
        return doc == null ? null : DailyReview.fromMap(doc);
      }
      rethrow;
    }
  }

  static Future<List<DailyReview>> getInRange(DateTime start, DateTime end) async {
    await _ensureInit();
    try {
      final docs = await _collection!
          .find(where.gte('date', start.toIso8601String()).lte('date', end.toIso8601String()))
          .toList();
      return docs.map((e) => DailyReview.fromMap(e)).toList();
    } catch (e) {
      if (_shouldReconnect(e)) {
        await _reconnect();
        final docs = await _collection!
            .find(where.gte('date', start.toIso8601String()).lte('date', end.toIso8601String()))
            .toList();
        return docs.map((e) => DailyReview.fromMap(e)).toList();
      }
      rethrow;
    }
  }
}
