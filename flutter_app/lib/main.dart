import 'package:flutter/material.dart';

import 'models/health_models.dart';
import 'screens/account_sheet.dart';
import 'screens/charts_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/history_screen.dart';
import 'screens/login_screen.dart';
import 'screens/record_bp_sheet.dart';
import 'screens/record_glucose_sheet.dart';
import 'screens/reminders_screen.dart';
import 'screens/thresholds_sheet.dart';
import 'services/health_repository.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const MyHealthTrackerApp());
}

class MyHealthTrackerApp extends StatefulWidget {
  const MyHealthTrackerApp({
    super.key,
    this.repository,
  });

  final LocalHealthRepository? repository;

  @override
  State<MyHealthTrackerApp> createState() => _MyHealthTrackerAppState();
}

class _MyHealthTrackerAppState extends State<MyHealthTrackerApp> {
  late final LocalHealthRepository _repository;

  AuthSession? _session;
  bool _checkingAuth = true;
  String? _authError;

  int _selectedTab = 0;
  DashboardData? _dashboard;
  List<HealthReading> _readings = const [];
  ChartsData? _charts;
  List<ReminderItem> _reminders = const [];

  String _historyPeriod = 'weekly';
  String _historyCategory = 'all';
  String _chartsPeriod = 'weekly';

