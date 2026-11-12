import '../models/health_models.dart';
import '../utils/date_formatters.dart';

const String wellnessDisclaimer =
    'General wellness guidance only — not medical advice. Always follow your clinician\'s care plan for medications and target ranges.';

String formatHoursValue(double hours) {
  return hours % 1 == 0 ? hours.toStringAsFixed(0) : hours.toStringAsFixed(1);
}

String formatWeightKg(double kg) {
  return kg % 1 == 0 ? kg.toStringAsFixed(0) : kg.toStringAsFixed(1);
}

String _glucoseValueText(HealthReading reading) {
  final value = reading.glucoseValue;
  if (value == null) return 'Glucose logged';
  return '${formatGlucoseValue(value)} mg/dL (${reading.glucoseType ?? 'Random'})';
}

String _bpValueText(HealthReading reading) {
  if (reading.systolic == null || reading.diastolic == null) {
    return 'Blood pressure logged';
  }
  final hrPart = reading.heartRate != null ? ' · ${reading.heartRate} bpm' : '';
  return '${reading.systolic}/${reading.diastolic} mmHg$hrPart';
}

bool _isLowGlucose(HealthReading? glucose, ThresholdsModel thresholds) {
  if (glucose == null || glucose.glucoseValue == null) return false;
  return glucose.glucoseValue! < thresholds.glucoseLowUrgent ||
      glucose.evaluation.statusLabel.toLowerCase().contains('low');
}

bool _isLowBp(HealthReading? bp, ThresholdsModel thresholds) {
  if (bp == null || bp.systolic == null || bp.diastolic == null) return false;
  return bp.systolic! < thresholds.bpLowSystolic ||
      bp.diastolic! < thresholds.bpLowDiastolic ||
      bp.evaluation.statusLabel.toLowerCase().contains('low');
}

