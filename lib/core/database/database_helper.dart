import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'time_register.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create settings table
    await db.execute('''
      CREATE TABLE settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        hourly_rate REAL NOT NULL DEFAULT 0.0
      )
    ''');

    // Create work_entries table
    await db.execute('''
      CREATE TABLE work_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT NOT NULL,
        lunch_taken INTEGER NOT NULL DEFAULT 0,
        total_hours REAL NOT NULL,
        hourly_rate REAL NOT NULL,
        earnings REAL NOT NULL,
        is_paid INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    // Insert default settings
    await db.insert('settings', {'hourly_rate': 14.0});
  }

  // Settings operations
  Future<double> getHourlyRate() async {
    final db = await database;
    final result = await db.query('settings', limit: 1);
    if (result.isNotEmpty) {
      return result.first['hourly_rate'] as double;
    }
    return 14.0; // Default rate
  }

  Future<void> updateHourlyRate(double rate) async {
    final db = await database;
    await db.update(
      'settings',
      {'hourly_rate': rate},
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  // Work entries operations
  Future<int> insertWorkEntry(Map<String, dynamic> entry) async {
    final db = await database;
    return await db.insert('work_entries', entry);
  }

  Future<List<Map<String, dynamic>>> getWorkEntries() async {
    final db = await database;
    return await db.query('work_entries', orderBy: 'date DESC, created_at DESC');
  }

  Future<List<Map<String, dynamic>>> getWorkEntriesForWeek(DateTime weekStart) async {
    final db = await database;
    final weekEnd = weekStart.add(const Duration(days: 6));
    final startStr = weekStart.toIso8601String().substring(0, 10);
    final endStr = weekEnd.toIso8601String().substring(0, 10);

    return await db.query(
      'work_entries',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [startStr, endStr],
      orderBy: 'date ASC',
    );
  }

  Future<int> updateWorkEntry(int id, Map<String, dynamic> entry) async {
    final db = await database;
    return await db.update(
      'work_entries',
      entry,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteWorkEntry(int id) async {
    final db = await database;
    return await db.delete(
      'work_entries',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markEntryAsPaid(int id, bool isPaid) async {
    final db = await database;
    await db.update(
      'work_entries',
      {'is_paid': isPaid ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}