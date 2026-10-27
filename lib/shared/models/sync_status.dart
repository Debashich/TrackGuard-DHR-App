enum SyncStatus {
  draft,
  pending,
  syncing,
  synced,
  failed,
  conflict;

  static SyncStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'draft':
        return SyncStatus.draft;
      case 'syncing':
        return SyncStatus.syncing;
      case 'synced':
        return SyncStatus.synced;
      case 'failed':
        return SyncStatus.failed;
      case 'conflict':
        return SyncStatus.conflict;
      case 'pending':
      default:
        return SyncStatus.pending;
    }
  }

  String toJson() => name;
}
