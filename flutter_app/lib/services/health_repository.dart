import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/health_models.dart';
import '../utils/date_formatters.dart';
import 'health_evaluator.dart';
import 'kv_storage_stub.dart'
    if (dart.library.js_interop) 'kv_storage_web.dart'
    if (dart.library.io) 'kv_storage_io.dart';
import 'password_hasher.dart';

class StoreException implements Exception {
  StoreException(this.message);

  final String message;

  @override
  String toString() => message;
}

class LocalHealthRepository {
  LocalHealthRepository({
    this.forcePrefsStorage = false,
    this.testStore,
  });

  static const String defaultUsername = 'patient';
  static const String defaultPassword = 'health123';
  static const String _prefsKey = 'mht_local_store_v1';

  final bool forcePrefsStorage;
  final Map<String, String>? testStore;
  Database? _db;

  bool get _useSqflite =>
      testStore == null && !forcePrefsStorage && !kIsWeb && supportsNativeSqflite;

  List<Map<String, dynamic>> _defaultRemindersList() => [
        {
          'key': 'morning_glucose',
          'title': 'Morning glucose check',
          'time_of_day': '08:00',
          'enabled': 1,
          'note': 'Check before breakfast if advised by your care plan.',
        },
        {
          'key': 'evening_glucose',
          'title': 'Evening glucose check',
          'time_of_day': '20:00',
          'enabled': 1,
          'note': 'Evening blood sugar check.',
        },
        {
          'key': 'bp_measurement',
          'title': 'BP measurement',
          'time_of_day': '09:00',
          'enabled': 1,
          'note': 'Sit quietly for 5 minutes before measuring.',
        },
      ];

