import 'package:flutter/material.dart';

/// Standard branded modal dialog for TrackGuard DHR.
///
/// Follows the high-fidelity rounded card design with top squircle icon,
/// centered typography, and stacked primary / cancel action buttons.
/// Uses the exact font sizes and hierarchy from the home screen.
class TrackGuardDialog extends StatelessWidget {
  const TrackGuardDialog({
    super.key,
    required this.icon,
    this.iconColor,
    this.iconBgColor,
    this.isDestructive = false,
    required this.title,
    this.message,
    this.content,
    required this.primaryLabel,
    this.primaryIcon,
    this.primaryColor,
    this.onPrimaryPressed,
    this.isPrimaryLoading = false,
    this.secondaryLabel,
    this.secondaryIcon,
    this.onSecondaryPressed,
    this.cancelLabel,
    this.onCancelPressed,
  });

  final IconData icon;
  final Color? iconColor;
  final Color? iconBgColor;
  final bool isDestructive;
  final String title;
  final String? message;
  final Widget? content;

  final String primaryLabel;
  final IconData? primaryIcon;
  final Color? primaryColor;
  final VoidCallback? onPrimaryPressed;
  final bool isPrimaryLoading;

  final String? secondaryLabel;
  final IconData? secondaryIcon;
  final VoidCallback? onSecondaryPressed;

  final String? cancelLabel;
  final VoidCallback? onCancelPressed;

  static const Color brandBlue = Color(0xFF074E95);
  static const Color brandBlueSoft = Color(0xFFE8F1FA);
  static const Color red = Color(0xFFDC2626);
  static const Color redSoft = Color(0xFFFFEDEC);
  static const Color amber = Color(0xFFD97706);
  static const Color amberSoft = Color(0xFFFEF3C7);
  static const Color green = Color(0xFF16A34A);
  static const Color greenSoft = Color(0xFFDCFCE7);

  static Future<T?> show<T>({
    required BuildContext context,
    required IconData icon,
    Color? iconColor,
    Color? iconBgColor,
    bool isDestructive = false,
    required String title,
    String? message,
    Widget? content,
    required String primaryLabel,
    IconData? primaryIcon,
    Color? primaryColor,
    VoidCallback? onPrimaryPressed,
    bool isPrimaryLoading = false,
    String? secondaryLabel,
    IconData? secondaryIcon,
    VoidCallback? onSecondaryPressed,
    String? cancelLabel,
    VoidCallback? onCancelPressed,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (ctx) => TrackGuardDialog(
        icon: icon,
        iconColor: iconColor,
        iconBgColor: iconBgColor,
        isDestructive: isDestructive,
        title: title,
        message: message,
        content: content,
        primaryLabel: primaryLabel,
        primaryIcon: primaryIcon,
        primaryColor: primaryColor,
        onPrimaryPressed: onPrimaryPressed,
        isPrimaryLoading: isPrimaryLoading,
        secondaryLabel: secondaryLabel,
        secondaryIcon: secondaryIcon,
        onSecondaryPressed: onSecondaryPressed,
        cancelLabel: cancelLabel,
        onCancelPressed: onCancelPressed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ?? (isDestructive ? red : brandBlue);
    final effectiveIconBgColor = iconBgColor ?? (isDestructive ? redSoft : brandBlueSoft);
    final effectivePrimaryColor = primaryColor ?? (isDestructive ? red : brandBlue);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.14),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(22, 28, 22, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Top Icon Squircle
            Center(
              child: Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: effectiveIconBgColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  icon,
                  size: 30,
                  color: effectiveIconColor,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 2. Title (Matching Home Screen Heading font size: 17.5)
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0A1E3F),
                letterSpacing: -0.2,
              ),
            ),

            // 3. Optional Message (Matching Home Screen Body/Subtitle font size: 13.5)
            if (message != null && message!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF475569),
                  height: 1.4,
                ),
              ),
            ],

            // 4. Custom Content Widget (e.g. warning banner, status badge)
            if (content != null) ...[
              const SizedBox(height: 14),
              content!,
            ],

            const SizedBox(height: 22),

            // 5. Action Buttons (Stacked Vertically)
            // Primary Action Button (Matching Home Screen action font size: 14.5)
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: isPrimaryLoading ? null : onPrimaryPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: effectivePrimaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: isPrimaryLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (primaryIcon != null) ...[
                            Icon(primaryIcon, size: 19, color: Colors.white),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: Text(
                              primaryLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            // Secondary Action Button (if present, e.g. "Discard")
            if (secondaryLabel != null && onSecondaryPressed != null) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: onSecondaryPressed,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFFFEF2F2),
                    foregroundColor: const Color(0xFFDC2626),
                    side: const BorderSide(color: Color(0xFFFECACA), width: 1.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (secondaryIcon != null) ...[
                        Icon(secondaryIcon, size: 18, color: const Color(0xFFDC2626)),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        secondaryLabel!,
                        style: const TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Cancel / Dismiss Action Button (Matching Home Screen font size: 14.5)
            if (cancelLabel != null && onCancelPressed != null) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: onCancelPressed,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: brandBlue,
                    side: const BorderSide(
                      color: Color(0xFFBFDBFE),
                      width: 1.3,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    cancelLabel!,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: brandBlue,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
