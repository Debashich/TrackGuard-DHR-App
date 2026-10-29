import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/app_user.dart';
import '../../../shared/models/hazard_report.dart';
import '../../../shared/models/inspection_status.dart';
import '../../../shared/models/user_role.dart';
import '../../reports/data/supabase_report_mapper.dart';

/// Simple remote data access for the Phase 3 admin MVP.
/// Supabase RLS remains the real authorization boundary.
class AdminRepository {
  AdminRepository(this._client);
  final SupabaseClient _client;

  Future<List<HazardReport>> fetchReports() async {
    final rows = await _client
        .from('reports')
        .select()
        .order('created_at', ascending: false)
        .limit(100);
    return rows
        .map<HazardReport>(
          (row) => SupabaseReportMapper.fromRemoteRow(
            Map<String, dynamic>.from(row),
          ),
        )
        .toList();
  }

  Future<HazardReport?> fetchReport(String id) async {
    final row = await _client
        .from('reports')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (row == null) return null;
    return SupabaseReportMapper.fromRemoteRow(Map<String, dynamic>.from(row));
  }

  Future<List<Map<String, dynamic>>> fetchHistory(String reportId) async {
    final rows = await _client
        .from('report_status_history')
        .select(
          'id, report_id, changed_by, from_status, to_status, comment, created_at',
        )
        .eq('report_id', reportId)
        .order('created_at', ascending: false);
    return rows
        .map<Map<String, dynamic>>((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  Future<List<AppUser>> fetchProfiles() async {
    final rows = await _client
        .from('profiles')
        .select()
        .order('created_at', ascending: false)
        .limit(200);
    return rows
        .map<AppUser>((row) => AppUser.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<void> updateStatus(String reportId, InspectionStatus status) async {
    await _client
        .from('reports')
        .update({
          'inspection_status': status.toJson(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', reportId);
    // The existing database trigger should create the audit-history row.
  }

  Future<void> updateProfile({
    required String id,
    required bool isActive,
    required UserRole role,
    required String? assignedSection,
  }) async {
    await _client
        .from('profiles')
        .update({
          'is_active': isActive,
          'role': role.name,
          'assigned_section': assignedSection,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id);
  }
}
