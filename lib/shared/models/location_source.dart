enum LocationSource {
  gps,
  manual,
  fallback;

  static LocationSource fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'manual':
        return LocationSource.manual;
      case 'fallback':
        return LocationSource.fallback;
      case 'gps':
      default:
        return LocationSource.gps;
    }
  }

  String toJson() => name;
}
