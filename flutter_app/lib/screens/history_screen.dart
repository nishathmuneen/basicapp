import 'package:flutter/material.dart';

import '../models/health_models.dart';
import '../services/health_repository.dart';
import '../theme/app_theme.dart';
import '../utils/date_formatters.dart';
import '../widgets/status_badge.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({
    super.key,
    required this.repository,
    required this.readings,
    required this.period,
    required this.category,
    required this.loading,
    required this.onPeriodChange,
    required this.onCategoryChange,
    required this.onRefresh,
  });

  final LocalHealthRepository repository;
  final List<HealthReading> readings;
  final String period;
  final String category;
  final bool loading;
  final void Function(String period) onPeriodChange;
  final void Function(String category) onCategoryChange;
  final Future<void> Function() onRefresh;

  Future<void> _confirmDelete(BuildContext context, HealthReading item) async {
    final label = item.category == 'glucose'
        ? '${formatGlucoseValue(item.glucoseValue)} mg/dL glucose'
        : '${item.systolic}/${item.diastolic} mmHg blood pressure';

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Reading?'),
        content: Text(
          'Remove the $label reading recorded on ${formatDateTimeDisplay(item.recordedAt)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep Reading'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.redBorder),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await repository.deleteReading(item.id);
      await onRefresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Health History',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
            'Review your saved daily, weekly, and monthly readings.',
            style: TextStyle(fontSize: 14, color: AppColors.textMuted),
          ),
          const SizedBox(height: 14),

          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'daily', label: Text('Daily')),
              ButtonSegment(value: 'weekly', label: Text('Weekly')),
              ButtonSegment(value: 'monthly', label: Text('Monthly')),
              ButtonSegment(value: 'all', label: Text('All')),
            ],
            selected: {period},
            onSelectionChanged: (selection) => onPeriodChange(selection.first),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final opt in const [
                ('all', 'All Readings'),
                ('glucose', 'Glucose Only'),
                ('bp', 'BP Only'),
              ])
                ChoiceChip(
                  label: Text(opt.$2),
                  selected: category == opt.$1,
                  selectedColor: AppColors.turquoiseLight,
                  onSelected: (_) => onCategoryChange(opt.$1),
                ),
            ],
          ),
          const SizedBox(height: 14),

          if (loading && readings.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 36),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (readings.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(Icons.history_rounded, size: 40, color: AppColors.tealAccent),
                    const SizedBox(height: 8),
                    const Text(
                      'No readings found for this period.',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Try switching to Weekly, Monthly, or All, or add a reading from Home.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            )
          else
            ...readings.map((item) {
              final dateText = formatDateDisplay(item.recordedAt);
              final timeText = formatTimeDisplay(item.recordedAt);
              final glucoseValue = item.category == 'glucose'
                  ? '${formatGlucoseValue(item.glucoseValue)} mg/dL (${item.glucoseType})'
                  : '—';
              final bpValue = item.category == 'bp'
                  ? '${item.systolic} / ${item.diastolic} mmHg'
                      '${item.heartRate != null ? ' · ${item.heartRate} bpm' : ''}'
                  : '—';

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '$dateText · $timeText',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.tealDark,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            StatusBadge(
                              colorName: item.evaluation.color,
                              label: item.evaluation.statusLabel,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _HistoryRow(label: 'Glucose value', value: glucoseValue),
                        const SizedBox(height: 4),
                        _HistoryRow(label: 'BP value', value: bpValue),
                        if (item.evaluation.warningMessage != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            item.evaluation.warningMessage!,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () => _confirmDelete(context, item),
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              size: 18,
                              color: AppColors.redText,
                            ),
                            label: const Text(
                              'Remove',
                              style: TextStyle(color: AppColors.redText),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 112,
          child: Text(
            '$label:',
            style: const TextStyle(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}