  Future<Database> _getDb() async {
    if (_db != null) return _db!;
    final dbDir = await getDatabasesPath();
    final dbPath = p.join(dbDir, 'health_tracker.db');
    _db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE readings (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            category TEXT NOT NULL CHECK (category IN ('glucose', 'bp')),
            recorded_at TEXT NOT NULL,
            created_at TEXT NOT NULL,
            glucose_value REAL,
            glucose_type TEXT,
            systolic INTEGER,
            diastolic INTEGER,
            heart_rate INTEGER
          )
        ''');
        await db.execute('''
          CREATE INDEX idx_readings_recorded_at
          ON readings (recorded_at DESC, id DESC)
        ''');
        await db.execute('''
          CREATE TABLE thresholds (
            id INTEGER PRIMARY KEY CHECK (id = 1),
            glucose_low_urgent REAL NOT NULL,
            glucose_fasting_max REAL NOT NULL,
            glucose_before_meal_max REAL NOT NULL,
            glucose_after_meal_max REAL NOT NULL,
            glucose_random_max REAL NOT NULL,
            glucose_high_urgent REAL NOT NULL,
            bp_low_systolic INTEGER NOT NULL,
            bp_low_diastolic INTEGER NOT NULL,
            bp_attention_systolic INTEGER NOT NULL,
            bp_attention_diastolic INTEGER NOT NULL,
            bp_urgent_systolic INTEGER NOT NULL,
            bp_urgent_diastolic INTEGER NOT NULL,
            hr_low INTEGER NOT NULL,
            hr_high INTEGER NOT NULL,
            hr_urgent_low INTEGER NOT NULL,
            hr_urgent_high INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE reminders (
            key TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            time_of_day TEXT NOT NULL,
            enabled INTEGER NOT NULL CHECK (enabled IN (0, 1)),
            note TEXT NOT NULL DEFAULT ''
          )
        ''');
        await db.execute('''
          CREATE TABLE user_account (
            id INTEGER PRIMARY KEY CHECK (id = 1),
            username TEXT NOT NULL,
            display_name TEXT NOT NULL DEFAULT 'Patient',
            password_hash TEXT NOT NULL,
            is_default_password INTEGER NOT NULL DEFAULT 1,
            authenticated INTEGER NOT NULL DEFAULT 0
          )
        ''');
      },
    );
    await _seedSqliteDefaults(_db!);
    return _db!;
  }

  Future<void> _seedSqliteDefaults(Database db) async {
    final tRows = await db.query('thresholds', where: 'id = 1');
    if (tRows.isEmpty) {
      await db.insert('thresholds', {'id': 1, ...defaultThresholds.toJson()});
    }
    for (final rem in _defaultRemindersList()) {
      await db.insert(
        'reminders',
        rem,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    final accRows = await db.query('user_account', where: 'id = 1');
    if (accRows.isEmpty) {
      await db.insert('user_account', {
        'id': 1,
        'username': defaultUsername,
        'display_name': 'Patient',
        'password_hash': PasswordHasher.hashPassword(defaultPassword),
        'is_default_password': 1,
        'authenticated': 0,
      });
    }
  }

  Future<Map<String, dynamic>> _loadPrefsState() async {
    final raw = testStore != null
        ? testStore![_prefsKey]
        : await readLocalStore(_prefsKey);
    if (raw != null && raw.isNotEmpty) {
      return jsonDecode(raw) as Map<String, dynamic>;
    }
    final initial = <String, dynamic>{
      'next_id': 1,
      'readings': <Map<String, dynamic>>[],
      'thresholds': defaultThresholds.toJson(),
      'reminders': _defaultRemindersList(),
      'account': {
        'username': defaultUsername,
        'display_name': 'Patient',
        'password_hash': PasswordHasher.hashPassword(defaultPassword),
        'is_default_password': 1,
        'authenticated': 0,
      },
    };
    await _savePrefsState(initial);
    return initial;
  }

  Future<void> _savePrefsState(Map<String, dynamic> state) async {
    final encoded = jsonEncode(state);
    if (testStore != null) {
      testStore![_prefsKey] = encoded;
      return;
    }
    await writeLocalStore(_prefsKey, encoded);
  }

  Future<ThresholdsModel> _readThresholds() async {
    if (_useSqflite) {
      final db = await _getDb();
      final rows = await db.query('thresholds', where: 'id = 1');
      if (rows.isEmpty) return defaultThresholds;
      return ThresholdsModel.fromJson(rows.first);
    }
    final state = await _loadPrefsState();
    return ThresholdsModel.fromJson(
      Map<String, dynamic>.from(state['thresholds'] as Map),
    );
  }

  HealthReading _buildReading(Map<String, dynamic> row, ThresholdsModel thresholds) {
    final category = row['category'] as String;
    final evaluation = category == 'glucose'
        ? evaluateGlucose(
            glucoseValue: (row['glucose_value'] as num).toDouble(),
            glucoseType: row['glucose_type'] as String,
            thresholds: thresholds,
          )
        : evaluateBloodPressure(
            systolic: (row['systolic'] as num).toInt(),
            diastolic: (row['diastolic'] as num).toInt(),
            heartRate: (row['heart_rate'] as num?)?.toInt(),
            thresholds: thresholds,
          );

    return HealthReading(
      id: (row['id'] as num).toInt(),
      category: category,
      recordedAt: row['recorded_at'] as String,
      createdAt: row['created_at'] as String,
      glucoseValue: (row['glucose_value'] as num?)?.toDouble(),
      glucoseType: row['glucose_type'] as String?,
      systolic: (row['systolic'] as num?)?.toInt(),
      diastolic: (row['diastolic'] as num?)?.toInt(),
      heartRate: (row['heart_rate'] as num?)?.toInt(),
      evaluation: evaluation,
    );
  }

  (String?, String?) _periodBounds(String period, DateTime referenceDate) {
    if (period == 'all') return (null, null);
    final daysBack = switch (period) {
      'daily' => 0,
      'weekly' => 6,
      'monthly' => 29,
      _ => 6,
    };
    final ref = DateTime(referenceDate.year, referenceDate.month, referenceDate.day);
    final start = ref.subtract(Duration(days: daysBack));
    return ('${toApiDateString(start)}T00:00', '${toApiDateString(ref)}T23:59');
  }

  Future<List<Map<String, dynamic>>> _queryReadingRows({
    required String period,
    required String category,
    required DateTime referenceDate,
    bool ascending = false,
  }) async {
    final (startBound, endBound) = _periodBounds(period, referenceDate);
    final orderDir = ascending ? 'ASC' : 'DESC';

    if (_useSqflite) {
      final db = await _getDb();
      final where = <String>[];
      final args = <Object>[];
      if (category != 'all') {
        where.add('category = ?');
        args.add(category);
      }
      if (startBound != null && endBound != null) {
        where.add('recorded_at >= ? AND recorded_at <= ?');
        args.addAll([startBound, endBound]);
      }
      return db.query(
        'readings',
        where: where.isEmpty ? null : where.join(' AND '),
        whereArgs: args.isEmpty ? null : args,
        orderBy: 'recorded_at $orderDir, id $orderDir',
      );
    }

    final state = await _loadPrefsState();
    final rows = (state['readings'] as List<dynamic>)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .where((r) {
      if (category != 'all' && r['category'] != category) return false;
      final rec = r['recorded_at'] as String;
      if (startBound != null && endBound != null) {
        return rec.compareTo(startBound) >= 0 && rec.compareTo(endBound) <= 0;
      }
      return true;
    }).toList();

    rows.sort((a, b) {
      final cmp = (a['recorded_at'] as String).compareTo(b['recorded_at'] as String);
      if (cmp != 0) return ascending ? cmp : -cmp;
      final idCmp = (a['id'] as int).compareTo(b['id'] as int);
      return ascending ? idCmp : -idCmp;
    });
    return rows;
  }

  Future<Map<String, dynamic>> _readAccountRow() async {
    if (_useSqflite) {
      final db = await _getDb();
      final rows = await db.query('user_account', where: 'id = 1');
      return rows.first;
    }
    final state = await _loadPrefsState();
    return Map<String, dynamic>.from(state['account'] as Map);
  }

  Future<AuthSession> getSession() async {
    final acc = await _readAccountRow();
    final isAuth = (acc['authenticated'] as num?)?.toInt() == 1;
    final isDefault = (acc['is_default_password'] as num?)?.toInt() == 1;
    if (isAuth) {
      return AuthSession(
        authenticated: true,
        username: acc['username'] as String,
        displayName: acc['display_name'] as String,
        isDefaultPassword: isDefault,
      );
    }
    return AuthSession(
      authenticated: false,
      showDefaultHint: isDefault,
      defaultUsername: isDefault ? acc['username'] as String : null,
      defaultPassword: isDefault ? defaultPassword : null,
    );
  }

  Future<AuthSession> login({
    required String username,
    required String password,
  }) async {
    final acc = await _readAccountRow();
    final storedUser = (acc['username'] as String).trim().toLowerCase();
    final matchesUser = username.trim().toLowerCase() == storedUser;
    final matchesPass = PasswordHasher.verifyPassword(
      password,
      acc['password_hash'] as String,
    );
    if (!matchesUser || !matchesPass) {
      throw StoreException(
        'Incorrect username or password. Please check your login details and try again.',
      );
    }

    if (_useSqflite) {
      final db = await _getDb();
      await db.update('user_account', {'authenticated': 1}, where: 'id = 1');
    } else {
      final state = await _loadPrefsState();
      (state['account'] as Map<String, dynamic>)['authenticated'] = 1;
      await _savePrefsState(state);
    }

    return AuthSession(
      authenticated: true,
      username: acc['username'] as String,
      displayName: acc['display_name'] as String,
      isDefaultPassword: (acc['is_default_password'] as num?)?.toInt() == 1,
    );
  }

  Future<void> logout() async {
    if (_useSqflite) {
      final db = await _getDb();
      await db.update('user_account', {'authenticated': 0}, where: 'id = 1');
    } else {
      final state = await _loadPrefsState();
      (state['account'] as Map<String, dynamic>)['authenticated'] = 0;
      await _savePrefsState(state);
    }
  }

  Future<AuthSession> updateCredentials({
    required String currentPassword,
    required String username,
    required String displayName,
    String? newPassword,
  }) async {
    final trimmedUser = username.trim();
    final trimmedName = displayName.trim();
    if (trimmedUser.length < 2) {
      throw StoreException('Username must be at least 2 characters.');
    }
    if (trimmedName.isEmpty) {
      throw StoreException('Display name cannot be blank.');
    }
    if (newPassword != null && newPassword.isNotEmpty && newPassword.length < 6) {
      throw StoreException('New password must be at least 6 characters long.');
    }

    final acc = await _readAccountRow();
    if (!PasswordHasher.verifyPassword(currentPassword, acc['password_hash'] as String)) {
      throw StoreException('Current password is incorrect.');
    }

    final hasNewPass = newPassword != null && newPassword.isNotEmpty;
    final nextHash = hasNewPass
        ? PasswordHasher.hashPassword(newPassword)
        : acc['password_hash'] as String;
    final nextIsDefault = hasNewPass ? 0 : (acc['is_default_password'] as num).toInt();

    if (_useSqflite) {
      final db = await _getDb();
      await db.update(
        'user_account',
        {
          'username': trimmedUser,
          'display_name': trimmedName,
          'password_hash': nextHash,
          'is_default_password': nextIsDefault,
        },
        where: 'id = 1',
      );
    } else {
      final state = await _loadPrefsState();
      final account = state['account'] as Map<String, dynamic>;
      account['username'] = trimmedUser;
      account['display_name'] = trimmedName;
      account['password_hash'] = nextHash;
      account['is_default_password'] = nextIsDefault;
      await _savePrefsState(state);
    }

    return AuthSession(
      authenticated: true,
      username: trimmedUser,
      displayName: trimmedName,
      isDefaultPassword: nextIsDefault == 1,
    );
  }

  Future<DashboardData> getDashboard({DateTime? now}) async {
    final localNow = now ?? DateTime.now();
    final thresholds = await _readThresholds();
    final acc = await _readAccountRow();
    final reminders = await getReminders();
    final allRows = await _queryReadingRows(
      period: 'all',
      category: 'all',
      referenceDate: localNow,
    );

    Map<String, dynamic>? latestGlucoseRow;
    Map<String, dynamic>? latestBpRow;
    Map<String, dynamic>? latestHrRow;

    for (final row in allRows) {
      if (latestGlucoseRow == null && row['category'] == 'glucose') {
        latestGlucoseRow = row;
      }
      if (latestBpRow == null && row['category'] == 'bp') {
        latestBpRow = row;
      }
      if (latestHrRow == null && row['heart_rate'] != null) {
        latestHrRow = row;
      }
      if (latestGlucoseRow != null && latestBpRow != null && latestHrRow != null) {
        break;
      }
    }

    final latestGlucose =
        latestGlucoseRow != null ? _buildReading(latestGlucoseRow, thresholds) : null;
    final latestBp = latestBpRow != null ? _buildReading(latestBpRow, thresholds) : null;
    final latestHr = (latestHrRow?['heart_rate'] as num?)?.toInt();
    final latestHrStatus = latestHr != null
        ? evaluateHeartRate(heartRate: latestHr, thresholds: thresholds)
        : null;
    final (status, color) = computeDashboardStatus(
      latestGlucose?.evaluation,
      latestBp?.evaluation,
    );

    final todayRows = await _queryReadingRows(
      period: 'daily',
      category: 'all',
      referenceDate: localNow,
    );
    final nowHhMm =
        '${localNow.hour.toString().padLeft(2, '0')}:${localNow.minute.toString().padLeft(2, '0')}';
    final glucoseTimes = todayRows
        .where((r) => r['category'] == 'glucose')
        .map((r) => (r['recorded_at'] as String).substring(11, 16))
        .toList();
    final bpCountToday = todayRows.where((r) => r['category'] == 'bp').length;

    final due = <ReminderItem>[];
    for (final rem in reminders) {
      if (!rem.enabled || nowHhMm.compareTo(rem.timeOfDay) < 0) continue;
      bool done = false;
      if (rem.key == 'morning_glucose') {
        done = glucoseTimes.any((t) => t.compareTo('14:00') < 0);
      } else if (rem.key == 'evening_glucose') {
        done = glucoseTimes.any(
          (t) => t.compareTo(rem.timeOfDay) >= 0 || t.compareTo('17:00') >= 0,
        );
      } else if (rem.key == 'bp_measurement') {
        done = bpCountToday > 0;
      }
      if (!done) due.add(rem);
    }

    return DashboardData(
      displayName: acc['display_name'] as String,
      latestGlucose: latestGlucose,
      latestBp: latestBp,
      latestHeartRate: latestHr,
      latestHeartRateAt: latestHrRow?['recorded_at'] as String?,
      latestHeartRateStatus: latestHrStatus,
      lastRecordedAt: allRows.isNotEmpty ? allRows.first['recorded_at'] as String : null,
      healthStatus: status,
      healthStatusColor: color,
      thresholds: thresholds,
      dueReminders: due,
    );
  }

  Future<List<HealthReading>> getReadings({
    String period = 'weekly',
    String category = 'all',
    DateTime? referenceDate,
  }) async {
    final thresholds = await _readThresholds();
    final rows = await _queryReadingRows(
      period: period,
      category: category,
      referenceDate: referenceDate ?? DateTime.now(),
    );
    return rows.map((row) => _buildReading(row, thresholds)).toList();
  }

  Future<HealthReading> createGlucoseReading({
    required double glucoseValue,
    required String glucoseType,
    required DateTime recordedAt,
  }) async {
    if (glucoseValue < 20 || glucoseValue > 800) {
      throw StoreException('Enter a glucose reading between 20 and 800 mg/dL.');
    }
    final thresholds = await _readThresholds();
    final recStr = toApiDateTimeString(recordedAt);
    final createdStr = '${toApiDateTimeString(DateTime.now())}:00';

    late Map<String, dynamic> inserted;
    if (_useSqflite) {
      final db = await _getDb();
      final id = await db.insert('readings', {
        'category': 'glucose',
        'recorded_at': recStr,
        'created_at': createdStr,
        'glucose_value': glucoseValue,
        'glucose_type': glucoseType,
      });
      final rows = await db.query('readings', where: 'id = ?', whereArgs: [id]);
      inserted = rows.first;
    } else {
      final state = await _loadPrefsState();
      final id = state['next_id'] as int;
      state['next_id'] = id + 1;
      inserted = {
        'id': id,
        'category': 'glucose',
        'recorded_at': recStr,
        'created_at': createdStr,
        'glucose_value': glucoseValue,
        'glucose_type': glucoseType,
        'systolic': null,
        'diastolic': null,
        'heart_rate': null,
      };
      (state['readings'] as List<dynamic>).add(inserted);
      await _savePrefsState(state);
    }
    return _buildReading(inserted, thresholds);
  }

  Future<HealthReading> createBPReading({
    required int systolic,
    required int diastolic,
    int? heartRate,
    required DateTime recordedAt,
  }) async {
    if (systolic < 40 || systolic > 300 || diastolic < 20 || diastolic > 200) {
      throw StoreException('Please enter valid systolic (40–300) and diastolic (20–200) numbers.');
    }
    if (systolic <= diastolic) {
      throw StoreException('Systolic reading must be higher than diastolic reading.');
    }
    if (heartRate != null && (heartRate < 25 || heartRate > 250)) {
      throw StoreException('Heart rate must be between 25 and 250 bpm.');
    }

    final thresholds = await _readThresholds();
    final recStr = toApiDateTimeString(recordedAt);
    final createdStr = '${toApiDateTimeString(DateTime.now())}:00';

    late Map<String, dynamic> inserted;
    if (_useSqflite) {
      final db = await _getDb();
      final id = await db.insert('readings', {
        'category': 'bp',
        'recorded_at': recStr,
        'created_at': createdStr,
        'systolic': systolic,
        'diastolic': diastolic,
        'heart_rate': heartRate,
      });
      final rows = await db.query('readings', where: 'id = ?', whereArgs: [id]);
      inserted = rows.first;
    } else {
      final state = await _loadPrefsState();
      final id = state['next_id'] as int;
      state['next_id'] = id + 1;
      inserted = {
        'id': id,
        'category': 'bp',
        'recorded_at': recStr,
        'created_at': createdStr,
        'glucose_value': null,
        'glucose_type': null,
        'systolic': systolic,
        'diastolic': diastolic,
        'heart_rate': heartRate,
      };
      (state['readings'] as List<dynamic>).add(inserted);
      await _savePrefsState(state);
    }
    return _buildReading(inserted, thresholds);
  }

  Future<void> deleteReading(int id) async {
    if (_useSqflite) {
      final db = await _getDb();
      await db.delete('readings', where: 'id = ?', whereArgs: [id]);
      return;
    }
    final state = await _loadPrefsState();
    (state['readings'] as List<dynamic>).removeWhere(
      (item) => (item as Map)['id'] == id,
    );
    await _savePrefsState(state);
  }

  Future<ChartsData> getCharts({
    String period = 'weekly',
    DateTime? referenceDate,
  }) async {
    final thresholds = await _readThresholds();
    final rows = await _queryReadingRows(
      period: period,
      category: 'all',
      referenceDate: referenceDate ?? DateTime.now(),
      ascending: true,
    );

    final glucosePts = <GlucoseChartPoint>[];
    final bpPts = <BPChartPoint>[];

    for (final row in rows) {
      final reading = _buildReading(row, thresholds);
      if (reading.category == 'glucose' && reading.glucoseValue != null) {
        glucosePts.add(
          GlucoseChartPoint(
            id: reading.id,
            recordedAt: reading.recordedAt,
            glucoseValue: reading.glucoseValue!,
            glucoseType: reading.glucoseType ?? 'Random',
            statusLevel: reading.evaluation.statusLevel,
          ),
        );
      } else if (reading.category == 'bp' &&
          reading.systolic != null &&
          reading.diastolic != null) {
        bpPts.add(
          BPChartPoint(
            id: reading.id,
            recordedAt: reading.recordedAt,
            systolic: reading.systolic!,
            diastolic: reading.diastolic!,
            heartRate: reading.heartRate,
            statusLevel: reading.evaluation.statusLevel,
          ),
        );
      }
    }

    return ChartsData(
      period: period,
      glucosePoints: glucosePts,
      glucoseTrend: computeTrend(
        values: glucosePts.map((p) => p.glucoseValue).toList(),
        unit: 'mg/dL',
        minChange: 5.0,
      ),
      bpPoints: bpPts,
      bpSystolicTrend: computeTrend(
        values: bpPts.map((p) => p.systolic.toDouble()).toList(),
        unit: 'mmHg systolic',
        minChange: 3.0,
      ),
      bpDiastolicTrend: computeTrend(
        values: bpPts.map((p) => p.diastolic.toDouble()).toList(),
        unit: 'mmHg diastolic',
        minChange: 3.0,
      ),
      thresholds: thresholds,
    );
  }

  Future<ThresholdsModel> updateThresholds(ThresholdsModel thresholds) async {
    final validationError = validateThresholds(thresholds);
    if (validationError != null) {
      throw StoreException(validationError);
    }
    if (_useSqflite) {
      final db = await _getDb();
      await db.update('thresholds', thresholds.toJson(), where: 'id = 1');
      return _readThresholds();
    }
    final state = await _loadPrefsState();
    state['thresholds'] = thresholds.toJson();
    await _savePrefsState(state);
    return thresholds;
  }

  Future<ThresholdsModel> resetThresholds() async {
    if (_useSqflite) {
      final db = await _getDb();
      await db.update('thresholds', defaultThresholds.toJson(), where: 'id = 1');
      return _readThresholds();
    }
    final state = await _loadPrefsState();
    state['thresholds'] = defaultThresholds.toJson();
    await _savePrefsState(state);
    return defaultThresholds;
  }

  Future<List<ReminderItem>> getReminders() async {
    late List<Map<String, dynamic>> rows;
    if (_useSqflite) {
      final db = await _getDb();
      rows = await db.query('reminders', orderBy: 'time_of_day ASC, key ASC');
    } else {
      final state = await _loadPrefsState();
      rows = (state['reminders'] as List<dynamic>)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      rows.sort((a, b) {
        final cmp = (a['time_of_day'] as String).compareTo(b['time_of_day'] as String);
        return cmp != 0 ? cmp : (a['key'] as String).compareTo(b['key'] as String);
      });
    }
    return rows
        .map(
          (r) => ReminderItem(
            key: r['key'] as String,
            title: r['title'] as String,
            timeOfDay: r['time_of_day'] as String,
            enabled: (r['enabled'] as num).toInt() == 1,
            note: r['note'] as String? ?? '',
          ),
        )
        .toList();
  }

  Future<ReminderItem> updateReminder({
    required String key,
    required String timeOfDay,
    required bool enabled,
    required String note,
  }) async {
    final cleanedNote = note.trim();
    if (_useSqflite) {
      final db = await _getDb();
      await db.update(
        'reminders',
        {
          'time_of_day': timeOfDay,
          'enabled': enabled ? 1 : 0,
          'note': cleanedNote,
        },
        where: 'key = ?',
        whereArgs: [key],
      );
      final rows = await db.query('reminders', where: 'key = ?', whereArgs: [key]);
      final row = rows.first;
      return ReminderItem(
        key: row['key'] as String,
        title: row['title'] as String,
        timeOfDay: row['time_of_day'] as String,
        enabled: (row['enabled'] as num).toInt() == 1,
        note: row['note'] as String? ?? '',
      );
    }

    final state = await _loadPrefsState();
    final list = state['reminders'] as List<dynamic>;
    final idx = list.indexWhere((r) => (r as Map)['key'] == key);
    if (idx < 0) {
      throw StoreException('Reminder not found.');
    }
    final rem = Map<String, dynamic>.from(list[idx] as Map);
    rem['time_of_day'] = timeOfDay;
    rem['enabled'] = enabled ? 1 : 0;
    rem['note'] = cleanedNote;
    list[idx] = rem;
    await _savePrefsState(state);
    return ReminderItem(
      key: rem['key'] as String,
      title: rem['title'] as String,
      timeOfDay: rem['time_of_day'] as String,
      enabled: enabled,
      note: cleanedNote,
    );
  }
}

