enum OfflineModelStatus {
  notDownloaded,
  checking,
  downloading,
  downloaded,
  initializing,
  ready,
  failed,
  unsupported,
}

class OfflineModelState {
  final OfflineModelStatus status;
  final String modelId;
  final String modelName;
  final String? version;
  final int? totalBytes;
  final int downloadedBytes;
  final double progress;
  final String? errorMessage;
  final DateTime? downloadedAt;
  final bool canCancel;
  final bool canDelete;

  const OfflineModelState({
    this.status = OfflineModelStatus.notDownloaded,
    this.modelId = 'gemma-4-e2b-it',
    this.modelName = 'Gemma 4 E2B',
    this.version = '1.0.0',
    this.totalBytes,
    this.downloadedBytes = 0,
    this.progress = 0.0,
    this.errorMessage,
    this.downloadedAt,
    this.canCancel = false,
    this.canDelete = false,
  });

  bool get isReady => status == OfflineModelStatus.ready;
  bool get isDownloading => status == OfflineModelStatus.downloading;
  bool get isDownloaded =>
      status == OfflineModelStatus.downloaded ||
      status == OfflineModelStatus.initializing ||
      status == OfflineModelStatus.ready;
  bool get needsDownload =>
      status == OfflineModelStatus.notDownloaded ||
      status == OfflineModelStatus.failed;
  bool get isInitializing => status == OfflineModelStatus.initializing;

  String get formattedDownloadedSize {
    if (downloadedBytes <= 0) return '0 MB';
    final mb = downloadedBytes / (1024 * 1024);
    if (mb < 1000) return '${mb.toStringAsFixed(1)} MB';
    return '${(mb / 1024).toStringAsFixed(2)} GB';
  }

  String get formattedTotalSize {
    if (totalBytes == null || totalBytes! <= 0) return '~1.2 GB';
    final mb = totalBytes! / (1024 * 1024);
    if (mb < 1000) return '${mb.toStringAsFixed(1)} MB';
    return '${(mb / 1024).toStringAsFixed(2)} GB';
  }

  int get progressPercent => (progress * 100).clamp(0, 100).toInt();

  OfflineModelState copyWith({
    OfflineModelStatus? status,
    String? modelId,
    String? modelName,
    String? version,
    int? totalBytes,
    int? downloadedBytes,
    double? progress,
    String? errorMessage,
    DateTime? downloadedAt,
    bool? canCancel,
    bool? canDelete,
  }) {
    return OfflineModelState(
      status: status ?? this.status,
      modelId: modelId ?? this.modelId,
      modelName: modelName ?? this.modelName,
      version: version ?? this.version,
      totalBytes: totalBytes ?? this.totalBytes,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      progress: progress ?? this.progress,
      errorMessage: errorMessage ?? this.errorMessage,
      downloadedAt: downloadedAt ?? this.downloadedAt,
      canCancel: canCancel ?? this.canCancel,
      canDelete: canDelete ?? this.canDelete,
    );
  }

  Map<String, dynamic> toJson() => {
    'status': status.name,
    'modelId': modelId,
    'modelName': modelName,
    'version': version,
    'totalBytes': totalBytes,
    'downloadedBytes': downloadedBytes,
    'downloadedAt': downloadedAt?.toIso8601String(),
  };

  factory OfflineModelState.fromJson(Map<String, dynamic> json) {
    OfflineModelStatus status = OfflineModelStatus.notDownloaded;
    try {
      status = OfflineModelStatus.values.byName(json['status'] as String);
    } catch (_) {}

    return OfflineModelState(
      status: status,
      modelId: json['modelId'] as String? ?? 'gemma-4-e2b-it',
      modelName: json['modelName'] as String? ?? 'Gemma 4 E2B',
      version: json['version'] as String? ?? '1.0.0',
      totalBytes: json['totalBytes'] as int?,
      downloadedBytes: json['downloadedBytes'] as int? ?? 0,
      downloadedAt: json['downloadedAt'] != null
          ? DateTime.tryParse(json['downloadedAt'] as String)
          : null,
      canDelete:
          status == OfflineModelStatus.ready ||
          status == OfflineModelStatus.downloaded,
    );
  }
}

class OfflineModelDownloadSettings {
  final bool wifiOnly;
  final bool allowCellularDownload;

  const OfflineModelDownloadSettings({
    this.wifiOnly = true,
    this.allowCellularDownload = false,
  });

  OfflineModelDownloadSettings copyWith({
    bool? wifiOnly,
    bool? allowCellularDownload,
  }) {
    return OfflineModelDownloadSettings(
      wifiOnly: wifiOnly ?? this.wifiOnly,
      allowCellularDownload:
          allowCellularDownload ?? this.allowCellularDownload,
    );
  }

  Map<String, dynamic> toJson() => {
    'wifiOnly': wifiOnly,
    'allowCellularDownload': allowCellularDownload,
  };

  factory OfflineModelDownloadSettings.fromJson(Map<String, dynamic> json) {
    return OfflineModelDownloadSettings(
      wifiOnly: json['wifiOnly'] as bool? ?? true,
      allowCellularDownload: json['allowCellularDownload'] as bool? ?? false,
    );
  }
}