  bool _loadingDashboard = false;
  bool _loadingHistory = false;
  bool _loadingCharts = false;
  bool _loadingReminders = false;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? LocalHealthRepository();
    _checkSession();
  }

  Future<void> _checkSession() async {
    setState(() {
      _checkingAuth = true;
      _authError = null;
    });
    try {
      final nextSession = await _repository.getSession();
      if (!mounted) return;
      setState(() {
        _session = nextSession;
        _checkingAuth = false;
      });
      if (nextSession.authenticated) {
        await _loadAllData();
      }
    } catch (err) {
      if (!mounted) return;
      setState(() {
        _checkingAuth = false;
        _authError = err.toString();
      });
    }
  }

  Future<void> _loadDashboard() async {
    setState(() => _loadingDashboard = true);
    try {
      final data = await _repository.getDashboard();
      if (!mounted) return;
      setState(() => _dashboard = data);
    } finally {
      if (mounted) setState(() => _loadingDashboard = false);
    }
  }

  Future<void> _loadHistory() async {
    setState(() => _loadingHistory = true);
    try {
      final data = await _repository.getReadings(
        period: _historyPeriod,
        category: _historyCategory,
      );
      if (!mounted) return;
      setState(() => _readings = data);
    } finally {
      if (mounted) setState(() => _loadingHistory = false);
    }
  }

  Future<void> _loadCharts() async {
    setState(() => _loadingCharts = true);
    try {
      final data = await _repository.getCharts(period: _chartsPeriod);
      if (!mounted) return;
      setState(() => _charts = data);
    } finally {
      if (mounted) setState(() => _loadingCharts = false);
    }
  }

  Future<void> _loadReminders() async {
    setState(() => _loadingReminders = true);
    try {
      final data = await _repository.getReminders();
      if (!mounted) return;
      setState(() => _reminders = data);
    } finally {
      if (mounted) setState(() => _loadingReminders = false);
    }
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      _loadDashboard(),
      _loadHistory(),
      _loadCharts(),
      _loadReminders(),
    ]);
  }

  Future<void> _logout() async {
    await _repository.logout();
    setState(() {
      _dashboard = null;
      _readings = const [];
      _charts = null;
      _reminders = const [];
      _selectedTab = 0;
    });
    await _checkSession();
  }

  void _openGlucoseSheet(BuildContext sheetContext) {
    showModalBottomSheet<void>(
      context: sheetContext,
      isScrollControlled: true,
      backgroundColor: AppColors.pageBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => RecordGlucoseSheet(
        repository: _repository,
        thresholds: _dashboard?.thresholds,
        onSaved: _loadAllData,
      ),
    );
  }

  void _openBPSheet(BuildContext sheetContext) {
    showModalBottomSheet<void>(
      context: sheetContext,
      isScrollControlled: true,
      backgroundColor: AppColors.pageBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => RecordBPSheet(
        repository: _repository,
        thresholds: _dashboard?.thresholds,
        onSaved: _loadAllData,
      ),
    );
  }

  void _openThresholdsSheet(BuildContext sheetContext) {
    final thresholds = _dashboard?.thresholds;
    if (thresholds == null) return;
    showModalBottomSheet<void>(
      context: sheetContext,
      isScrollControlled: true,
      backgroundColor: AppColors.pageBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ThresholdsSheet(
        repository: _repository,
        thresholds: thresholds,
        onUpdated: _loadAllData,
      ),
    );
  }

  void _openAccountSheet(BuildContext sheetContext) {
    final session = _session;
    if (session == null) return;
    showModalBottomSheet<void>(
      context: sheetContext,
      isScrollControlled: true,
      backgroundColor: AppColors.pageBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AccountSheet(
        repository: _repository,
        session: session,
        onUpdated: (updated) {
          setState(() => _session = updated);
          _loadDashboard();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Health Tracker',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: _buildHome(),
    );
  }

  Widget _buildHome() {
    if (_checkingAuth && _session == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_session?.authenticated != true) {
      return LoginScreen(
        repository: _repository,
        sessionInfo: _session,
        initialError: _authError,
        onSignedIn: (nextSession) {
          setState(() {
            _session = nextSession;
            _authError = null;
          });
          _loadAllData();
        },
      );
    }

    final dueCount = _dashboard?.dueReminders.length ?? 0;

    return Builder(
      builder: (innerContext) => Scaffold(
        appBar: AppBar(
          title: const Row(
            children: [
              Icon(Icons.monitor_heart_rounded, color: AppColors.tealPrimary),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  'My Health Tracker',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Login Details',
              onPressed: () => _openAccountSheet(innerContext),
              icon: const Icon(Icons.person_outline_rounded),
            ),
            IconButton(
              tooltip: 'Sign Out',
              onPressed: _logout,
              icon: const Icon(Icons.logout_rounded),
            ),
          ],
        ),
        body: SafeArea(
          child: IndexedStack(
            index: _selectedTab,
            children: [
              DashboardScreen(
                dashboard: _dashboard,
                session: _session,
                loading: _loadingDashboard,
                onRefresh: _loadAllData,
                onAddGlucose: () => _openGlucoseSheet(innerContext),
                onAddBP: () => _openBPSheet(innerContext),
                onOpenThresholds: () => _openThresholdsSheet(innerContext),
                onOpenAccount: () => _openAccountSheet(innerContext),
                onGoToReminders: () => setState(() => _selectedTab = 3),
              ),
              HistoryScreen(
                repository: _repository,
                readings: _readings,
                period: _historyPeriod,
                category: _historyCategory,
                loading: _loadingHistory,
                onPeriodChange: (next) {
                  setState(() => _historyPeriod = next);
                  _loadHistory();
                },
                onCategoryChange: (next) {
                  setState(() => _historyCategory = next);
                  _loadHistory();
                },
                onRefresh: _loadAllData,
              ),
              ChartsScreen(
                charts: _charts,
                period: _chartsPeriod,
                loading: _loadingCharts,
                onPeriodChange: (next) {
                  setState(() => _chartsPeriod = next);
                  _loadCharts();
                },
                onRefresh: _loadCharts,
              ),
              RemindersScreen(
                repository: _repository,
                reminders: _reminders,
                loading: _loadingReminders,
                onRefresh: () async {
                  await Future.wait([_loadReminders(), _loadDashboard()]);
                },
              ),
            ],
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedTab,
          onDestinationSelected: (idx) => setState(() => _selectedTab = idx),
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            const NavigationDestination(
              icon: Icon(Icons.history_outlined),
              selectedIcon: Icon(Icons.history_rounded),
              label: 'History',
            ),
            const NavigationDestination(
              icon: Icon(Icons.show_chart_rounded),
              selectedIcon: Icon(Icons.show_chart_rounded),
              label: 'Charts',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: dueCount > 0,
                label: Text('$dueCount'),
                child: const Icon(Icons.notifications_outlined),
              ),
              selectedIcon: Badge(
                isLabelVisible: dueCount > 0,
                label: Text('$dueCount'),
                child: const Icon(Icons.notifications_rounded),
              ),
              label: 'Reminders',
            ),
          ],
        ),
      ),
    );
  }
}
