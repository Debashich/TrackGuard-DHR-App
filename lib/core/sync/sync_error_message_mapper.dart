import '../../l10n/app_localizations.dart';

abstract class SyncErrorMessageMapper {
  const SyncErrorMessageMapper._();

  /// Maps raw exceptions or sync error strings into clear, field-worker-friendly messages.
  /// Never exposes stack traces or technical database details.
  static String getLocalizedMessage(Object? error, AppLocalizations l10n) =>
      toUserMessage(error, l10n);

  static String toUserMessage(Object? error, AppLocalizations l10n) {
    if (error == null) return '';
    final raw = error.toString().toLowerCase();

    if (raw.contains('socketexception') ||
        raw.contains('network') ||
        raw.contains('offline') ||
        raw.contains('failed host lookup') ||
        raw.contains('no route to host') ||
        raw.contains('connection refused') ||
        raw.contains('client not initialized')) {
      return l10n.syncErrorOffline;
    }

    if (raw.contains('timeoutexception') ||
        raw.contains('timed out') ||
        raw.contains('timeout') ||
        raw.contains('deadline exceeded')) {
      return l10n.syncErrorTimeout;
    }

    if (raw.contains('unauthorized') ||
        raw.contains('jwt') ||
        raw.contains('401') ||
        raw.contains('403') ||
        raw.contains('row-level security') ||
        raw.contains('permission denied')) {
      return l10n.syncErrorUnauthorized;
    }

    if (raw.contains('storage') ||
        raw.contains('media') ||
        raw.contains('photo') ||
        raw.contains('bucket') ||
        raw.contains('upload')) {
      return l10n.syncErrorMediaUpload;
    }

    if (raw.contains('502') ||
        raw.contains('503') ||
        raw.contains('504') ||
        raw.contains('service unavailable') ||
        raw.contains('bad gateway')) {
      return l10n.syncErrorServerUnavailable;
    }

    if (raw.contains('conflict') || raw.contains('409')) {
      return l10n.syncErrorConflict;
    }

    return l10n.syncErrorUnknown;
  }

  /// Determines whether the error can likely be recovered via retry.
  static bool canRetry(Object? error) {
    if (error == null) return true;
    final raw = error.toString().toLowerCase();
    if (raw.contains('unauthorized') ||
        raw.contains('401') ||
        raw.contains('403') ||
        raw.contains('forbidden') ||
        raw.contains('corrupt') ||
        raw.contains('malformed json')) {
      return false;
    }
    return true;
  }

  /// Extracts clean technical code if present for diagnostics (without exposing stack trace).
  static String? extractTechnicalCode(Object? error) {
    if (error == null) return null;
    final raw = error.toString();
    final match = RegExp(r'\b([45]\d{2})\b').firstMatch(raw);
    if (match != null) {
      return match.group(1);
    }
    if (raw.contains('SocketException')) return 'NET_UNREACHABLE';
    if (raw.contains('TimeoutException')) return 'TIMEOUT';
    if (raw.contains('StorageException')) return 'STORAGE_ERR';
    return null;
  }
}
