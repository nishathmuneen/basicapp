import 'package:flutter/material.dart';

import '../models/health_models.dart';
import '../theme/app_theme.dart';
import '../utils/date_formatters.dart';
import '../widgets/app_chrome.dart';
import '../widgets/status_badge.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.dashboard,
    required this.session,
    required this.loading,
    required this.onRefresh,
    required this.onAddGlucose,
    required this.onAddBP,
    required this.onOpenThresholds,
    required this.onOpenAccount,
    required this.onGoToReminders,
  });

  final DashboardData? dashboard;
  final AuthSession? session;
  final bool loading;
  final Future<void> Function() onRefresh;
  final VoidCallback onAddGlucose;
  final VoidCallback onAddBP;
  final VoidCallback onOpenThresholds;
  final VoidCallback onOpenAccount;
  final VoidCallback onGoToReminders;

  @override
  Widget build(BuildContext context) {
    if (loading && dashboard == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final data = dashboard;
    final displayName = data?.displayName ?? session?.displayName ?? 'Patient';
    final welcomeTitle = displayName.toLowerCase() != 'patient'
        ? 'Welcome back, $displayName'
        : 'Welcome to My Health Tracker';

    final statusColor = data?.healthStatusColor ?? 'neutral';
    final statusText = data?.healthStatus ?? 'No Readings Yet';
    final statusPalette = StatusPalette.fromColorName(statusColor);

    final latestGlucose = data?.latestGlucose;
    final latestBp = data?.latestBp;
    final latestHr = data?.latestHeartRate;
    final latestHrStatus = data?.latestHeartRateStatus;
    final dueReminders = data?.dueReminders ?? const <ReminderItem>[];

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Welcome & Overall Status Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppColors.welcomeCardGradient,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.turquoiseBorder, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const AppLogoMark(size: 42, borderRadius: 11),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            welcomeTitle,
                            style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              color: AppColors.tealDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Track your blood sugar, blood pressure, and heart rate simply.',
                            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: onOpenThresholds,
                      icon: const Icon(Icons.tune_rounded, size: 18),
                      label: const Text('Target Ranges'),
                    ),
                    if (session?.isDefaultPassword == true)
                      OutlinedButton.icon(
                        onPressed: onOpenAccount,
                        icon: const Icon(Icons.lock_reset_rounded, size: 18),
                        label: const Text('Update Login Details'),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: statusPalette.bg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: statusPalette.border, width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(statusPalette.icon, color: statusPalette.fg, size: 28),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Overall Health Status',
                                  style: TextStyle(
                                    color: statusPalette.fg,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  statusText,
                                  style: TextStyle(
                                    color: statusPalette.fg,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Last recording: ${formatDateTimeDisplay(data?.lastRecordedAt)}',
                        style: TextStyle(
                          color: statusPalette.fg,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Two Large Action Buttons
          Row(
            children: [
              Expanded(
                child: _LargeActionButton(
                  title: 'Add Glucose Reading',
                  subtitle: 'mg/dL & meal type',
                  icon: Icons.water_drop_rounded,
                  gradientColors: const [AppColors.tealPrimary, AppColors.tealAccent],
                  onTap: onAddGlucose,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _LargeActionButton(
                  title: 'Add BP Reading',
                  subtitle: 'BP & heart rate',
                  icon: Icons.favorite_rounded,
                  gradientColors: const [AppColors.turquoiseDark, AppColors.turquoisePrimary],
                  onTap: onAddBP,
                ),
              ),
            ],
          ),

          // Due Reminders Banner
          if (dueReminders.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.pageBg, AppColors.turquoiseSoft],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.turquoiseBorder, width: 1.8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.notifications_active_outlined, color: AppColors.tealDark),
                      SizedBox(width: 8),
                      Text(
                        "Today's Reminders Due",
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: AppColors.tealDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...dueReminders.map(
                    (rem) => Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${rem.title} (${formatWallTime(rem.timeOfDay)})',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                          TextButton(
                            onPressed: rem.key == 'bp_measurement' ? onAddBP : onAddGlucose,
                            child: Text(rem.key == 'bp_measurement' ? 'Log BP' : 'Log Sugar'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: onGoToReminders,
                      child: const Text('Manage Reminders'),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Automatic Warning Banners
          if (latestGlucose?.evaluation.warningMessage != null) ...[
            const SizedBox(height: 14),
            HealthAlertBanner(
              colorName: latestGlucose!.evaluation.color,
              title: 'Blood Glucose Note',
              message: latestGlucose.evaluation.warningMessage!,
            ),
          ],
          if (latestBp?.evaluation.warningMessage != null) ...[
            const SizedBox(height: 12),
            HealthAlertBanner(
              colorName: latestBp!.evaluation.color,
              title: 'Blood Pressure Note',
              message: latestBp.evaluation.warningMessage!,
            ),
          ],

          const SizedBox(height: 18),
          const Text(
            'Latest Readings',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),

          _MetricCard(
            label: 'Blood Glucose',
            icon: Icons.water_drop_outlined,
            badgeColor: latestGlucose?.evaluation.color ?? 'neutral',
            badgeLabel: latestGlucose?.evaluation.statusLabel ?? 'No data',
            valueText: latestGlucose != null
                ? formatGlucoseValue(latestGlucose.glucoseValue)
                : null,
            unit: 'mg/dL',
            detail: latestGlucose != null
                ? '${latestGlucose.glucoseType} · ${formatDateTimeDisplay(latestGlucose.recordedAt)}'
                : 'No blood glucose readings saved yet.',
            note: latestGlucose != null
                ? 'Target: ${latestGlucose.evaluation.targetRangeText}'
                : null,
          ),
          const SizedBox(height: 12),

          _MetricCard(
            label: 'Blood Pressure',
            icon: Icons.favorite_border_rounded,
            badgeColor: latestBp?.evaluation.color ?? 'neutral',
            badgeLabel: latestBp?.evaluation.statusLabel ?? 'No data',
            valueText:
                latestBp != null ? '${latestBp.systolic} / ${latestBp.diastolic}' : null,
            unit: 'mmHg',
            detail: latestBp != null
                ? formatDateTimeDisplay(latestBp.recordedAt)
                : 'No blood pressure readings saved yet.',
            note: latestBp != null ? 'Target: ${latestBp.evaluation.targetRangeText}' : null,
          ),
          const SizedBox(height: 12),

          _MetricCard(
            label: 'Heart Rate',
            icon: Icons.monitor_heart_outlined,
            badgeColor: latestHrStatus?.color ?? 'neutral',
            badgeLabel: latestHrStatus?.statusLabel ?? 'Optional',
            valueText: latestHr != null ? '$latestHr' : null,
            unit: 'bpm',
            detail: latestHr != null
                ? formatDateTimeDisplay(data?.latestHeartRateAt)
                : 'Optional — enter heart rate when logging blood pressure.',
            note: latestHrStatus != null
                ? 'Typical resting range: ${latestHrStatus.targetRangeText}'
                : null,
          ),

          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.pageBg, AppColors.turquoiseSoft],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.turquoiseBorder, width: 1.4),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    StatusBadge(colorName: 'green', label: 'Green: Normal'),
                    StatusBadge(colorName: 'yellow', label: 'Yellow: Attention'),
                    StatusBadge(colorName: 'red', label: 'Red: Urgent'),
                  ],
                ),
                SizedBox(height: 10),
                Text(
                  'This personal tracker helps monitor your readings using your target ranges. '
                  'It does not diagnose conditions or recommend changing medication.',
                  style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LargeActionButton extends StatelessWidget {
  const _LargeActionButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 112),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: Colors.white, size: 24),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontSize: 13,
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

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.icon,
    required this.badgeColor,
    required this.badgeLabel,
    required this.valueText,
    required this.unit,
    required this.detail,
    this.note,
  });

  final String label;
  final IconData icon;
  final String badgeColor;
  final String badgeLabel;
  final String? valueText;
  final String unit;
  final String detail;
  final String? note;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.tealAccent, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppColors.tealDark,
                    ),
                  ),
                ),
                StatusBadge(colorName: badgeColor, label: badgeLabel),
              ],
            ),
            const SizedBox(height: 10),
            if (valueText != null)
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      valueText!,
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      unit,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 4),
            Text(
              detail,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            if (note != null) ...[
              const SizedBox(height: 3),
              Text(
                note!,
                style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
