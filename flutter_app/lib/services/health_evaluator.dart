import 'dart:math' as math;

import '../models/health_models.dart';
import '../utils/date_formatters.dart';

const String lowGlucoseWarning =
    "Your blood sugar is low. Follow your healthcare professional's hypoglycaemia plan.";
const String highGlucoseWarning =
    'Your blood sugar is above your target range. Monitor and follow your care plan.';
const String highBpWarning =
    'Your blood pressure is elevated. Rest and repeat the measurement correctly.';
const String veryHighBpWarning =
    'Your blood pressure is severely elevated. Seek urgent medical guidance.';

const ThresholdsModel defaultThresholds = ThresholdsModel(
  glucoseLowUrgent: 70.0,
  glucoseFastingMax: 130.0,
  glucoseBeforeMealMax: 130.0,
  glucoseAfterMealMax: 180.0,
  glucoseRandomMax: 180.0,
  glucoseHighUrgent: 250.0,
  bpLowSystolic: 90,
  bpLowDiastolic: 60,
  bpAttentionSystolic: 130,
  bpAttentionDiastolic: 80,
  bpUrgentSystolic: 180,
  bpUrgentDiastolic: 120,
  hrLow: 60,
  hrHigh: 100,
  hrUrgentLow: 45,
  hrUrgentHigh: 130,
);

const Map<String, int> _levelRank = {'normal': 0, 'attention': 1, 'urgent': 2};

String? validateThresholds(ThresholdsModel t) {
  final minTarget = [
    t.glucoseFastingMax,
    t.glucoseBeforeMealMax,
    t.glucoseAfterMealMax,
    t.glucoseRandomMax,
  ].reduce(math.min);
  final maxTarget = [
    t.glucoseFastingMax,
    t.glucoseBeforeMealMax,
    t.glucoseAfterMealMax,
    t.glucoseRandomMax,
  ].reduce(math.max);

  if (t.glucoseLowUrgent >= minTarget) {
    return 'Low glucose alert must be lower than target upper limits.';
  }
  if (t.glucoseHighUrgent <= maxTarget) {
    return 'Urgent high glucose alert must exceed target upper limits.';
  }
  if (!(t.bpLowSystolic < t.bpAttentionSystolic && t.bpAttentionSystolic < t.bpUrgentSystolic)) {
    return 'Systolic thresholds must satisfy low < elevated < urgent.';
  }
  if (!(t.bpLowDiastolic < t.bpAttentionDiastolic &&
      t.bpAttentionDiastolic < t.bpUrgentDiastolic)) {
    return 'Diastolic thresholds must satisfy low < elevated < urgent.';
  }
  if (!(t.hrUrgentLow < t.hrLow && t.hrLow < t.hrHigh && t.hrHigh < t.hrUrgentHigh)) {
    return 'Heart rate thresholds must satisfy urgent low < low < high < urgent high.';
  }
  return null;
}

EvaluationResult evaluateGlucose({
  required double glucoseValue,
  required String glucoseType,
  required ThresholdsModel thresholds,
}) {
  final low = thresholds.glucoseLowUrgent;
  final targetMax = thresholds.targetMaxForType(glucoseType);
  final rangeText =
      '${formatGlucoseValue(low)}–${formatGlucoseValue(targetMax)} mg/dL ($glucoseType)';

  if (glucoseValue < low) {
    return EvaluationResult(
      statusLevel: 'urgent',
      statusLabel: 'Urgent',
      color: 'red',
      withinTarget: false,
      summary: 'Below your target range (low blood sugar).',
      warningMessage: lowGlucoseWarning,
      targetRangeText: rangeText,
    );
  }

  if (glucoseValue > targetMax) {
    final isUrgent = glucoseValue >= thresholds.glucoseHighUrgent;
    return EvaluationResult(
      statusLevel: isUrgent ? 'urgent' : 'attention',
      statusLabel: isUrgent ? 'Urgent' : 'Attention',
      color: isUrgent ? 'red' : 'yellow',
      withinTarget: false,
      summary: isUrgent
          ? 'Well above your target range.'
          : 'Above your target range — requires attention.',
      warningMessage: highGlucoseWarning,
      targetRangeText: rangeText,
    );
  }

  return EvaluationResult(
    statusLevel: 'normal',
    statusLabel: 'Normal',
    color: 'green',
    withinTarget: true,
    summary: 'Within your configured target range.',
    warningMessage: null,
    targetRangeText: rangeText,
  );
}

