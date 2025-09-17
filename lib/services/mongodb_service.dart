import 'package:mongo_dart/mongo_dart.dart';
import '../models/mood_entry.dart';

class MongoService {
  static const String _connectionString = 'mongodb+srv://bloom_user:Bloom123@cluster0.unn7b.mongodb.net/bloom_app?retryWrites=true&w=majority&appName=Cluster0';
  static const String _databaseName = 'bloom_app';
  static const String _collectionName = 'mood_entries';
  
  static Db? _db;
  static DbCollection? _collection;

  static Future<void> _reconnect() async {
    try {
      await _db?.close();
    } catch (_) {}
    _db = await Db.create(_connectionString);
    await _db!.open();
    _collection = _db!.collection(_collectionName);
  }

  // Initialize database connection
  static Future<void> initialize() async {
    try {
      print('=== INITIALIZING MONGODB CONNECTION ===');
      print('Connection string: $_connectionString');
      print('Database name: $_databaseName');
      print('Collection name: $_collectionName');
      
      _db = await Db.create(_connectionString);
      print('Database object created');
      
      await _db!.open();
      print('Database connection opened');
      
      _collection = _db!.collection(_collectionName);
      print('Collection reference created: $_collectionName');
      
      print('MongoDB connected successfully to bloom_app database!');
    } catch (e) {
      print('=== MONGODB CONNECTION ERROR ===');
      print('Error type: ${e.runtimeType}');
      print('Error message: $e');
      print('Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  static bool _shouldReconnect(Object e) {
    final msg = e.toString();
    return msg.contains('No master connection') ||
        msg.contains('SocketException') ||
        msg.contains('ConnectionException');
  }

  // Save mood entry
  static Future<void> saveMoodEntry(MoodEntry entry) async {
    try {
      print('=== SAVING MOOD ENTRY ===');
      print('Entry details: mood=${entry.mood}, activities=${entry.activities}, date=${entry.date}');
      
      if (_collection == null) {
        print('Collection is null, initializing...');
        await initialize();
      }
      
      final entryMap = entry.toMap();
      print('Entry map to save: $entryMap');
      
      final result = await _collection!.insertOne(entryMap);
      print('MongoDB insert result: $result');
      print('Mood entry saved successfully! Inserted ID: ${result.id}');
      
      // Verify the save by trying to read it back
      final verifyResult = await _collection!.findOne(where.eq('_id', result.id));
      print('Verification - found saved entry: $verifyResult');
      
    } catch (e) {
      if (_shouldReconnect(e)) {
        print('Reconnect needed (reason: $e). Retrying once...');
        await _reconnect();
        final result = await _collection!.insertOne(entry.toMap());
        print('Retry insert result: $result');
        return;
      }
      print('=== ERROR SAVING MOOD ENTRY ===');
      print('Error type: ${e.runtimeType}');
      print('Error message: $e');
      print('Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  // Get all mood entries
  static Future<List<MoodEntry>> getMoodEntries() async {
    try {
      if (_collection == null) await initialize();
      final cursor = await _collection!.find();
      final entries = await cursor.toList();
      
      return entries.map((doc) => MoodEntry.fromMap(doc)).toList();
    } catch (e) {
      if (_shouldReconnect(e)) {
        await _reconnect();
        final entries = await _collection!.find().toList();
        return entries.map((doc) => MoodEntry.fromMap(doc)).toList();
      }
      print('Error getting mood entries: $e');
      return [];
    }
  }

  // Get entry for specific date
  static Future<MoodEntry?> getEntryForDate(DateTime date) async {
    try {
      if (_collection == null) await initialize();
      final query = where.eq('date', date.toIso8601String());
      final entry = await _collection!.findOne(query);
      
      if (entry != null) {
        return MoodEntry.fromMap(entry);
      }
      return null;
    } catch (e) {
      if (_shouldReconnect(e)) {
        await _reconnect();
        final entry = await _collection!.findOne(where.eq('date', date.toIso8601String()));
        return entry == null ? null : MoodEntry.fromMap(entry);
      }
      print('Error getting entry for date: $e');
      return null;
    }
  }

  // Delete mood entry
  static Future<void> deleteMoodEntry(MoodEntry entry) async {
    try {
      if (_collection == null) await initialize();
      final query = where.eq('_id', entry.id);
      await _collection!.remove(query);
      print('Mood entry deleted successfully!');
    } catch (e) {
      if (_shouldReconnect(e)) {
        await _reconnect();
        await _collection!.remove(where.eq('_id', entry.id));
        return;
      }
      print('Error deleting mood entry: $e');
      rethrow;
    }
  }

  // Close connection
  static Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      print('MongoDB connection closed');
    }
  }
}
