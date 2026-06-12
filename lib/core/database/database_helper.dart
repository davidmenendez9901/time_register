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
      version: 6,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create settings table
    await db.execute('''
      CREATE TABLE settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        hourly_rate REAL NOT NULL DEFAULT 0.0,
        theme_mode TEXT NOT NULL DEFAULT 'system',
        app_palette TEXT NOT NULL DEFAULT 'Blue',
        currency_symbol TEXT NOT NULL DEFAULT '\$',
        active_shift_start TEXT
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
        created_at TEXT NOT NULL,
        lunch_start_time TEXT,
        lunch_end_time TEXT,
        description TEXT
      )
    ''');

    // Insert default settings
    await db.insert('settings', {
      'hourly_rate': 14.0,
      'theme_mode': 'system',
      'app_palette': 'Blue',
      'currency_symbol': '\$',
    });
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add theme_mode column to settings table
      await db.execute('''
        ALTER TABLE settings ADD COLUMN theme_mode TEXT NOT NULL DEFAULT 'system'
      ''');
    }
    if (oldVersion < 3) {
      // Add app_palette column to settings table
      await db.execute('''
        ALTER TABLE settings ADD COLUMN app_palette TEXT NOT NULL DEFAULT 'Blue'
      ''');
    }
    if (oldVersion < 4) {
      // Add lunch start/end and description columns to work_entries table
      await db.execute(
        'ALTER TABLE work_entries ADD COLUMN lunch_start_time TEXT',
      );
      await db.execute(
        'ALTER TABLE work_entries ADD COLUMN lunch_end_time TEXT',
      );
      await db.execute('ALTER TABLE work_entries ADD COLUMN description TEXT');
    }
    if (oldVersion < 5) {
      // Add currency_symbol column to settings table
      await db.execute(
        "ALTER TABLE settings ADD COLUMN currency_symbol TEXT NOT NULL DEFAULT '\$'",
      );
    }
    if (oldVersion < 6) {
      // Track the start of a running shift (clock in/out)
      await db.execute(
        'ALTER TABLE settings ADD COLUMN active_shift_start TEXT',
      );
    }
  }

  // Settings operations
  Future<Map<String, dynamic>> getSettings() async {
    final db = await database;
    final result = await db.query('settings', limit: 1);
    if (result.isNotEmpty) {
      return result.first;
    }
    return {
      'hourly_rate': 14.0,
      'theme_mode': 'system',
      'app_palette': 'Blue',
      'currency_symbol': '\$',
    };
  }

  Future<double> getHourlyRate() async {
    final settings = await getSettings();
    return (settings['hourly_rate'] as num).toDouble();
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

  Future<void> updateThemeMode(String themeMode) async {
    final db = await database;
    await db.update(
      'settings',
      {'theme_mode': themeMode},
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  Future<void> updateAppPalette(String paletteName) async {
    final db = await database;
    await db.update(
      'settings',
      {'app_palette': paletteName},
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  Future<void> updateCurrencySymbol(String symbol) async {
    final db = await database;
    await db.update(
      'settings',
      {'currency_symbol': symbol},
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  Future<String?> getActiveShiftStart() async {
    final settings = await getSettings();
    return settings['active_shift_start'] as String?;
  }

  Future<void> setActiveShiftStart(String? startIso) async {
    final db = await database;
    await db.update(
      'settings',
      {'active_shift_start': startIso},
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  Future<void> updateSettings(Map<String, dynamic> settings) async {
    final db = await database;
    await db.update('settings', settings, where: 'id = ?', whereArgs: [1]);
  }

  // Work entries operations
  Future<int> insertWorkEntry(Map<String, dynamic> entry) async {
    final db = await database;
    return await db.insert('work_entries', entry);
  }

  Future<List<Map<String, dynamic>>> getWorkEntries() async {
    final db = await database;
    return await db.query(
      'work_entries',
      orderBy: 'date DESC, created_at DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getWorkEntriesForWeek(
    DateTime weekStart,
  ) async {
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
    return await db.delete('work_entries', where: 'id = ?', whereArgs: [id]);
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

  /// Atomically replaces all work entries and settings (used by restore).
  Future<void> restoreAll({
    required Map<String, dynamic> settings,
    required List<Map<String, dynamic>> entries,
  }) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('work_entries');
      for (final entry in entries) {
        await txn.insert('work_entries', entry);
      }
      if (settings.isNotEmpty) {
        await txn.update('settings', settings, where: 'id = ?', whereArgs: [1]);
      }
    });
  }
}
