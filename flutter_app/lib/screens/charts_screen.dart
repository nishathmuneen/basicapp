import 'package:flutter/material.dart';

import '../models/health_models.dart';
import '../theme/app_theme.dart';
import '../widgets/trend_chart.dart';

class ChartsScreen extends StatelessWidget {
  const ChartsScreen({
    super.key,
    required this.charts,
    required this.period,
    required this.loading,
    required this.onPeriodChange,
    required this.onRefresh,
  });

  final ChartsData? charts;
  final String period;
  final bool loading;
  final void Function(String period) onPeriodChange;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final data = charts;
    final thresholds = data?.thresholds;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Simple Charts',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
            'See whether your readings are increasing, decreasing, or staying steady.',
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
          const SizedBox(height: 16),
          if (loading && data == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 36),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (data != null) ...[
            TrendChartCard(
              title: 'Blood Glucose History',
              subtitle:
                  'Readings over time in mg/dL. Shaded green band shows your fasting target range.',
              unit: 'mg/dL',
              timestamps: data.glucosePoints.map((p) => p.recordedAt).toList(),
              series: [
                ChartSeriesConfig(
                  label: 'Blood Glucose',
                  color: AppColors.tealAccent,
                  values: data.glucosePoints.map((p) => p.glucoseValue).toList(),
                ),
              ],
              dotStatuses: data.glucosePoints.map((p) => p.statusLevel).toList(),
              targetBandMin: thresholds?.glucoseLowUrgent,
              targetBandMax: thresholds?.glucoseFastingMax,
              referenceLines: thresholds != null
                  ? [
                      ChartReferenceLine(
                        label: 'After meal max',
                        value: thresholds.glucoseAfterMealMax,
                        color: AppColors.yellowBorder,
                      ),
                    ]
                  : const [],
              trendSummary: data.glucoseTrend,
            ),
            const SizedBox(height: 16),
            TrendChartCard(
              title: 'Blood Pressure History',
              subtitle: 'Systolic (top) and diastolic (bottom) readings in mmHg.',
              unit: 'mmHg',
              timestamps: data.bpPoints.map((p) => p.recordedAt).toList(),
              series: [
                ChartSeriesConfig(
                  label: 'Systolic (top)',
                  color: AppColors.turquoisePrimary,
                  values: data.bpPoints.map((p) => p.systolic.toDouble()).toList(),
                ),
                ChartSeriesConfig(
                  label: 'Diastolic (bottom)',
                  color: AppColors.tealAccent,
                  values: data.bpPoints.map((p) => p.diastolic.toDouble()).toList(),
                ),
              ],
              referenceLines: thresholds != null
                  ? [
                      ChartReferenceLine(
                        label: 'Elevated systolic',
                        value: thresholds.bpAttentionSystolic.toDouble(),
                        color: AppColors.yellowBorder,
                      ),
                      ChartReferenceLine(
                        label: 'Elevated diastolic',
                        value: thresholds.bpAttentionDiastolic.toDouble(),
                        color: AppColors.tealPrimary,
                      ),
                    ]
                  : const [],
              trendSummary: data.bpSystolicTrend,
              secondaryTrendSummary: data.bpDiastolicTrend,
            ),
          ],
        ],
      ),
    );
  }
}

