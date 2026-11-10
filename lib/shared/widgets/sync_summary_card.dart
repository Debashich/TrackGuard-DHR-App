import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../l10n/app_localizations.dart';
import '../models/sync_summary.dart';

class SyncSummaryCard extends StatelessWidget {
  final SyncSummary summary;
  final VoidCallback? onSyncNow;
  final VoidCallback? onViewQueue;
  final bool isSyncing;

  const SyncSummaryCard({
    super.key,
    required this.summary,
    this.onSyncNow,
    this.onViewQueue,
    this.isSyncing = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isOnline = summary.isOnline;
    final currentlySyncing = isSyncing || summary.isSyncing;

    final syncDateFormatted = summary.lastSuccessfulSync != null
        ? DateFormat('d MMM yyyy, h:mm a').format(summary.lastSuccessfulSync!)
        : '2 Nov 2026, 6:38 PM';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Icon + Title + Signal Badge (Clean spaceBetween without flex compression)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Symbols.layers_rounded,
                    color: Color(0xFF074E95),
                    size: 21,
                  ),
                  SizedBox(width: 7),
                  Text(
                    'Sync Summary',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                decoration: BoxDecoration(
                  color: isOnline
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isOnline
                        ? const Color(0xFF86EFAC)
                        : const Color(0xFFCBD5E1),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isOnline
                            ? const Color(0xFF16A34A)
                            : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isOnline
                          ? (l10n?.syncStationSignalAvailable ?? 'Station signal available')
                          : 'Offline',
                      style: TextStyle(
                        fontSize: 12.0,
                        fontWeight: FontWeight.w700,
                        color: isOnline
                            ? const Color(0xFF15803D)
                            : const Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 2x2 Metric Grid with IDENTICAL height (76px) and IDENTICAL width (50%) for all 4 cards
          // Row 1: Pending & Failed
          Row(
            children: [
              // 1. Pending Block
              Expanded(
                child: Container(
                  height: 76,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFEF3C7), width: 1.2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Symbols.schedule_rounded,
                            size: 16,
                            color: Color(0xFFD97706),
                          ),
                          const SizedBox(width: 5),
                          const Text(
                            'Pending',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF92400E),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFD97706),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${summary.pendingCount}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // 2. Failed Block
              Expanded(
                child: Container(
                  height: 76,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFEE2E2), width: 1.2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Symbols.error_rounded,
                            size: 16,
                            color: Color(0xFFDC2626),
                          ),
                          SizedBox(width: 5),
                          Text(
                            'Failed',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF991B1B),
                            ),
                          ),
                          Spacer(),
                          Icon(
                            Symbols.cancel_rounded,
                            size: 15,
                            color: Color(0xFFDC2626),
                          ),
                        ],
                      ),
                      Text(
                        '${summary.failedCount}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Row 2: Synced & Status Action (Identical 76px height)
          Row(
            children: [
              // 3. Synced Block
              Expanded(
                child: Container(
                  height: 76,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFDCFCE7), width: 1.2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Symbols.check_circle_rounded,
                            size: 16,
                            color: Color(0xFF16A34A),
                          ),
                          SizedBox(width: 5),
                          Text(
                            'Synced',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF166534),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${summary.syncedCount}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // 4. Status Action Block (Same 76px height, generous clear typography)
              Expanded(
                child: Container(
                  height: 76,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFDCFCE7), width: 1.2),
                  ),
                  child: currentlySyncing
                      ? const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF16A34A),
                                  ),
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Syncing...',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF15803D),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Uploading reports...',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        )
                      : (summary.hasPendingOrFailed && onSyncNow != null && isOnline)
                          ? InkWell(
                              onTap: onSyncNow,
                              borderRadius: BorderRadius.circular(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(
                                        Symbols.sync_rounded,
                                        size: 16,
                                        color: Color(0xFF074E95),
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        'Sync Now',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF074E95),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${summary.pendingCount} pending upload',
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  children: const [
                                    Icon(
                                      Symbols.cloud_done_rounded,
                                      size: 18,
                                      color: Color(0xFF16A34A),
                                    ),
                                    SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'All reports synced',
                                        style: TextStyle(
                                          fontSize: 13.0,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF15803D),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  'Last synced: $syncDateFormatted',
                                  style: const TextStyle(
                                    fontSize: 11.0,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF475569),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                ),
              ),
            ],
          ),

          if (onViewQueue != null) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onViewQueue,
                child: const Text('View Queue'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
