enum InspectionStatus {
  open,
  acknowledged,
  inspectionRequired,
  resolved;

  static InspectionStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'acknowledged':
        return InspectionStatus.acknowledged;
      case 'inspectionrequired':
      case 'inspection_required':
        return InspectionStatus.inspectionRequired;
      case 'resolved':
        return InspectionStatus.resolved;
      case 'open':
      default:
        return InspectionStatus.open;
    }
  }

  String toJson() => name;
}
