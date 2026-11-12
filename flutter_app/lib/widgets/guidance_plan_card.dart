import 'package:flutter/material.dart';

import '../models/health_models.dart';
import '../theme/app_theme.dart';
import 'status_badge.dart';

class GuidancePlanCard extends StatelessWidget {
  const GuidancePlanCard({
    super.key,
    required this.plan,
    this.title = 'Suggested Diet & Exercise Plan',
    this.compact = false,
    this.onUpdateLifestyle,
  });

  final DailyGuidancePlan plan;
  final String title;
  final bool compact;
  final VoidCallback? onUpdateLifestyle;

  @override
  Widget build(BuildContext context) {
    final palette = StatusPalette.fromColorName(plan.toneColor);
    final blocked = plan.exerciseSafetyLevel == 'blocked';
    final badgeLabel = switch (plan.toneColor) {
      'red' => 'Safety Alert',
      'yellow' => 'Tailored Focus',
      _ => 'Balanced Day',
    };

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: plan.toneColor == 'red' ? palette.border : AppColors.turquoiseBorder,
          width: plan.toneColor == 'red' ? 1.8 : 1.2,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 14 : 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.turquoiseSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.spa_rounded,
                    color: AppColors.tealDark,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.tealDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        plan.headline,
                        style: TextStyle(
                          fontSize: compact ? 16 : 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                StatusBadge(colorName: plan.toneColor, label: badgeLabel),
              ],
            ),
            if (plan.safetyNote != null && plan.safetyNote!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: palette.bg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: palette.border, width: 1.4),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(palette.icon, color: palette.fg, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        plan.safetyNote!,
                        style: TextStyle(
                          color: palette.fg,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            _GuidanceSection(
              icon: Icons.restaurant_menu_rounded,
              iconBg: AppColors.turquoiseLight,
              iconColor: AppColors.tealDark,
              heading: 'Suggested Diet Plan',
              items: plan.dietTips,
            ),
            const SizedBox(height: 12),
            _GuidanceSection(
              icon: blocked
                  ? Icons.pause_circle_outline_rounded
                  : Icons.directions_walk_rounded,
              iconBg: blocked ? AppColors.redBg : AppColors.turquoiseLight,
              iconColor: blocked ? AppColors.redText : AppColors.turquoiseDark,
              heading: 'Suggested Exercise Routine',
              items: plan.exerciseRoutine,
            ),
            if (plan.sleepSummary != null ||
                plan.weightSummary != null ||
                onUpdateLifestyle != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.turquoiseSoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.turquoiseBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (plan.sleepSummary != null)
                      _ContextRow(
                        icon: Icons.bedtime_rounded,
                        text: plan.sleepSummary!,
                      ),
                    if (plan.sleepSummary != null && plan.weightSummary != null)
                      const SizedBox(height: 6),
                    if (plan.weightSummary != null)
                      _ContextRow(
                        icon: Icons.monitor_weight_outlined,
                        text: plan.weightSummary!,
                      ),
                    if (plan.sleepSummary == null && plan.weightSummary == null)
                      const _ContextRow(
                        icon: Icons.tune_rounded,
                        text:
                            'Add your sleep hours and weight to further tailor your diet and exercise plan.',
                      ),
                    if (onUpdateLifestyle != null) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: onUpdateLifestyle,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            minimumSize: const Size(0, 36),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          icon: const Icon(Icons.edit_outlined, size: 17),
                          label: Text(
                            plan.sleepSummary != null || plan.weightSummary != null
                                ? 'Update Sleep & Weight'
                                : 'Add Sleep & Weight',
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            Text(
              plan.disclaimer,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuidanceSection extends StatelessWidget {
  const _GuidanceSection({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.heading,
    required this.items,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String heading;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 17, color: iconColor),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                heading,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final tip in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Icon(
                    Icons.circle,
                    size: 6,
                    color: AppColors.tealPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tip,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ContextRow extends StatelessWidget {
  const _ContextRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 17, color: AppColors.tealDark),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.tealDark,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
