import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/app_user.dart';
import '../../../shared/models/hazard_report.dart';
import '../../../shared/models/inspection_status.dart';
import '../../../shared/models/user_role.dart';
import '../../reports/data/supabase_report_mapper.dart';

/// Remote data access for the admin portal.
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

    final reports = rows
        .map<HazardReport>(
          (row) => SupabaseReportMapper.fromRemoteRow(
            Map<String, dynamic>.from(row),
          ),
        )
        .toList();

    try {
      final reportIds = reports.map((r) => r.id).toList();
      if (reportIds.isNotEmpty) {
        final mediaRows = await _client
            .from('report_media')
            .select('report_id, original_path, thumbnail_path')
            .inFilter('report_id', reportIds);

        final mediaMap = <String, String>{};
        for (final m in mediaRows) {
          final repId = m['report_id'] as String?;
          final thumb = _cleanStoragePath(m['thumbnail_path'] as String?);
          final orig = _cleanStoragePath(m['original_path'] as String?);
          final path = (thumb != null && thumb.isNotEmpty) ? thumb : orig;
          if (repId != null && path != null && path.isNotEmpty) {
            final url = await _resolveStorageUrl(path);
            if (url != null && url.isNotEmpty) {
              mediaMap[repId] = url;
            }
          }
        }

        // For any reports missing from report_media table, try storage discovery
        for (final r in reports) {
          if (!mediaMap.containsKey(r.id)) {
            final discoveredUrl = await _searchStorageForReport(r.id, userId: r.createdBy);
            if (discoveredUrl != null && discoveredUrl.isNotEmpty) {
              mediaMap[r.id] = discoveredUrl;
            }
          }
        }

        if (mediaMap.isNotEmpty) {
          return reports.map((r) {
            final url = mediaMap[r.id];
            if (url != null) {
              return r.copyWith(
                thumbnailPhotoPath: url,
                originalPhotoPath: url,
              );
            }
            return r;
          }).toList();
        }
      }
    } catch (e) {
      debugPrint('[AdminRepository] Error batch loading report media: $e');
    }

    return reports;
  }

  Future<HazardReport?> fetchReport(String id) async {
    final row = await _client
        .from('reports')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (row == null) return null;
    var report = SupabaseReportMapper.fromRemoteRow(Map<String, dynamic>.from(row));

    final mediaUrl = await fetchReportMediaUrl(id, userId: report.createdBy);
    if (mediaUrl != null && mediaUrl.isNotEmpty) {
      report = report.copyWith(
        originalPhotoPath: mediaUrl,
        thumbnailPhotoPath: mediaUrl,
      );
    }
    return report;
  }

  /// Fetches the remote media URL from the report_media table or directly from Supabase storage.
  Future<String?> fetchReportMediaUrl(String reportId, {String? userId}) async {
    try {
      final row = await _client
          .from('report_media')
          .select('original_path, thumbnail_path')
          .eq('report_id', reportId)
          .maybeSingle();

      if (row != null) {
        final origPath = _cleanStoragePath(row['original_path'] as String?);
        final thumbPath = _cleanStoragePath(row['thumbnail_path'] as String?);
        // For full report detail, prefer full original image over thumbnail
        final candidate = (origPath != null && origPath.isNotEmpty) ? origPath : thumbPath;
        if (candidate != null && candidate.isNotEmpty) {
          final url = await _resolveStorageUrl(candidate);
          if (url != null && url.isNotEmpty) return url;
        }
      }
    } catch (e) {
      debugPrint('[AdminRepository] Error querying report_media: $e');
    }

    // Direct Supabase storage search fallback
    return _searchStorageForReport(reportId, userId: userId);
  }

  String? _cleanStoragePath(String? raw) {
    if (raw == null) return null;
    var path = raw.trim();
    if (path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    if (path.startsWith('report-media/')) path = path.substring('report-media/'.length);
    if (path.startsWith('reports/')) path = path.substring('reports/'.length);
    if (path.startsWith('/')) path = path.substring(1);
    return path;
  }

  Future<String?> _resolveStorageUrl(String path) async {
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    for (final bucket in ['report-media', 'reports']) {
      try {
        final signed = await _client.storage.from(bucket).createSignedUrl(path, 60 * 60);
        if (signed.isNotEmpty) return signed;
      } catch (_) {}
      try {
        final pub = _client.storage.from(bucket).getPublicUrl(path);
        if (pub.isNotEmpty) return pub;
      } catch (_) {}
    }
    return null;
  }

  Future<String?> _searchStorageForReport(String reportId, {String? userId}) async {
    final possiblePrefixes = [
      if (userId != null && userId.isNotEmpty) '$userId/$reportId',
      'anonymous/$reportId',
      reportId,
    ];

    for (final bucket in ['report-media', 'reports']) {
      for (final prefix in possiblePrefixes) {
        try {
          final files = await _client.storage.from(bucket).list(path: prefix);
          if (files.isNotEmpty) {
            final file = files.firstWhere(
              (f) => f.name.toLowerCase().contains('original'),
              orElse: () => files.first,
            );
            final fullPath = '$prefix/${file.name}';
            final signed = await _client.storage
                .from(bucket)
                .createSignedUrl(fullPath, 60 * 60);
            if (signed.isNotEmpty) return signed;
            final pub = _client.storage.from(bucket).getPublicUrl(fullPath);
            if (pub.isNotEmpty) return pub;
          }
        } catch (_) {}
      }
    }
    return null;
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
        .order('full_name', ascending: true);
    return rows
        .map<AppUser>(
          (row) => AppUser(
            id: row['id'] as String,
            email: row['email'] as String? ?? '',
            fullName: row['full_name'] as String?,
            role: UserRole.fromString(row['role'] as String?),
            assignedSection: row['assigned_section'] as String?,
            isActive: row['is_active'] as bool? ?? true,
            createdAt:
                DateTime.tryParse(row['created_at'] as String? ?? '') ??
                DateTime.now(),
            updatedAt:
                DateTime.tryParse(row['updated_at'] as String? ?? '') ??
                DateTime.now(),
          ),
        )
        .toList();
  }

  Future<void> updateStatus(
    String reportId,
    InspectionStatus newStatus, {
    String? comment,
  }) async {
    final user = _client.auth.currentUser;
    await _client.from('reports').update({
      'inspection_status': newStatus.toJson(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', reportId);

    if (user != null) {
      await _client.from('report_status_history').insert({
        'report_id': reportId,
        'changed_by': user.id,
        'to_status': newStatus.toJson(),
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      });
    }
  }

  Future<void> updateUserRole(String userId, UserRole role) async {
    await _client.from('profiles').update({
      'role': role.name,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', userId);
  }

  Future<void> updateUserSection(String userId, String? sectionId) async {
    await _client.from('profiles').update({
      'assigned_section': sectionId,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', userId);
  }

  Future<void> setUserActive(String userId, bool isActive) async {
    await _client.from('profiles').update({
      'is_active': isActive,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', userId);
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
