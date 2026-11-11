import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.colorName,
    required this.label,
  });

  final String colorName;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = StatusPalette.fromColorName(colorName);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: palette.bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.border, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(palette.icon, size: 16, color: palette.fg),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: palette.fg,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class HealthAlertBanner extends StatelessWidget {
  const HealthAlertBanner({
    super.key,
    required this.colorName,
    required this.title,
    required this.message,
    this.subtitle,
    this.badgeLabel,
  });

  final String colorName;
  final String title;
  final String message;
  final String? subtitle;
  final String? badgeLabel;

  @override
  Widget build(BuildContext context) {
    final palette = StatusPalette.fromColorName(colorName);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border, width: 1.8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(palette.icon, color: palette.fg, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (badgeLabel != null) ...[
                  StatusBadge(colorName: colorName, label: badgeLabel!),
                  const SizedBox(height: 6),
                ],
                Text(
                  title,
                  style: TextStyle(
                    color: palette.fg,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    color: palette.fg,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      color: palette.fg,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

