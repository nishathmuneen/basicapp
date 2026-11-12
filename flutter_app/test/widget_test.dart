import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_health_tracker/main.dart';
import 'package:my_health_tracker/screens/account_sheet.dart';
import 'package:my_health_tracker/screens/charts_screen.dart';
import 'package:my_health_tracker/screens/dashboard_screen.dart';
import 'package:my_health_tracker/screens/record_bp_sheet.dart';
import 'package:my_health_tracker/screens/record_glucose_sheet.dart';
import 'package:my_health_tracker/screens/record_lifestyle_sheet.dart';
import 'package:my_health_tracker/services/health_evaluator.dart';
import 'package:my_health_tracker/services/health_repository.dart';
import 'package:my_health_tracker/services/lifestyle_advisor.dart';
import 'package:my_health_tracker/widgets/app_chrome.dart';

void main() {
  group('LocalHealthRepository unit tests', () {
    test('evaluates all 4 warnings, filters daily/weekly/monthly, and persists across instances',
        () async {
      final sharedStore = <String, String>{};
      final repo1 = LocalHealthRepository(testStore: sharedStore);

      // Default session state
      final initialSession = await repo1.getSession();
      expect(initialSession.authenticated, isFalse);
      expect(initialSession.showDefaultHint, isTrue);
      expect(initialSession.defaultUsername, 'patient');
      expect(initialSession.defaultPassword, 'health123');

      // Wrong password rejected
      await expectLater(
        repo1.login(username: 'patient', password: 'wrong'),
        throwsA(isA<StoreException>()),
      );

      // Valid login
      final signedIn = await repo1.login(username: 'patient', password: 'health123');
      expect(signedIn.authenticated, isTrue);

      // Glucose evaluations
      final lowG = await repo1.createGlucoseReading(
        glucoseValue: 62,
        glucoseType: 'Before Meal',
        recordedAt: DateTime(2026, 11, 11, 8, 0),
      );
      expect(lowG.evaluation.color, 'red');
      expect(lowG.evaluation.warningMessage, lowGlucoseWarning);

      final highG = await repo1.createGlucoseReading(
        glucoseValue: 195,
        glucoseType: 'After Meal',
        recordedAt: DateTime(2026, 11, 8, 13, 0),
      );
      expect(highG.evaluation.color, 'yellow');
      expect(highG.evaluation.warningMessage, highGlucoseWarning);

      // Older reading (monthly only)
      await repo1.createGlucoseReading(
        glucoseValue: 220,
        glucoseType: 'Fasting',
        recordedAt: DateTime(2026, 10, 20, 8, 0),
      );

      // BP evaluations
      final highBp = await repo1.createBPReading(
        systolic: 142,
        diastolic: 90,
        heartRate: 76,
        recordedAt: DateTime(2026, 11, 11, 9, 0),
      );
      expect(highBp.evaluation.color, 'yellow');
      expect(highBp.evaluation.warningMessage, highBpWarning);

      final veryHighBp = await repo1.createBPReading(
        systolic: 184,
        diastolic: 122,
        heartRate: 84,
        recordedAt: DateTime(2026, 11, 11, 10, 0),
      );
      expect(veryHighBp.evaluation.color, 'red');
      expect(veryHighBp.evaluation.warningMessage, veryHighBpWarning);

      // Daily / Weekly / Monthly filtering
      final ref = DateTime(2026, 11, 11);
      final daily = await repo1.getReadings(period: 'daily', referenceDate: ref);
      expect(daily.length, 3);
      final weekly = await repo1.getReadings(period: 'weekly', referenceDate: ref);
      expect(weekly.length, 4);
      final monthly = await repo1.getReadings(period: 'monthly', referenceDate: ref);
      expect(monthly.length, 5);

      // Trend calculation (220 -> 195 -> 62 = decreasing)
      final charts = await repo1.getCharts(period: 'monthly', referenceDate: ref);
      expect(charts.glucoseTrend.direction, 'decreasing');

      // Threshold customization & reset
      final customThresholds = charts.thresholds;
      await repo1.updateThresholds(
        defaultThresholds.toJson().let((_) => customThresholds),
      );
      await repo1.resetThresholds();

      // Update credentials & simulate fresh app restart
      await repo1.updateCredentials(
        currentPassword: 'health123',
        username: 'maya',
        displayName: 'Maya',
        newPassword: 'newpass99',
      );
      await repo1.logout();

      final repo2 = LocalHealthRepository(testStore: sharedStore);
      final afterRestart = await repo2.getSession();
      expect(afterRestart.authenticated, isFalse);
      expect(afterRestart.showDefaultHint, isFalse);

      final relogin = await repo2.login(username: 'maya', password: 'newpass99');
      expect(relogin.displayName, 'Maya');
      final persistedReadings = await repo2.getReadings(period: 'all');
      expect(persistedReadings.length, 5);
    });
  });

  testWidgets('Full Flutter app workflow using local repository',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = LocalHealthRepository(testStore: <String, String>{});

    await tester.pumpWidget(MyHealthTrackerApp(repository: repository));
    await tester.pumpAndSettle();

    // 1. Sign in using default credentials
    expect(find.byType(AppBackground), findsOneWidget);
    expect(find.byType(AppLogoMark), findsOneWidget);
    expect(find.text('Default Login Details'), findsOneWidget);
    await tester.ensureVisible(find.text('Use Default Details'));
    await tester.tap(find.text('Use Default Details'));
    await tester.pump();
    await tester.ensureVisible(find.text('Sign In'));
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    // 2. Home Dashboard
    expect(find.byType(AppBackground), findsOneWidget);
    expect(find.byType(AppLogoMark), findsWidgets);
    expect(find.text('Welcome to My Health Tracker'), findsOneWidget);
    expect(find.text('Add Glucose Reading'), findsOneWidget);
    expect(find.text('Add BP Reading'), findsOneWidget);

    // 3. Record high glucose reading -> automatic warning
    await tester.tap(find.text('Add Glucose Reading'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '195');
    await tester.tap(find.text('After Meal'));
    await tester.ensureVisible(find.text('Save Glucose Reading'));
    await tester.tap(find.text('Save Glucose Reading'));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(RecordGlucoseSheet),
        matching: find.text(highGlucoseWarning),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(RecordGlucoseSheet),
        matching: find.text('Suggested Diet & Exercise Plan'),
      ),
      findsOneWidget,
    );
    await tester.ensureVisible(find.text('Done'));
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    // 4. Record severely elevated BP + heart rate -> Critical status
    await tester.tap(find.text('Add BP Reading'));
    await tester.pumpAndSettle();
    final bpFields = find.descendant(
      of: find.byType(RecordBPSheet),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(bpFields.at(0), '185');
    await tester.enterText(bpFields.at(1), '122');
    await tester.enterText(bpFields.at(2), '84');
    await tester.ensureVisible(find.text('Save BP Reading'));
    await tester.tap(find.text('Save BP Reading'));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(RecordBPSheet),
        matching: find.text(veryHighBpWarning),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(RecordBPSheet),
        matching: find.text('Suggested Diet & Exercise Plan'),
      ),
      findsOneWidget,
    );
    await tester.ensureVisible(find.text('Done'));
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    // 4b. Log Sleep & Weight and check updated plan
    await tester.tap(find.text('Log Sleep & Weight'));
    await tester.pumpAndSettle();
    final lifestyleFields = find.descendant(
      of: find.byType(RecordLifestyleSheet),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(lifestyleFields.at(0), '5.5');
    await tester.enterText(lifestyleFields.at(1), '72');
    await tester.ensureVisible(find.text('Save Sleep & Weight'));
    await tester.tap(find.text('Save Sleep & Weight'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(RecordLifestyleSheet),
        matching: find.text('Updated Diet & Exercise Plan'),
      ),
      findsOneWidget,
    );
    await tester.ensureVisible(find.text('Done'));
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(
      find.descendant(of: find.byType(DashboardScreen), matching: find.text('Critical')),
      findsOneWidget,
    );
    final dashboardList = find.descendant(
      of: find.byType(DashboardScreen),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(find.text('195'), 200, scrollable: dashboardList);
    expect(
      find.descendant(of: find.byType(DashboardScreen), matching: find.text('195')),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(find.text('185 / 122'), 200, scrollable: dashboardList);
    expect(
      find.descendant(of: find.byType(DashboardScreen), matching: find.text('185 / 122')),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(find.text('84'), 200, scrollable: dashboardList);
    expect(
      find.descendant(of: find.byType(DashboardScreen), matching: find.text('84')),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.text('5.5h · 72 kg'),
      200,
      scrollable: dashboardList,
    );
    expect(
      find.descendant(
        of: find.byType(DashboardScreen),
        matching: find.text('5.5h · 72 kg'),
      ),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.text("Today's Diet & Exercise Plan"),
      200,
      scrollable: dashboardList,
    );
    expect(
      find.descendant(
        of: find.byType(DashboardScreen),
        matching: find.text("Today's Diet & Exercise Plan"),
      ),
      findsOneWidget,
    );

    // 5. History Screen (Daily/Weekly/Monthly)
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(find.text('Health History'), findsOneWidget);
    expect(find.text('Daily'), findsOneWidget);
    expect(find.text('Weekly'), findsOneWidget);
    expect(find.text('Monthly'), findsOneWidget);

    // 6. Charts Screen
    await tester.tap(find.text('Charts'));
    await tester.pumpAndSettle();
    expect(find.text('Blood Glucose History'), findsOneWidget);
    final chartsList = find.descendant(
      of: find.byType(ChartsScreen),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      find.text('Blood Pressure History'),
      200,
      scrollable: chartsList,
    );
    expect(find.text('Blood Pressure History'), findsOneWidget);

    // 7. Reminders Screen
    await tester.tap(find.text('Reminders'));
    await tester.pumpAndSettle();
    expect(find.text('Morning glucose check'), findsOneWidget);
    expect(find.text('Evening glucose check'), findsOneWidget);
    expect(find.text('BP measurement'), findsOneWidget);

    // 8. Update Login Details & Sign Out
    await tester.tap(find.byTooltip('Login Details'));
    await tester.pumpAndSettle();
    final accountFields = find.descendant(
      of: find.byType(AccountSheet),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(accountFields.at(0), 'Maya');
    await tester.enterText(accountFields.at(2), 'health123');
    await tester.ensureVisible(find.text('Save Login Details'));
    await tester.tap(find.text('Save Login Details'));
    await tester.pumpAndSettle();
    expect(find.text('Your login details have been updated.'), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(AccountSheet),
        matching: find.byTooltip('Close'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Welcome back, Maya'),
      -200,
      scrollable: dashboardList,
    );
    expect(find.text('Welcome back, Maya'), findsOneWidget);

    await tester.tap(find.byTooltip('Sign Out'));
    await tester.pumpAndSettle();
    expect(find.text('Sign In'), findsOneWidget);
  });

  group('Lifestyle advisor and persistence', () {
    test('Low glucose safety override blocks exercise and prioritizes fast-acting carbs',
        () async {
      final store = <String, String>{};
      final repo = LocalHealthRepository(testStore: store);
      final reading = await repo.createGlucoseReading(
        glucoseValue: 62,
        glucoseType: 'Fasting',
        recordedAt: DateTime(2026, 3, 18, 8, 0),
      );
      final plan = await repo.buildLatestGuidancePlan(latestGlucoseOverride: reading);

      expect(plan.toneColor, 'red');
      expect(plan.exerciseSafetyLevel, 'blocked');
      expect(plan.safetyNote, contains('Low blood sugar'));
      expect(plan.dietTips.first, contains('15 g fast-acting carbohydrates'));
      expect(plan.exerciseRoutine.first, contains('Do not exercise right now'));
    });

    test('Urgent high BP pauses strenuous exercise and advises low-sodium meals',
        () async {
      final store = <String, String>{};
      final repo = LocalHealthRepository(testStore: store);
      final reading = await repo.createBPReading(
        systolic: 186,
        diastolic: 116,
        heartRate: 88,
        recordedAt: DateTime(2026, 3, 18, 9, 0),
      );
      final plan = await repo.buildLatestGuidancePlan(latestBpOverride: reading);

      expect(plan.toneColor, 'red');
      expect(plan.exerciseSafetyLevel, 'blocked');
      expect(plan.dietTips.join(' '), contains('low in sodium'));
      expect(plan.exerciseRoutine.join(' '), contains('Skip cardio'));
    });

    test('Elevated glucose + BP + short sleep + weight tailors gentle guidance and persists',
        () async {
      final store = <String, String>{};
      final repo = LocalHealthRepository(testStore: store);
      await repo.createGlucoseReading(
        glucoseValue: 196,
        glucoseType: 'After Meal',
        recordedAt: DateTime(2026, 3, 18, 13, 0),
      );
      await repo.createBPReading(
        systolic: 138,
        diastolic: 86,
        heartRate: 76,
        recordedAt: DateTime(2026, 3, 18, 13, 15),
      );
      await repo.createLifestyleReading(
        sleepHours: 5.0,
        recordedAt: DateTime(2026, 3, 18, 7, 30),
      );
      await repo.createLifestyleReading(
        weightKg: 78.5,
        recordedAt: DateTime(2026, 3, 18, 7, 45),
      );

      final reopenedRepo = LocalHealthRepository(testStore: store);
      final dashboard = await reopenedRepo.getDashboard(
        now: DateTime(2026, 3, 18, 14, 0),
      );

      expect(dashboard.latestLifestyle?.sleepHours, 5.0);
      expect(dashboard.latestLifestyle?.weightKg, 78.5);
      final plan = dashboard.guidancePlan!;
      expect(plan.toneColor, 'yellow');
      expect(plan.exerciseSafetyLevel, 'gentle');
      expect(plan.dietTips.first, contains('low-sodium, low-glycemic'));
      expect(plan.exerciseRoutine.first, contains('keep activity gentle'));
      expect(plan.sleepSummary, contains('5 hrs'));
      expect(plan.weightSummary, contains('78.5 kg'));
      expect(plan.disclaimer, wellnessDisclaimer);

      final baselinePlan = buildLifestylePlan();
      expect(baselinePlan.toneColor, 'green');
      expect(baselinePlan.exerciseSafetyLevel, 'standard');
    });
  });
}

extension _ScopeExt<T> on T {
  R let<R>(R Function(T) block) => block(this);
}
