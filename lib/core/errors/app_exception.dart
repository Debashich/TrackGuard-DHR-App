sealed class AppException implements Exception {
  final String message;
  final String? code;

  const AppException(this.message, [this.code]);

  @override
  String toString() => '$runtimeType: $message (${code ?? 'UNKNOWN'})';
}

class CameraPermissionDeniedException extends AppException {
  const CameraPermissionDeniedException([
    String message = 'Camera permission was denied',
  ]) : super(message, 'CAMERA_PERMISSION_DENIED');
}

class CameraUnavailableException extends AppException {
  const CameraUnavailableException([
    String message = 'Camera hardware is unavailable',
  ]) : super(message, 'CAMERA_UNAVAILABLE');
}

class ImageCaptureException extends AppException {
  const ImageCaptureException([
    String message = 'Failed to capture photo from camera',
  ]) : super(message, 'IMAGE_CAPTURE_FAILED');
}

class ImageProcessingException extends AppException {
  const ImageProcessingException([
    String message = 'Failed to process or compress image',
  ]) : super(message, 'IMAGE_PROCESSING_FAILED');
}

class LocationPermissionDeniedException extends AppException {
  const LocationPermissionDeniedException([
    String message = 'Location permission was denied',
  ]) : super(message, 'LOCATION_PERMISSION_DENIED');
}

class LocationUnavailableException extends AppException {
  const LocationUnavailableException([
    String message = 'Location services are disabled or unavailable',
  ]) : super(message, 'LOCATION_UNAVAILABLE');
}

class LocationTimeoutException extends AppException {
  const LocationTimeoutException([String message = 'GPS acquisition timed out'])
    : super(message, 'LOCATION_TIMEOUT');
}

// AI Exceptions
class AiUnavailableException extends AppException {
  const AiUnavailableException([
    String message = 'AI analysis model is unavailable',
  ]) : super(message, 'AI_UNAVAILABLE');
}

class AiInitializationException extends AppException {
  const AiInitializationException([
    String message = 'AI model failed to initialize',
  ]) : super(message, 'AI_INIT_FAILED');
}

class AiInvalidOutputException extends AppException {
  const AiInvalidOutputException([
    String message = 'AI returned an invalid or unparseable response',
  ]) : super(message, 'AI_INVALID_OUTPUT');
}

class OfflineModelUnavailableException extends AppException {
  const OfflineModelUnavailableException([
    String message =
        'Offline Gemma model is not installed or available on this device',
  ]) : super(message, 'OFFLINE_MODEL_UNAVAILABLE');
}

class OfflineModelInitializationFailedException extends AppException {
  const OfflineModelInitializationFailedException([
    String message = 'Failed to initialize offline Gemma model runtime',
  ]) : super(message, 'OFFLINE_MODEL_INIT_FAILED');
}

class OfflineModelInferenceFailedException extends AppException {
  const OfflineModelInferenceFailedException([
    String message = 'Offline Gemma inference execution failed',
  ]) : super(message, 'OFFLINE_MODEL_INFERENCE_FAILED');
}

class OfflineModelOutOfMemoryException extends AppException {
  const OfflineModelOutOfMemoryException([
    String message =
        'Device has insufficient memory to run the offline AI model',
  ]) : super(message, 'OFFLINE_MODEL_OOM');
}

class OfflineModelDownloadFailedException extends AppException {
  const OfflineModelDownloadFailedException([
    String message = 'Failed to download offline Gemma model',
  ]) : super(message, 'OFFLINE_MODEL_DOWNLOAD_FAILED');
}

class OfflineModelDownloadCancelledException extends AppException {
  const OfflineModelDownloadCancelledException([
    String message = 'Model download was cancelled by the user',
  ]) : super(message, 'OFFLINE_MODEL_DOWNLOAD_CANCELLED');
}

class OfflineModelInsufficientStorageException extends AppException {
  const OfflineModelInsufficientStorageException([
    String message =
        'Insufficient storage available on this device to download the model',
  ]) : super(message, 'OFFLINE_MODEL_INSUFFICIENT_STORAGE');
}

class OfflineModelNetworkUnavailableException extends AppException {
  const OfflineModelNetworkUnavailableException([
    String message =
        'Network connection required to download the offline AI model',
  ]) : super(message, 'OFFLINE_MODEL_NETWORK_UNAVAILABLE');
}

class OfflineModelDeleteFailedException extends AppException {
  const OfflineModelDeleteFailedException([
    String message = 'Failed to delete offline Gemma model files',
  ]) : super(message, 'OFFLINE_MODEL_DELETE_FAILED');
}

class GeminiUnavailableException extends AppException {
  const GeminiUnavailableException([
    String message =
        'Online Gemini backend is unavailable or device is offline',
  ]) : super(message, 'GEMINI_UNAVAILABLE');
}

class GeminiUnauthorizedException extends AppException {
  const GeminiUnauthorizedException([
    String message = 'Unauthorized request to Gemini backend service',
  ]) : super(message, 'GEMINI_UNAUTHORIZED');
}

class GeminiRateLimitedException extends AppException {
  const GeminiRateLimitedException([
    String message = 'Gemini service rate limit reached. Please retry later',
  ]) : super(message, 'GEMINI_RATE_LIMITED');
}

class GeminiTimeoutException extends AppException {
  const GeminiTimeoutException([
    String message = 'Gemini online analysis timed out',
  ]) : super(message, 'GEMINI_TIMEOUT');
}

class GeminiInvalidResponseException extends AppException {
  const GeminiInvalidResponseException([
    String message = 'Gemini backend returned an invalid response structure',
  ]) : super(message, 'GEMINI_INVALID_RESPONSE');
}

class AiValidationFailedException extends AppException {
  const AiValidationFailedException([
    String message = 'AI response failed schema validation or safety checks',
  ]) : super(message, 'AI_VALIDATION_FAILED');
}

class AiImageTooLargeException extends AppException {
  const AiImageTooLargeException([
    String message = 'Image exceeds acceptable dimensions or size for analysis',
  ]) : super(message, 'AI_IMAGE_TOO_LARGE');
}

class AiUnsupportedLanguageException extends AppException {
  const AiUnsupportedLanguageException([
    String message = 'Requested language is not supported by the AI provider',
  ]) : super(message, 'AI_UNSUPPORTED_LANGUAGE');
}

class DraftMissingException extends AppException {
  const DraftMissingException([
    String message = 'Inspection draft could not be found',
  ]) : super(message, 'DRAFT_MISSING');
}

class LocalSaveException extends AppException {
  const LocalSaveException([
    String message = 'Failed to persist report locally',
  ]) : super(message, 'LOCAL_SAVE_FAILED');
}

class AuthException extends AppException {
  const AuthException([String message = 'Authentication failed'])
    : super(message, 'AUTH_FAILED');
}

class ProfileUnavailableException extends AppException {
  const ProfileUnavailableException([
    String message = 'User profile could not be loaded',
  ]) : super(message, 'PROFILE_UNAVAILABLE');
}
