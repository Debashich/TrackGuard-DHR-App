import 'dart:async';
import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../../shared/models/hazard_report.dart';
import '../../../shared/models/hazard_type.dart';
import '../../../shared/models/report_draft.dart';
import '../../../shared/models/severity.dart';
import '../../../shared/models/sync_status.dart';
import 'report_repository.dart';

class SqliteReportRepository implements ReportRepository {
  static Database? _database;
  static Future<Database>? _openingDatabase;

  final StreamController<List<HazardReport>> _changes =
      StreamController<List<HazardReport>>.broadcast();

  Future<Database> get _db async {
    if (_database != null) return _database!;

    // Prevent multiple simultaneous database openings.
    _openingDatabase ??= _openDatabase();

    try {
      _database = await _openingDatabase!;
      return _database!;
    } catch (_) {
      _openingDatabase = null;
      rethrow;
    }
  }

  Future<Database> _openDatabase() async {
    final documents = await getApplicationDocumentsDirectory();
    final databasePath = p.join(documents.path, 'trackguard_dhr.db');

    return openDatabase(
      databasePath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE reports (
            id TEXT PRIMARY KEY,
            payload TEXT NOT NULL,
            sync_status TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE INDEX idx_reports_sync_status
          ON reports(sync_status)
        ''');

        await db.execute('''
          CREATE TABLE drafts (
            id INTEGER PRIMARY KEY CHECK (id = 1),
            payload TEXT NOT NULL
          )
        ''');

        await _seedDefaultReports(db);
      },
    );
  }

  Future<void> _seedDefaultReports(Database db) async {
    final now = DateTime.now();
    final defaultReports = [
      HazardReport(
        id: 'dhr-sample-001',
        createdBy: 'dhr-gangman',
        createdAt: DateTime(now.year, now.month, now.day, 10, 24),
        updatedAt: DateTime(now.year, now.month, now.day, 10, 24),
        confirmedHazardType: HazardType.vegetation,
        confirmedSeverity: Severity.high,
        userNote: 'Fallen tree blocking the railway track near Kurseong.',
        kmMarker: 48.2,
        sectionId: 'kurseong-ghum',
        nearestStationName: 'Kurseong',
        syncStatus: SyncStatus.synced,
      ),
      HazardReport(
        id: 'dhr-sample-002',
        createdBy: 'dhr-gangman',
        createdAt: DateTime(now.year, now.month, now.day, 8, 11),
        updatedAt: DateTime(now.year, now.month, now.day, 8, 11),
        confirmedHazardType: HazardType.trackDefect,
        confirmedSeverity: Severity.medium,
        userNote: 'Fishplate loosening and rail joint defect near Tung.',
        kmMarker: 47.8,
        sectionId: 'kurseong-ghum',
        nearestStationName: 'Tung',
        syncStatus: SyncStatus.pending,
      ),
      HazardReport(
        id: 'dhr-sample-003',
        createdBy: 'dhr-gangman',
        createdAt: DateTime(now.year, now.month, now.day - 1, 17, 36),
        updatedAt: DateTime(now.year, now.month, now.day - 1, 17, 36),
        confirmedHazardType: HazardType.rockfall,
        confirmedSeverity: Severity.critical,
        userNote: 'Landslide and boulders covering the track alignment.',
        kmMarker: 49.4,
        sectionId: 'kurseong-ghum',
        nearestStationName: 'Sonada',
        syncStatus: SyncStatus.synced,
      ),
    ];

    for (final report in defaultReports) {
      await db.insert('reports', {
        'id': report.id,
        'payload': jsonEncode(report.toJson()),
        'sync_status': report.syncStatus.toJson(),
        'created_at': report.createdAt.toIso8601String(),
        'updated_at': report.updatedAt.toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  @override
  Future<void> saveDraft(ReportDraft draft) async {
    final db = await _db;

    await db.insert('drafts', {
      'id': 1,
      'payload': jsonEncode(draft.toJson()),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<ReportDraft?> getDraft() async {
    final db = await _db;
    final rows = await db.query(
      'drafts',
      where: 'id = ?',
      whereArgs: [1],
      limit: 1,
    );

    if (rows.isEmpty) return null;

    final json =
        jsonDecode(rows.first['payload'] as String) as Map<String, dynamic>;

    return ReportDraft.fromJson(json);
  }

  @override
  Future<void> clearDraft() async {
    final db = await _db;
    await db.delete('drafts', where: 'id = ?', whereArgs: [1]);
  }

  @override
  Future<void> saveReport(HazardReport report) async {
    final db = await _db;

    // The device-generated UUID is the primary key.
    // Saving the same report again updates it instead of duplicating it.
    await db.insert('reports', {
      'id': report.id,
      'payload': jsonEncode(report.toJson()),
      'sync_status': report.syncStatus.toJson(),
      'created_at': report.createdAt.toIso8601String(),
      'updated_at': report.updatedAt.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    await _publishReports();
  }

  @override
  Future<int> getPendingCount() async {
    final db = await _db;

    final result = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM reports WHERE sync_status = ?',
      [SyncStatus.pending.name],
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  @override
  Future<List<HazardReport>> getLocalReports() async {
    final db = await _db;

    var rows = await db.query('reports', orderBy: 'created_at DESC');

    if (rows.isEmpty) {
      await _seedDefaultReports(db);
      rows = await db.query('reports', orderBy: 'created_at DESC');
    }

    return rows
        .map((row) {
          final json =
              jsonDecode(row['payload'] as String) as Map<String, dynamic>;

          return HazardReport.fromJson(json);
        })
        .toList(growable: false);
  }

  @override
  Future<HazardReport?> getReportById(String id) async {
    final db = await _db;

    var rows = await db.query(
      'reports',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isEmpty) {
      await _seedDefaultReports(db);
      rows = await db.query(
        'reports',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
    }

    if (rows.isEmpty) return null;

    final json =
        jsonDecode(rows.first['payload'] as String) as Map<String, dynamic>;

    return HazardReport.fromJson(json);
  }

  /// Emits the current queue and then every subsequent queue update.
  @override
  Stream<List<HazardReport>> watchLocalReports() async* {
    yield await getLocalReports();
    yield* _changes.stream;
  }

  Future<void> _publishReports() async {
    if (_changes.isClosed) return;
    _changes.add(await getLocalReports());
  }

  Future<void> dispose() async {
    await _changes.close();
  }
}
