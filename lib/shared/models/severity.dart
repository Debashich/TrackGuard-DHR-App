enum Severity {
  low,
  medium,
  high,
  critical;

  static Severity fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'low':
        return Severity.low;
      case 'high':
        return Severity.high;
      case 'critical':
      case 'urgent':
        return Severity.critical;
      case 'medium':
      default:
        return Severity.medium;
    }
  }

  String toJson() => name;
}