EvaluationResult evaluateHeartRate({
  required int heartRate,
  required ThresholdsModel thresholds,
}) {
  final rangeText = '${thresholds.hrLow}–${thresholds.hrHigh} bpm';
  if (heartRate < thresholds.hrUrgentLow || heartRate > thresholds.hrUrgentHigh) {
    return EvaluationResult(
      statusLevel: 'urgent',
      statusLabel: 'Urgent',
      color: 'red',
      withinTarget: false,
      summary: 'Heart rate is well outside your typical resting range.',
      warningMessage:
          'Your heart rate is far outside your configured resting range. Rest and seek medical guidance if you feel unwell.',
      targetRangeText: rangeText,
    );
  }
  if (heartRate < thresholds.hrLow || heartRate > thresholds.hrHigh) {
    return EvaluationResult(
      statusLevel: 'attention',
      statusLabel: 'Attention',
      color: 'yellow',
      withinTarget: false,
      summary: 'Heart rate is outside your configured resting range.',
      warningMessage:
          'Your heart rate is outside your usual resting range. Rest quietly and check again.',
      targetRangeText: rangeText,
    );
  }
  return EvaluationResult(
    statusLevel: 'normal',
    statusLabel: 'Normal',
    color: 'green',
    withinTarget: true,
    summary: 'Heart rate is within your configured resting range.',
    warningMessage: null,
    targetRangeText: rangeText,
  );
}

EvaluationResult evaluateBloodPressure({
  required int systolic,
  required int diastolic,
  int? heartRate,
  required ThresholdsModel thresholds,
}) {
  final rangeText =
      '${thresholds.bpLowSystolic}–${thresholds.bpAttentionSystolic - 1} / '
      '${thresholds.bpLowDiastolic}–${thresholds.bpAttentionDiastolic - 1} mmHg';

  String level;
  bool withinTarget;
  String summary;
  String? warningMessage;

  if (systolic >= thresholds.bpUrgentSystolic || diastolic >= thresholds.bpUrgentDiastolic) {
    level = 'urgent';
    withinTarget = false;
    summary = 'Severely elevated blood pressure.';
    warningMessage = veryHighBpWarning;
  } else if (systolic >= thresholds.bpAttentionSystolic ||
      diastolic >= thresholds.bpAttentionDiastolic) {
    level = 'attention';
    withinTarget = false;
    summary = 'Elevated blood pressure — requires attention.';
    warningMessage = highBpWarning;
  } else if (systolic < thresholds.bpLowSystolic || diastolic < thresholds.bpLowDiastolic) {
    level = 'attention';
    withinTarget = false;
    summary = 'Blood pressure is lower than your target range.';
    warningMessage =
        'Your blood pressure is below your configured lower range. Sit down safely, rest, and check again.';
  } else {
    level = 'normal';
    withinTarget = true;
    summary = 'Within your configured blood pressure range.';
    warningMessage = null;
  }

  if (heartRate != null) {
    final hrEval = evaluateHeartRate(heartRate: heartRate, thresholds: thresholds);
    if ((_levelRank[hrEval.statusLevel] ?? 0) > (_levelRank[level] ?? 0)) {
      level = hrEval.statusLevel;
      withinTarget = false;
      warningMessage ??= hrEval.warningMessage;
      summary = '$summary ${hrEval.summary}';
    } else if (hrEval.warningMessage != null && warningMessage != null) {
      summary = '$summary (${hrEval.summary})';
    }
  }

  final label = level == 'urgent'
      ? 'Urgent'
      : (level == 'attention' ? 'Attention' : 'Normal');
  final color = level == 'urgent'
      ? 'red'
      : (level == 'attention' ? 'yellow' : 'green');

  return EvaluationResult(
    statusLevel: level,
    statusLabel: label,
    color: color,
    withinTarget: withinTarget,
    summary: summary,
    warningMessage: warningMessage,
    targetRangeText: rangeText,
  );
}

(String, String) computeDashboardStatus(
  EvaluationResult? latestGlucoseEval,
  EvaluationResult? latestBpEval,
) {
  final evals = [?latestGlucoseEval, ?latestBpEval];
  if (evals.isEmpty) {
    return ('No Readings Yet', 'neutral');
  }
  final highest = evals.map((e) => _levelRank[e.statusLevel] ?? 0).reduce(math.max);
  if (highest == 2) return ('Critical', 'red');
  if (highest == 1) return ('Warning', 'yellow');
  return ('Normal', 'green');
}

ChartTrendSummary computeTrend({
  required List<double> values,
  required String unit,
  required double minChange,
}) {
  if (values.length < 2) {
    return const ChartTrendSummary(
      direction: 'insufficient_data',
      delta: null,
      message: 'Add at least 2 readings in this period to see a trend.',
    );
  }
  final midpoint = math.max(1, values.length ~/ 2);
  final earlier = values.sublist(0, midpoint);
  final recent = values.sublist(midpoint);
  final earlierAvg = earlier.reduce((a, b) => a + b) / earlier.length;
  final recentAvg = recent.reduce((a, b) => a + b) / recent.length;
  final delta = double.parse((recentAvg - earlierAvg).toStringAsFixed(1));

  if (delta >= minChange) {
    return ChartTrendSummary(
      direction: 'increasing',
      delta: delta,
      message:
          'Trending up (+${formatGlucoseValue(delta)} $unit compared with earlier readings).',
    );
  }
  if (delta <= -minChange) {
    return ChartTrendSummary(
      direction: 'decreasing',
      delta: delta,
      message:
          'Trending down (-${formatGlucoseValue(delta.abs())} $unit compared with earlier readings).',
    );
  }
  return ChartTrendSummary(
    direction: 'steady',
    delta: delta,
    message: 'Holding steady (average change ${formatGlucoseValue(delta.abs())} $unit).',
  );
}
