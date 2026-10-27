class AppConstants {
  static const String appName = 'TrackGuard DHR';
  static const String appVersion = '0.1.0';

  // Image limits
  static const int aiImageMaxDimension = 1280;
  static const int thumbnailMaxDimension = 320;
  static const int jpegQuality = 85;

  // GPS limits
  static const int gpsTimeoutSeconds = 12;
  static const double acceptableGpsAccuracyMeters = 50.0;

  // Touch target
  static const double minTouchTargetSize = 48.0;

  // Default fallback waypoint (Kurseong)
  static const double fallbackLat = 26.8812;
  static const double fallbackLon = 88.2789;
  static const double fallbackKm = 51.0;
  static const String fallbackStation = 'Kurseong Station';
  static const String fallbackSection = 'kurseong-ghum';
}
