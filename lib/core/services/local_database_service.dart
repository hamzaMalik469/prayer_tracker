/// SQLite database service.
///
/// Manages the local database for offline-first prayer tracking.
/// All prayer records and Qada records are written here first,
/// then synced to Firestore when authenticated and online.
library;

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../logging/app_logger.dart';

abstract final class LocalDatabaseService {
  static Database? _db;

  static Future<Database> get database async {
    _db ??= await _initialise();
    return _db!;
  }

  static Future<Database> _initialise() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'daily_deen.db');

    AppLogger.info('Opening local database at $path', tag: 'LocalDB');

    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    AppLogger.info('Creating local database schema v$version', tag: 'LocalDB');

    // Prayer records table
    await db.execute('''
      CREATE TABLE prayer_records (
        id           TEXT PRIMARY KEY,
        user_id      TEXT NOT NULL,
        date         TEXT NOT NULL,
        prayer_type  TEXT NOT NULL,
        status       TEXT NOT NULL,
        created_at   INTEGER NOT NULL,
        updated_at   INTEGER NOT NULL,
        notes        TEXT,
        synced       INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Qada records table
    await db.execute('''
      CREATE TABLE qada_records (
        id            TEXT PRIMARY KEY,
        user_id       TEXT NOT NULL,
        missed_date   TEXT NOT NULL,
        prayer_type   TEXT NOT NULL,
        qada_status   TEXT NOT NULL,
        created_at    INTEGER NOT NULL,
        updated_at    INTEGER NOT NULL,
        completed_at  INTEGER,
        notes         TEXT,
        synced        INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Indexes for fast date-range queries
    await db.execute(
      'CREATE INDEX idx_prayer_records_user_date '
      'ON prayer_records (user_id, date)',
    );

    await db.execute(
      'CREATE INDEX idx_qada_records_user_status '
      'ON qada_records (user_id, qada_status)',
    );

    AppLogger.info('Local database schema created.', tag: 'LocalDB');
  }

  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    AppLogger.info(
      'Upgrading local database v$oldVersion → v$newVersion',
      tag: 'LocalDB',
    );
    // Future migrations go here.
  }

  static Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
