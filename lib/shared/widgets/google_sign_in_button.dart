import 'package:flutter/material.dart';

import 'google_logo.dart';

class GoogleSignInButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;

  const GoogleSignInButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            // Natural deep-navy shadow matching the background tone perfectly
            BoxShadow(
              color: const Color(0xFF021631).withValues(alpha: 0.45),
              blurRadius: 24,
              spreadRadius: 1,
              offset: const Offset(0, 8),
            ),
            // Soft ambient spread for clean, natural elevation
            BoxShadow(
              color: const Color(0xFF092D5A).withValues(alpha: 0.22),
              blurRadius: 14,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          child: InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: isLoading ? null : onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: isLoading
                  ? const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Color(0xFF4285F4)),
                        ),
                      ),
                    )
                  : Stack(
                      alignment: Alignment.center,
                      children: [
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: GoogleLogo(size: 26),
                        ),
                        Center(
                          child: Text(
                            text,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF191D26),
                              letterSpacing: 0.15,
                            ),
                          ),
                        ),
                        const Align(
                          alignment: Alignment.centerRight,
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            size: 22,
                            color: Color(0xFF191D26),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
