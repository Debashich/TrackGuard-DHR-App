import 'dart:io';

import '../../l10n/app_localizations.dart';
import 'app_exception.dart';

class AiErrorMapper {
  static String getLocalizedMessage(dynamic error, AppLocalizations l10n) {
    if (error is OfflineModelInsufficientStorageException) {
      return l10n.offlineModelInsufficientStorage;
    }
    if (error is OfflineModelNetworkUnavailableException) {
      return l10n.offlineModelNetworkRequired;
    }
    if (error is OfflineModelDownloadCancelledException) {
      return l10n.offlineModelDownloadCancelled;
    }
    if (error is OfflineModelDownloadFailedException) {
      return l10n.offlineModelDownloadFailed;
    }
    if (error is OfflineModelDeleteFailedException) {
      return l10n.offlineModelFailed;
    }
    if (error is OfflineModelUnavailableException) {
      return l10n.aiGemmaUnavailable;
    }
    if (error is OfflineModelInitializationFailedException) {
      return l10n.aiModelInitializationFailed;
    }
    if (error is OfflineModelInferenceFailedException) {
      return l10n.aiInferenceFailed;
    }
    if (error is OfflineModelOutOfMemoryException) {
      return l10n.aiInferenceFailed;
    }
    if (error is GeminiUnavailableException) {
      return l10n.aiGeminiRequiresNetwork;
    }
    if (error is GeminiRateLimitedException) {
      return l10n.aiRateLimited;
    }
    if (error is GeminiTimeoutException) {
      return l10n.aiTimeout;
    }
    if (error is GeminiUnauthorizedException) {
      return l10n.aiOnlineRequestFailed;
    }
    if (error is GeminiInvalidResponseException ||
        error is AiInvalidOutputException ||
        error is AiValidationFailedException) {
      return l10n.aiInvalidResult;
    }
    if (error is AiImageTooLargeException) {
      return l10n.aiImageTooLarge;
    }
    if (error is SocketException) {
      return l10n.aiGeminiRequiresNetwork;
    }

    final message = error.toString().toLowerCase();
    if (message.contains('offline') || message.contains('socket')) {
      return l10n.aiGeminiRequiresNetwork;
    }
    if (message.contains('timeout')) {
      return l10n.aiTimeout;
    }
    if (message.contains('rate limit') || message.contains('429')) {
      return l10n.aiRateLimited;
    }
    if (message.contains('unauthorized') || message.contains('401')) {
      return l10n.aiOnlineRequestFailed;
    }

    return l10n.aiValidationFailed;
  }

  static bool canRetry(dynamic error) {
    if (error is GeminiRateLimitedException ||
        error is GeminiTimeoutException ||
        error is GeminiUnavailableException ||
        error is SocketException) {
      return true;
    }

    if (error is GeminiUnauthorizedException ||
        error is OfflineModelUnavailableException ||
        error is OfflineModelOutOfMemoryException ||
        error is AiValidationFailedException) {
      return false;
    }

    final message = error.toString().toLowerCase();
    return message.contains('timeout') ||
        message.contains('socket') ||
        message.contains('429');
  }
}
