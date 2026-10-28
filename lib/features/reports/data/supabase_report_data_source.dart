
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/hazard_report.dart';
import 'supabase_report_mapper.dart';

class SupabaseReportDataSource {
  SupabaseReportDataSource(this._client);

  final SupabaseClient _client;

  Future<void> upsertReport(HazardReport report) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw StateError('Sign in before syncing reports.');
    }

    final row = SupabaseReportMapper.toRemoteRow(
      report,
      userId: user.id,
    );

    await _client.from('reports').upsert(
      row,
      onConflict: 'id',
    );
  }

  Future<List<HazardReport>> fetchReports({
    int page = 0,
    int pageSize = 50,
  }) async {
    if (_client.auth.currentUser == null) {
      throw StateError('Sign in before fetching reports.');
    }

    if (page < 0 || pageSize < 1 || pageSize > 100) {
      throw ArgumentError('Invalid report pagination values.');
    }

    final start = page * pageSize;
    final end = start + pageSize - 1;

    final rows = await _client
        .from('reports')
        .select()
        .order('created_at', ascending: false)
        .range(start, end);

    return rows
        .map<HazardReport>(
          (row) => SupabaseReportMapper.fromRemoteRow(
            Map<String, dynamic>.from(row),
          ),
        )
        .toList();
  }
}
