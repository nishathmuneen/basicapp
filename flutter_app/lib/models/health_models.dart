class AuthSession {
  const AuthSession({
    required this.authenticated,
    this.username,
    this.displayName,
    this.isDefaultPassword = false,
    this.showDefaultHint = false,
    this.defaultUsername,
    this.defaultPassword,
    this.accessToken,
  });

  final bool authenticated;
  final String? username;
  final String? displayName;
  final bool isDefaultPassword;
  final bool showDefaultHint;
  final String? defaultUsername;
  final String? defaultPassword;
  final String? accessToken;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      authenticated: json['authenticated'] as bool? ?? false,
      username: json['username'] as String?,
      displayName: json['display_name'] as String?,
      isDefaultPassword: json['is_default_password'] as bool? ?? false,
      showDefaultHint: json['show_default_hint'] as bool? ?? false,
      defaultUsername: json['default_username'] as String?,
      defaultPassword: json['default_password'] as String?,
      accessToken: json['access_token'] as String?,
    );
  }
}

class ThresholdsModel {
  const ThresholdsModel({
    required this.glucoseLowUrgent,
    required this.glucoseFastingMax,
    required this.glucoseBeforeMealMax,
    required this.glucoseAfterMealMax,
    required this.glucoseRandomMax,
    required this.glucoseHighUrgent,
    required this.bpLowSystolic,
    required this.bpLowDiastolic,
    required this.bpAttentionSystolic,
    required this.bpAttentionDiastolic,
    required this.bpUrgentSystolic,
    required this.bpUrgentDiastolic,
    required this.hrLow,
    required this.hrHigh,
    required this.hrUrgentLow,
    required this.hrUrgentHigh,
  });

  final double glucoseLowUrgent;
  final double glucoseFastingMax;
  final double glucoseBeforeMealMax;
  final double glucoseAfterMealMax;
  final double glucoseRandomMax;
  final double glucoseHighUrgent;
  final int bpLowSystolic;
  final int bpLowDiastolic;
  final int bpAttentionSystolic;
  final int bpAttentionDiastolic;
  final int bpUrgentSystolic;
  final int bpUrgentDiastolic;
  final int hrLow;
  final int hrHigh;
  final int hrUrgentLow;
  final int hrUrgentHigh;

