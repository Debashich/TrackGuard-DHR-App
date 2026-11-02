enum OfflineModelStatus {
  notDownloaded,
  checking,
  downloading,
  downloaded,
  initializing,
  ready,
  failed,
  unsupported,
  corrupted,
}

class OfflineModelState {
  final OfflineModelStatus status;
  final String modelId;
  final String modelName;
  final String? version;
  final String? repository;
  final String? filename;
  @Deprecated('LiteRT-LM uses a single self-contained .litertlm model file.')
  final String? projectorFilename;
  final String? sha256;
  final int? totalBytes;
  final int downloadedBytes;
  final double progress;
  final String? errorMessage;
  final DateTime? downloadedAt;
  final DateTime? lastInitializedAt;
  final String? lastInitializationError;
  final bool canCancel;
  final bool canDelete;

  const OfflineModelState({
    this.status = OfflineModelStatus.notDownloaded,
    this.modelId = 'gemma-4-e2b-litertlm',
    this.modelName = 'Gemma 4 E2B',
    this.version = 'litertlm-gemma4-e2b-v1',
    this.repository = 'litert-community/gemma-4-E2B-it-litert-lm',
    this.filename = 'gemma-4-E2B-it.litertlm',
    @Deprecated('LiteRT-LM uses a single self-contained .litertlm model file.')
    this.projectorFilename,
    this.sha256,
    this.totalBytes,
    this.downloadedBytes = 0,
    this.progress = 0.0,
    this.errorMessage,
    this.downloadedAt,
    this.lastInitializedAt,
    this.lastInitializationError,
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
      status == OfflineModelStatus.failed ||
      status == OfflineModelStatus.corrupted;
  bool get isInitializing => status == OfflineModelStatus.initializing;

  String get formattedDownloadedSize {
    if (downloadedBytes <= 0) return '0 MB';
    final mb = downloadedBytes / (1024 * 1024);
    if (mb < 1000) return '${mb.toStringAsFixed(1)} MB';
    return '${(mb / 1024).toStringAsFixed(2)} GB';
  }

  String get formattedTotalSize {
    if (totalBytes == null || totalBytes! <= 0) return '~2.6 GB';
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
    String? repository,
    String? filename,
    String? projectorFilename,
    String? sha256,
    int? totalBytes,
    int? downloadedBytes,
    double? progress,
    String? errorMessage,
    DateTime? downloadedAt,
    DateTime? lastInitializedAt,
    String? lastInitializationError,
    bool? canCancel,
    bool? canDelete,
  }) {
    return OfflineModelState(
      status: status ?? this.status,
      modelId: modelId ?? this.modelId,
      modelName: modelName ?? this.modelName,
      version: version ?? this.version,
      repository: repository ?? this.repository,
      filename: filename ?? this.filename,
      projectorFilename: projectorFilename ?? this.projectorFilename,
      sha256: sha256 ?? this.sha256,
      totalBytes: totalBytes ?? this.totalBytes,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      progress: progress ?? this.progress,
      errorMessage: errorMessage ?? this.errorMessage,
      downloadedAt: downloadedAt ?? this.downloadedAt,
      lastInitializedAt: lastInitializedAt ?? this.lastInitializedAt,
      lastInitializationError:
          lastInitializationError ?? this.lastInitializationError,
      canCancel: canCancel ?? this.canCancel,
      canDelete: canDelete ?? this.canDelete,
    );
  }

  Map<String, dynamic> toJson() => {
    'status': status.name,
    'modelId': modelId,
    'modelName': modelName,
    'version': version,
    'repository': repository,
    'filename': filename,
    'sha256': sha256,
    'totalBytes': totalBytes,
    'downloadedBytes': downloadedBytes,
    'downloadedAt': downloadedAt?.toIso8601String(),
    'lastInitializedAt': lastInitializedAt?.toIso8601String(),
    'lastInitializationError': lastInitializationError,
  };

  factory OfflineModelState.fromJson(Map<String, dynamic> json) {
    OfflineModelStatus status = OfflineModelStatus.notDownloaded;
    try {
      status = OfflineModelStatus.values.byName(json['status'] as String);
    } catch (_) {}

    return OfflineModelState(
      status: status,
      modelId: json['modelId'] as String? ?? 'gemma-4-e2b-litertlm',
      modelName: json['modelName'] as String? ?? 'Gemma 4 E2B',
      version: json['version'] as String? ?? 'litertlm-gemma4-e2b-v1',
      repository:
          json['repository'] as String? ??
          'litert-community/gemma-4-E2B-it-litert-lm',
      filename: json['filename'] as String? ?? 'gemma-4-E2B-it.litertlm',
      projectorFilename: json['projectorFilename'] as String?,
      sha256: json['sha256'] as String?,
      totalBytes: json['totalBytes'] as int?,
      downloadedBytes: json['downloadedBytes'] as int? ?? 0,
      downloadedAt: json['downloadedAt'] != null
          ? DateTime.tryParse(json['downloadedAt'] as String)
          : null,
      lastInitializedAt: json['lastInitializedAt'] != null
          ? DateTime.tryParse(json['lastInitializedAt'] as String)
          : null,
      lastInitializationError: json['lastInitializationError'] as String?,
      canDelete:
          status == OfflineModelStatus.ready ||
          status == OfflineModelStatus.downloaded,
    );
  }
}

class OfflineModelDownloadSettings {
  final bool wifiOnly;
  final bool allowCellularDownload;
  final String? huggingFaceToken;

  const OfflineModelDownloadSettings({
    this.wifiOnly = true,
    this.allowCellularDownload = false,
    this.huggingFaceToken,
  });

  OfflineModelDownloadSettings copyWith({
    bool? wifiOnly,
    bool? allowCellularDownload,
    String? huggingFaceToken,
  }) {
    return OfflineModelDownloadSettings(
      wifiOnly: wifiOnly ?? this.wifiOnly,
      allowCellularDownload:
          allowCellularDownload ?? this.allowCellularDownload,
      huggingFaceToken: huggingFaceToken ?? this.huggingFaceToken,
    );
  }

  Map<String, dynamic> toJson() => {
    'wifiOnly': wifiOnly,
    'allowCellularDownload': allowCellularDownload,
    if (huggingFaceToken != null) 'huggingFaceToken': huggingFaceToken,
  };

  factory OfflineModelDownloadSettings.fromJson(Map<String, dynamic> json) {
    return OfflineModelDownloadSettings(
      wifiOnly: json['wifiOnly'] as bool? ?? true,
      allowCellularDownload: json['allowCellularDownload'] as bool? ?? false,
      huggingFaceToken: json['huggingFaceToken'] as String?,
    );
  }
}
