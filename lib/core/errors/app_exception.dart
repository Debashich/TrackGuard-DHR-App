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