  factory ThresholdsModel.fromJson(Map<String, dynamic> json) {
    return ThresholdsModel(
      glucoseLowUrgent: (json['glucose_low_urgent'] as num).toDouble(),
      glucoseFastingMax: (json['glucose_fasting_max'] as num).toDouble(),
      glucoseBeforeMealMax: (json['glucose_before_meal_max'] as num).toDouble(),
      glucoseAfterMealMax: (json['glucose_after_meal_max'] as num).toDouble(),
      glucoseRandomMax: (json['glucose_random_max'] as num).toDouble(),
      glucoseHighUrgent: (json['glucose_high_urgent'] as num).toDouble(),
      bpLowSystolic: (json['bp_low_systolic'] as num).toInt(),
      bpLowDiastolic: (json['bp_low_diastolic'] as num).toInt(),
      bpAttentionSystolic: (json['bp_attention_systolic'] as num).toInt(),
      bpAttentionDiastolic: (json['bp_attention_diastolic'] as num).toInt(),
      bpUrgentSystolic: (json['bp_urgent_systolic'] as num).toInt(),
      bpUrgentDiastolic: (json['bp_urgent_diastolic'] as num).toInt(),
      hrLow: (json['hr_low'] as num).toInt(),
      hrHigh: (json['hr_high'] as num).toInt(),
      hrUrgentLow: (json['hr_urgent_low'] as num).toInt(),
      hrUrgentHigh: (json['hr_urgent_high'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'glucose_low_urgent': glucoseLowUrgent,
      'glucose_fasting_max': glucoseFastingMax,
      'glucose_before_meal_max': glucoseBeforeMealMax,
      'glucose_after_meal_max': glucoseAfterMealMax,
      'glucose_random_max': glucoseRandomMax,
      'glucose_high_urgent': glucoseHighUrgent,
      'bp_low_systolic': bpLowSystolic,
      'bp_low_diastolic': bpLowDiastolic,
      'bp_attention_systolic': bpAttentionSystolic,
      'bp_attention_diastolic': bpAttentionDiastolic,
      'bp_urgent_systolic': bpUrgentSystolic,
      'bp_urgent_diastolic': bpUrgentDiastolic,
      'hr_low': hrLow,
      'hr_high': hrHigh,
      'hr_urgent_low': hrUrgentLow,
      'hr_urgent_high': hrUrgentHigh,
    };
  }

  double targetMaxForType(String glucoseType) {
    switch (glucoseType) {
      case 'Fasting':
        return glucoseFastingMax;
      case 'Before Meal':
        return glucoseBeforeMealMax;
      case 'After Meal':
        return glucoseAfterMealMax;
      case 'Random':
        return glucoseRandomMax;
      default:
        return glucoseFastingMax;
    }
  }
}

class EvaluationResult {
  const EvaluationResult({
    required this.statusLevel,
    required this.statusLabel,
    required this.color,
    required this.withinTarget,
    required this.summary,
    this.warningMessage,
    required this.targetRangeText,
  });

  final String statusLevel;
  final String statusLabel;
  final String color;
  final bool withinTarget;
  final String summary;
  final String? warningMessage;
  final String targetRangeText;

  factory EvaluationResult.fromJson(Map<String, dynamic> json) {
    return EvaluationResult(
      statusLevel: json['status_level'] as String,
      statusLabel: json['status_label'] as String,
      color: json['color'] as String,
      withinTarget: json['within_target'] as bool,
      summary: json['summary'] as String,
      warningMessage: json['warning_message'] as String?,
      targetRangeText: json['target_range_text'] as String,
    );
  }
}

class HealthReading {
  const HealthReading({
    required this.id,
    required this.category,
    required this.recordedAt,
    required this.createdAt,
    this.glucoseValue,
    this.glucoseType,
    this.systolic,
    this.diastolic,
    this.heartRate,
    required this.evaluation,
  });

  final int id;
  final String category;
  final String recordedAt;
  final String createdAt;
  final double? glucoseValue;
  final String? glucoseType;
  final int? systolic;
  final int? diastolic;
  final int? heartRate;
  final EvaluationResult evaluation;

  factory HealthReading.fromJson(Map<String, dynamic> json) {
    return HealthReading(
      id: (json['id'] as num).toInt(),
      category: json['category'] as String,
      recordedAt: json['recorded_at'] as String,
      createdAt: json['created_at'] as String,
      glucoseValue: (json['glucose_value'] as num?)?.toDouble(),
      glucoseType: json['glucose_type'] as String?,
      systolic: (json['systolic'] as num?)?.toInt(),
      diastolic: (json['diastolic'] as num?)?.toInt(),
      heartRate: (json['heart_rate'] as num?)?.toInt(),
      evaluation: EvaluationResult.fromJson(
        json['evaluation'] as Map<String, dynamic>,
      ),
    );
  }
}

class ReminderItem {
  const ReminderItem({
    required this.key,
    required this.title,
    required this.timeOfDay,
    required this.enabled,
    required this.note,
  });

  final String key;
  final String title;
  final String timeOfDay;
  final bool enabled;
  final String note;

  factory ReminderItem.fromJson(Map<String, dynamic> json) {
    return ReminderItem(
      key: json['key'] as String,
      title: json['title'] as String,
      timeOfDay: json['time_of_day'] as String,
      enabled: json['enabled'] as bool,
      note: json['note'] as String? ?? '',
    );
  }
}

class DashboardData {
  const DashboardData({
    required this.displayName,
    this.latestGlucose,
    this.latestBp,
    this.latestHeartRate,
    this.latestHeartRateAt,
    this.latestHeartRateStatus,
    this.lastRecordedAt,
    required this.healthStatus,
    required this.healthStatusColor,
    required this.thresholds,
    required this.dueReminders,
  });

  final String displayName;
  final HealthReading? latestGlucose;
  final HealthReading? latestBp;
  final int? latestHeartRate;
  final String? latestHeartRateAt;
  final EvaluationResult? latestHeartRateStatus;
  final String? lastRecordedAt;
  final String healthStatus;
  final String healthStatusColor;
  final ThresholdsModel thresholds;
  final List<ReminderItem> dueReminders;

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      displayName: json['display_name'] as String? ?? 'Patient',
      latestGlucose: json['latest_glucose'] != null
          ? HealthReading.fromJson(json['latest_glucose'] as Map<String, dynamic>)
          : null,
      latestBp: json['latest_bp'] != null
          ? HealthReading.fromJson(json['latest_bp'] as Map<String, dynamic>)
          : null,
      latestHeartRate: (json['latest_heart_rate'] as num?)?.toInt(),
      latestHeartRateAt: json['latest_heart_rate_at'] as String?,
      latestHeartRateStatus: json['latest_heart_rate_status'] != null
          ? EvaluationResult.fromJson(
              json['latest_heart_rate_status'] as Map<String, dynamic>,
            )
          : null,
      lastRecordedAt: json['last_recorded_at'] as String?,
      healthStatus: json['health_status'] as String,
      healthStatusColor: json['health_status_color'] as String,
      thresholds: ThresholdsModel.fromJson(
        json['thresholds'] as Map<String, dynamic>,
      ),
      dueReminders: (json['due_reminders'] as List<dynamic>? ?? [])
          .map((item) => ReminderItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class GlucoseChartPoint {
  const GlucoseChartPoint({
    required this.id,
    required this.recordedAt,
    required this.glucoseValue,
    required this.glucoseType,
    required this.statusLevel,
  });

  final int id;
  final String recordedAt;
  final double glucoseValue;
  final String glucoseType;
  final String statusLevel;

  factory GlucoseChartPoint.fromJson(Map<String, dynamic> json) {
    return GlucoseChartPoint(
      id: (json['id'] as num).toInt(),
      recordedAt: json['recorded_at'] as String,
      glucoseValue: (json['glucose_value'] as num).toDouble(),
      glucoseType: json['glucose_type'] as String,
      statusLevel: json['status_level'] as String,
    );
  }
}

class BPChartPoint {
  const BPChartPoint({
    required this.id,
    required this.recordedAt,
    required this.systolic,
    required this.diastolic,
    this.heartRate,
    required this.statusLevel,
  });

  final int id;
  final String recordedAt;
  final int systolic;
  final int diastolic;
  final int? heartRate;
  final String statusLevel;

  factory BPChartPoint.fromJson(Map<String, dynamic> json) {
    return BPChartPoint(
      id: (json['id'] as num).toInt(),
      recordedAt: json['recorded_at'] as String,
      systolic: (json['systolic'] as num).toInt(),
      diastolic: (json['diastolic'] as num).toInt(),
      heartRate: (json['heart_rate'] as num?)?.toInt(),
      statusLevel: json['status_level'] as String,
    );
  }
}

class ChartTrendSummary {
  const ChartTrendSummary({
    required this.direction,
    this.delta,
    required this.message,
  });

  final String direction;
  final double? delta;
  final String message;

  factory ChartTrendSummary.fromJson(Map<String, dynamic> json) {
    return ChartTrendSummary(
      direction: json['direction'] as String,
      delta: (json['delta'] as num?)?.toDouble(),
      message: json['message'] as String,
    );
  }
}

class ChartsData {
  const ChartsData({
    required this.period,
    required this.glucosePoints,
    required this.glucoseTrend,
    required this.bpPoints,
    required this.bpSystolicTrend,
    required this.bpDiastolicTrend,
    required this.thresholds,
  });

  final String period;
  final List<GlucoseChartPoint> glucosePoints;
  final ChartTrendSummary glucoseTrend;
  final List<BPChartPoint> bpPoints;
  final ChartTrendSummary bpSystolicTrend;
  final ChartTrendSummary bpDiastolicTrend;
  final ThresholdsModel thresholds;

  factory ChartsData.fromJson(Map<String, dynamic> json) {
    return ChartsData(
      period: json['period'] as String,
      glucosePoints: (json['glucose_points'] as List<dynamic>? ?? [])
          .map((item) => GlucoseChartPoint.fromJson(item as Map<String, dynamic>))
          .toList(),
      glucoseTrend: ChartTrendSummary.fromJson(
        json['glucose_trend'] as Map<String, dynamic>,
      ),
      bpPoints: (json['bp_points'] as List<dynamic>? ?? [])
          .map((item) => BPChartPoint.fromJson(item as Map<String, dynamic>))
          .toList(),
      bpSystolicTrend: ChartTrendSummary.fromJson(
        json['bp_systolic_trend'] as Map<String, dynamic>,
      ),
      bpDiastolicTrend: ChartTrendSummary.fromJson(
        json['bp_diastolic_trend'] as Map<String, dynamic>,
      ),
      thresholds: ThresholdsModel.fromJson(
        json['thresholds'] as Map<String, dynamic>,
      ),
    );
  }
}

