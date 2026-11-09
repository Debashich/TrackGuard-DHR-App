import 'dart:async';
import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../../shared/models/ai_provider.dart';
import '../../../shared/models/app_language.dart';
import '../../../shared/models/hazard_report.dart';
import '../../../shared/models/inspection_status.dart';
import '../../../shared/models/location_source.dart';
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
    final defaultReports = [
      HazardReport(
        id: 'dhr-sample-001',
        createdBy: 'dhr-gangman',
        createdAt: DateTime(2026, 11, 2, 18, 38),
        updatedAt: DateTime(2026, 11, 2, 18, 41),
        confirmedHazardType: HazardType.damagedWall,
        confirmedSeverity: Severity.medium,
        userNote: 'Cracked stone retaining wall along KM 51 curve.',
        kmMarker: 51.0,
        sectionId: 'kurseong-ghum',
        nearestStationName: 'Kurseong Station',
        syncStatus: SyncStatus.synced,
        syncTimestamp: DateTime(2026, 11, 2, 18, 38),
        inspectionStatus: InspectionStatus.acknowledged,
        locationSource: LocationSource.gps,
        gpsAccuracyMeters: 100.0,
        aiProvider: AiProvider.onlineGemini,
        aiModel: 'nvidia/nemotron-3.5-super-vl:free',
        aiLanguage: AppLanguage.en,
        aiConfidence: 0.75,
      ),
      HazardReport(
        id: 'dhr-sample-002',
        createdBy: 'dhr-gangman',
        createdAt: DateTime(2026, 11, 2, 10, 27),
        updatedAt: DateTime(2026, 11, 2, 10, 27),
        confirmedHazardType: HazardType.rockfall,
        confirmedSeverity: Severity.medium,
        userNote: 'Fallen rock boulders and loose debris on outer rail.',
        kmMarker: 51.0,
        sectionId: 'kurseong-ghum',
        nearestStationName: 'Kurseong Station',
        syncStatus: SyncStatus.synced,
        syncTimestamp: DateTime(2026, 11, 2, 10, 27),
      ),
      HazardReport(
        id: 'dhr-sample-003',
        createdBy: 'dhr-gangman',
        createdAt: DateTime(2026, 11, 2, 9, 45),
        updatedAt: DateTime(2026, 11, 2, 9, 45),
        confirmedHazardType: HazardType.rockfall,
        confirmedSeverity: Severity.medium,
        userNote: 'Small rockfall rubble near alignment drainage outlet.',
        kmMarker: 51.0,
        sectionId: 'kurseong-ghum',
        nearestStationName: 'Kurseong Station',
        syncStatus: SyncStatus.synced,
        syncTimestamp: DateTime(2026, 11, 2, 9, 45),
      ),
      HazardReport(
        id: 'dhr-sample-004',
        createdBy: 'dhr-gangman',
        createdAt: DateTime(2026, 11, 1, 15, 20),
        updatedAt: DateTime(2026, 11, 1, 15, 20),
        confirmedHazardType: HazardType.blockedDrain,
        confirmedSeverity: Severity.low,
        userNote: 'Catchwater drain blocked with leaves and silt.',
        kmMarker: 52.4,
        sectionId: 'kurseong-ghum',
        nearestStationName: 'Kurseong Station',
        syncStatus: SyncStatus.synced,
        syncTimestamp: DateTime(2026, 11, 1, 15, 20),
      ),
      HazardReport(
        id: 'dhr-sample-005',
        createdBy: 'dhr-gangman',
        createdAt: DateTime(2026, 10, 31, 11, 10),
        updatedAt: DateTime(2026, 10, 31, 11, 10),
        confirmedHazardType: HazardType.trackDefect,
        confirmedSeverity: Severity.high,
        userNote: 'Loose fishplate bolts on curved rail section.',
        kmMarker: 50.8,
        sectionId: 'kurseong-ghum',
        nearestStationName: 'Kurseong Station',
        syncStatus: SyncStatus.synced,
        syncTimestamp: DateTime(2026, 10, 31, 11, 10),
      ),
    ];

    for (final report in defaultReports) {
      await db.insert('reports', {
        'id': report.id,
        'payload': jsonEncode(report.toJson()),
        'sync_status': report.syncStatus.toJson(),
        'created_at': report.createdAt.toIso8601String(),
        'updated_at': report.updatedAt.toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
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
