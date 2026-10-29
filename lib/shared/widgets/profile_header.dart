import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/constants/dhr_waypoints.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/models/app_user.dart';
import '../../shared/models/user_role.dart';

class ProfileHeader extends StatelessWidget {
  final AppUser? user;
  final bool compact;
  final VoidCallback? onTap;

  const ProfileHeader({
    super.key,
    required this.user,
    this.compact = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isAdmin = user?.role == UserRole.admin;
    final roleColor = isAdmin ? AppTheme.statusBlue : AppTheme.primaryAmber;
    final roleIcon = isAdmin ? Icons.admin_panel_settings : Icons.engineering;
    final roleName = isAdmin ? l10n.roleAdmin : l10n.roleGangman;

    final sectionName = user?.assignedSection != null
        ? DhrWaypoints.getSectionName(user!.assignedSection!)
        : (isAdmin ? 'All DHR Alignment' : l10n.unassignedSection);

    final avatar = CircleAvatar(
      backgroundColor: roleColor.withValues(alpha: 0.2),
      radius: compact ? 22 : 32,
      child: Icon(roleIcon, color: roleColor, size: compact ? 24 : 36),
    );

    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                user?.fullName ?? (isAdmin ? 'Supervisor' : 'Gangman'),
                style: TextStyle(
                  fontSize: compact ? 15 : 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: roleColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: roleColor.withValues(alpha: 0.5)),
              ),
              child: Text(
                roleName.toUpperCase(),
                style: TextStyle(
                  color: roleColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          user?.email ?? '',
          style: TextStyle(fontSize: compact ? 12 : 13, color: Colors.white70),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(
              isAdmin ? Icons.map_outlined : Icons.alt_route,
              size: 14,
              color: roleColor,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                isAdmin ? sectionName : l10n.assignedSection(sectionName),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white60,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );

    if (compact) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              avatar,
              const SizedBox(width: 12),
              Expanded(child: details),
            ],
          ),
        ),
      );
    }

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              avatar,
              const SizedBox(width: 16),
              Expanded(child: details),
            ],
          ),
        ),
      ),
    );
  }
}
