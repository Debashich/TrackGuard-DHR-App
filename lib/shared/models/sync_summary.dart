class SyncSummary {
  final int pendingCount;
  final int syncingCount;
  final int failedCount;
  final int syncedCount;
  final int conflictCount;
  final DateTime? lastSuccessfulSync;
  final DateTime? lastAttemptedSync;
  final String? lastError;
  final bool isOnline;
  final bool isSyncing;

  const SyncSummary({
    this.pendingCount = 0,
    this.syncingCount = 0,
    this.failedCount = 0,
    this.syncedCount = 0,
    this.conflictCount = 0,
    this.lastSuccessfulSync,
    this.lastAttemptedSync,
    this.lastError,
    this.isOnline = false,
    this.isSyncing = false,
  });

  int get totalCount =>
      pendingCount + syncingCount + failedCount + syncedCount + conflictCount;

  bool get hasPendingOrFailed => pendingCount > 0 || failedCount > 0;

  bool get hasFailed => failedCount > 0;

  bool get allSynced =>
      totalCount > 0 &&
      pendingCount == 0 &&
      failedCount == 0 &&
      syncingCount == 0;

  SyncSummary copyWith({
    int? pendingCount,
    int? syncingCount,
    int? failedCount,
    int? syncedCount,
    int? conflictCount,
    DateTime? lastSuccessfulSync,
    DateTime? lastAttemptedSync,
    String? lastError,
    bool? isOnline,
    bool? isSyncing,
  }) {
    return SyncSummary(
      pendingCount: pendingCount ?? this.pendingCount,
      syncingCount: syncingCount ?? this.syncingCount,
      failedCount: failedCount ?? this.failedCount,
      syncedCount: syncedCount ?? this.syncedCount,
      conflictCount: conflictCount ?? this.conflictCount,
      lastSuccessfulSync: lastSuccessfulSync ?? this.lastSuccessfulSync,
      lastAttemptedSync: lastAttemptedSync ?? this.lastAttemptedSync,
      lastError: lastError ?? this.lastError,
      isOnline: isOnline ?? this.isOnline,
      isSyncing: isSyncing ?? this.isSyncing,
    );
  }
}
