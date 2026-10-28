import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';

abstract class DateFormatUtils {
  const DateFormatUtils._();

  /// Formats synchronization time with localized Today / Yesterday prefix.
  static String formatSyncTime(DateTime dateTime, AppLocalizations l10n) {
    final local = dateTime.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final itemDay = DateTime(local.year, local.month, local.day);
    final timeStr = DateFormat('h:mm a').format(local);

    if (itemDay == today) {
      return '${l10n.today}, $timeStr';
    } else if (itemDay == today.subtract(const Duration(days: 1))) {
      return '${l10n.yesterday}, $timeStr';
    } else {
      return '${DateFormat('d MMM yyyy').format(local)}, $timeStr';
    }
  }

  /// Formats creation or event timestamp for reports.
  static String formatReportDate(DateTime dateTime) {
    return DateFormat('d MMM yyyy, h:mm a').format(dateTime.toLocal());
  }

  /// General format helper that formats with localization if provided, or report format.
  static String formatDateTime(DateTime dateTime, [AppLocalizations? l10n]) {
    if (l10n != null) {
      return formatSyncTime(dateTime, l10n);
    }
    return formatReportDate(dateTime);
  }
}