/// Builds a deterministic, safety-first offline diet & exercise plan from the
/// user's latest glucose, blood pressure/heart rate, sleep hours, and weight.
DailyGuidancePlan buildLifestylePlan({
  HealthReading? latestGlucose,
  HealthReading? latestBp,
  EvaluationResult? latestHeartRateStatus,
  LifestyleReading? latestLifestyle,
  ThresholdsModel? thresholds,
}) {
  final activeThresholds = thresholds ??
      const ThresholdsModel(
        glucoseLowUrgent: 70,
        glucoseFastingMax: 125,
        glucoseBeforeMealMax: 130,
        glucoseAfterMealMax: 180,
        glucoseRandomMax: 160,
        glucoseHighUrgent: 250,
        bpLowSystolic: 90,
        bpLowDiastolic: 60,
        bpAttentionSystolic: 130,
        bpAttentionDiastolic: 80,
        bpUrgentSystolic: 180,
        bpUrgentDiastolic: 120,
        hrLow: 50,
        hrHigh: 100,
        hrUrgentLow: 40,
        hrUrgentHigh: 130,
      );

  final glucoseColor = latestGlucose?.evaluation.color;
  final bpColor = latestBp?.evaluation.color;
  final hrColor = latestHeartRateStatus?.color;

  final isGlucoseRed = glucoseColor == 'red';
  final isBpRed = bpColor == 'red' || hrColor == 'red';
  final isLowSugar = isGlucoseRed && _isLowGlucose(latestGlucose, activeThresholds);
  final isHighSugarUrgent = isGlucoseRed && !isLowSugar;
  final isLowPressure = bpColor == 'red' && _isLowBp(latestBp, activeThresholds);

  final isGlucoseYellow = glucoseColor == 'yellow';
  final isBpYellow = bpColor == 'yellow' || hrColor == 'yellow';

  final sleepHours = latestLifestyle?.sleepHours;
  final weightKg = latestLifestyle?.weightKg;
  final shortSleep = sleepHours != null && sleepHours < 6.0;
  final longSleep = sleepHours != null && sleepHours > 9.0;

  String? sleepSummary;
  if (sleepHours != null) {
    final h = formatHoursValue(sleepHours);
    if (shortSleep) {
      sleepSummary =
          'Sleep: $h hrs — short rest detected; dialing back workout intensity and prioritizing recovery.';
    } else if (longSleep) {
      sleepSummary =
          'Sleep: $h hrs — extra rest logged; light morning movement can help energy.';
    } else {
      sleepSummary =
          'Sleep: $h hrs — steady rest supports glucose and blood pressure recovery.';
    }
  }

  String? weightSummary;
  if (weightKg != null) {
    final lbs = (weightKg * 2.20462262).toStringAsFixed(1);
    weightSummary =
        'Weight: ${formatWeightKg(weightKg)} kg ($lbs lbs) — paired with balanced portions and daily movement.';
  }

  // 1. Safety-first red alerts: pause strenuous exercise immediately.
  if (isGlucoseRed || isBpRed) {
    final safetyNotes = <String>[];
    final dietTips = <String>[];
    final exerciseRoutine = <String>[];

    if (isLowSugar) {
      safetyNotes.add(
        'Low blood sugar (${_glucoseValueText(latestGlucose!)}): pause exercise immediately, take fast-acting carbs, and re-check in 15 minutes.',
      );
      dietTips.addAll([
        'Take ~15 g fast-acting carbohydrates right away (4 oz fruit juice, 3–4 glucose tablets, or 1 tbsp sugar/honey).',
        'Once glucose returns above ${formatGlucoseValue(activeThresholds.glucoseLowUrgent)} mg/dL, eat a small protein + slow-carb snack (whole-grain crackers with peanut butter or cheese).',
      ]);
      exerciseRoutine.add(
        'Do not exercise right now. Rest calmly until blood sugar stays stable in your safe range.',
      );
    } else if (isHighSugarUrgent) {
      safetyNotes.add(
        'Urgent high blood sugar (${_glucoseValueText(latestGlucose!)}): skip vigorous exercise, hydrate with plain water, and contact a clinician if levels stay elevated or you feel unwell.',
      );
      dietTips.addAll([
        'Drink plain water steadily and avoid fruit juices, sweetened beverages, white bread, and desserts.',
        'If eating, keep portions small and focus on non-starchy vegetables with lean protein.',
      ]);
      exerciseRoutine.add(
        'Pause workouts for now. Rest, hydrate, and follow your care plan before resuming activity.',
      );
    }

    if (isBpRed) {
      final bpContext = latestBp != null
          ? _bpValueText(latestBp)
          : 'Heart rate requires urgent attention';
      if (isLowPressure || latestHeartRateStatus?.statusLabel.toLowerCase().contains('low') == true) {
        safetyNotes.add(
          'Low blood pressure / pulse ($bpContext): avoid sudden standing or intense workouts; sit or lie down and seek medical advice if dizzy or faint.',
        );
        dietTips.add(
          'Sip water slowly to stay hydrated and avoid heavy high-carb meals in one sitting.',
        );
      } else {
        safetyNotes.add(
          'Urgent blood pressure / pulse ($bpContext): rest quietly for 5–10 minutes, avoid straining or lifting, and seek prompt clinical advice if readings remain high.',
        );
        dietTips.addAll([
          'Keep remaining meals very low in sodium — skip pickles, packaged sauces, salted snacks, and processed meats.',
          'Choose steamed or fresh vegetables, beans, unsalted oats, and plain water.',
        ]);
      }
      exerciseRoutine.add(
        'Skip cardio, heavy lifting, and HIIT today. Sit quietly and try 5 minutes of slow, gentle nasal breathing.',
      );
    }

    if (shortSleep) {
      dietTips.add(
        'Because sleep was under 6 hours (${formatHoursValue(sleepHours)} hrs), avoid extra caffeine or sugary pick-me-ups that can destabilize vitals.',
      );
    }

    return DailyGuidancePlan(
      headline: 'Safety First: Rest & Stabilize Today',
      toneColor: 'red',
      exerciseSafetyLevel: 'blocked',
      safetyNote: safetyNotes.join(' '),
      dietTips: dietTips,
      exerciseRoutine: exerciseRoutine,
      sleepSummary: sleepSummary,
      weightSummary: weightSummary,
      disclaimer: wellnessDisclaimer,
    );
  }

  // 2. Non-urgent elevated / normal vitals + sleep + weight customization.
  final dietTips = <String>[];
  final exerciseRoutine = <String>[];
  String toneColor = 'green';
  String headline = 'Steady Daily Routine';
  String exerciseSafetyLevel = shortSleep ? 'gentle' : 'standard';

  if (isGlucoseYellow && isBpYellow) {
    toneColor = 'yellow';
    headline = 'Balance Blood Sugar & Blood Pressure';
    dietTips.addAll([
      'Build a low-sodium, low-glycemic plate: fill 1/2 with non-starchy vegetables, 1/4 with lean protein, and 1/4 with high-fiber whole grains or lentils.',
      'Season with garlic, lemon, turmeric, or fresh herbs instead of table salt, and skip sugary drinks and fried snacks.',
    ]);
  } else if (isGlucoseYellow) {
    toneColor = 'yellow';
    headline = 'Support Steady Blood Sugar';
    final gType = latestGlucose?.glucoseType ?? 'Random';
    if (gType == 'After Meal' || gType == 'Random') {
      dietTips.addAll([
        'Pair carbohydrates with fiber and protein (greens, beans, nuts, eggs, or grilled fish/tofu) to blunt post-meal spikes.',
        'Swap refined carbs and sweet drinks for water, unsweetened tea, and whole-food fiber options.',
      ]);
    } else {
      dietTips.addAll([
        'Start your next meal with protein and vegetables before starches (e.g., eggs or plain yogurt with greens/berries instead of sweet breakfast foods).',
        'Space meals evenly and avoid sweetened beverages or juices on an empty stomach.',
      ]);
    }
  } else if (isBpYellow) {
    toneColor = 'yellow';
    headline = 'Heart-Healthy Low-Sodium Day';
    dietTips.addAll([
      'Limit added salt and packaged sauces today; favor potassium-rich whole foods like spinach, broccoli, bananas, avocado, and beans.',
      'Choose fresh home-prepared meals with olive oil, herbs, and citrus over canned soups or salty snacks.',
    ]);
  } else {
    dietTips.addAll([
      'Keep meals balanced with high-fiber vegetables, lean protein, whole grains, and steady plain water throughout the day.',
      'Maintain regular meal timing to keep energy, blood sugar, and blood pressure steady.',
    ]);
  }

  if (shortSleep) {
    dietTips.add(
      'Short sleep (${formatHoursValue(sleepHours)} hrs): eat a protein-plus-fiber meal early to curb cravings and taper caffeine after early afternoon.',
    );
  } else if (weightKg != null) {
    dietTips.add(
      'For weight support (${formatWeightKg(weightKg)} kg): drink a glass of water before meals, eat slowly, and stop at comfortable fullness.',
    );
  }

  // Exercise routine tailored by vitals, post-meal state, sleep, and weight.
  if (shortSleep) {
    exerciseRoutine.addAll([
      'Because sleep was ${formatHoursValue(sleepHours)} hrs, keep activity gentle: 15–20 minutes of easy walking plus light mobility or stretching.',
      'Aim for an earlier wind-down routine tonight without screens 30 minutes before bed.',
    ]);
  } else {
    final gType = latestGlucose?.glucoseType ?? '';
    if (isGlucoseYellow && (gType == 'After Meal' || gType == 'Random')) {
      exerciseRoutine.add(
        'Take an easy-to-moderate 10–15 minute walk within 30 minutes after meals to help muscles absorb glucose naturally.',
      );
    } else if (isBpYellow) {
      exerciseRoutine.add(
        'Do 25–30 minutes of steady, moderate movement (brisk walking, flat cycling, or swimming) and avoid holding your breath during effort.',
      );
    } else {
      exerciseRoutine.add(
        'Aim for 30 minutes of brisk walking or cycling today (even split into two 15-minute walks).',
      );
    }

    if (isBpYellow) {
      exerciseRoutine.add(
        'Finish with 5 minutes of slow relaxed breathing (4 seconds inhale, 6 seconds exhale) to support calmer blood pressure.',
      );
    } else {
      exerciseRoutine.add(
        'Add 10 minutes of gentle bodyweight strength or joint-friendly mobility work (squats to a chair, wall push-ups, or resistance bands).',
      );
    }
  }

  if (longSleep) {
    exerciseRoutine.add(
      'Try getting natural morning light during a short 10-minute walk to reset your daily rhythm.',
    );
  }

  String? safetyNote;
  if (toneColor == 'yellow') {
    safetyNote =
        'Vitals are slightly outside target. Stick to conversational-pace movement (you can talk comfortably) and stop right away if you feel dizzy, chest pain, or shortness of breath.';
  }

  return DailyGuidancePlan(
    headline: headline,
    toneColor: toneColor,
    exerciseSafetyLevel: exerciseSafetyLevel,
    safetyNote: safetyNote,
    dietTips: dietTips,
    exerciseRoutine: exerciseRoutine,
    sleepSummary: sleepSummary,
    weightSummary: weightSummary,
    disclaimer: wellnessDisclaimer,
  );
}

