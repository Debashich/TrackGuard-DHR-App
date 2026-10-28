class SyncErrorEvent {
  final String reportId;
  final String userMessage;
  final String? technicalCode;
  final DateTime occurredAt;
  final bool canRetry;

  const SyncErrorEvent({
    required this.reportId,
    required this.userMessage,
    this.technicalCode,
    required this.occurredAt,
    this.canRetry = true,
  });
}
