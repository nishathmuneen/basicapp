import 'package:flutter/material.dart';

import '../models/health_models.dart';
import '../services/health_repository.dart';
import '../theme/app_theme.dart';
import '../utils/date_formatters.dart';
import '../widgets/status_badge.dart';

class ThresholdsSheet extends StatefulWidget {
  const ThresholdsSheet({
    super.key,
    required this.repository,
    required this.thresholds,
    required this.onUpdated,
  });

  final LocalHealthRepository repository;
  final ThresholdsModel thresholds;
  final VoidCallback onUpdated;

  @override
  State<ThresholdsSheet> createState() => _ThresholdsSheetState();
}

class _ThresholdsSheetState extends State<ThresholdsSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _gLow;
  late final TextEditingController _gFasting;
  late final TextEditingController _gBefore;
  late final TextEditingController _gAfter;
  late final TextEditingController _gRandom;
  late final TextEditingController _gUrgent;
  late final TextEditingController _bpAttnSys;
  late final TextEditingController _bpAttnDia;
  late final TextEditingController _bpUrgSys;
  late final TextEditingController _bpUrgDia;
  late final TextEditingController _hrLow;
  late final TextEditingController _hrHigh;

  bool _saving = false;
  String? _error;
  String? _success;

  @override
  void initState() {
    super.initState();
    _gLow = TextEditingController();
    _gFasting = TextEditingController();
    _gBefore = TextEditingController();
    _gAfter = TextEditingController();
    _gRandom = TextEditingController();
    _gUrgent = TextEditingController();
    _bpAttnSys = TextEditingController();
    _bpAttnDia = TextEditingController();
    _bpUrgSys = TextEditingController();
    _bpUrgDia = TextEditingController();
    _hrLow = TextEditingController();
    _hrHigh = TextEditingController();
    _syncControllers(widget.thresholds);
  }

  void _syncControllers(ThresholdsModel t) {
    _gLow.text = formatGlucoseValue(t.glucoseLowUrgent);
    _gFasting.text = formatGlucoseValue(t.glucoseFastingMax);
    _gBefore.text = formatGlucoseValue(t.glucoseBeforeMealMax);
    _gAfter.text = formatGlucoseValue(t.glucoseAfterMealMax);
    _gRandom.text = formatGlucoseValue(t.glucoseRandomMax);
    _gUrgent.text = formatGlucoseValue(t.glucoseHighUrgent);
    _bpAttnSys.text = t.bpAttentionSystolic.toString();
    _bpAttnDia.text = t.bpAttentionDiastolic.toString();
    _bpUrgSys.text = t.bpUrgentSystolic.toString();
    _bpUrgDia.text = t.bpUrgentDiastolic.toString();
    _hrLow.text = t.hrLow.toString();
    _hrHigh.text = t.hrHigh.toString();
  }

  @override
  void dispose() {
    _gLow.dispose();
    _gFasting.dispose();
    _gBefore.dispose();
    _gAfter.dispose();
    _gRandom.dispose();
    _gUrgent.dispose();
    _bpAttnSys.dispose();
    _bpAttnDia.dispose();
    _bpUrgSys.dispose();
    _bpUrgDia.dispose();
    _hrLow.dispose();
    _hrHigh.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _error = null;
      _success = null;
    });
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);
    try {
      final updated = ThresholdsModel(
        glucoseLowUrgent: double.parse(_gLow.text.trim()),
        glucoseFastingMax: double.parse(_gFasting.text.trim()),
        glucoseBeforeMealMax: double.parse(_gBefore.text.trim()),
        glucoseAfterMealMax: double.parse(_gAfter.text.trim()),
        glucoseRandomMax: double.parse(_gRandom.text.trim()),
        glucoseHighUrgent: double.parse(_gUrgent.text.trim()),
        bpLowSystolic: widget.thresholds.bpLowSystolic,
        bpLowDiastolic: widget.thresholds.bpLowDiastolic,
        bpAttentionSystolic: int.parse(_bpAttnSys.text.trim()),
        bpAttentionDiastolic: int.parse(_bpAttnDia.text.trim()),
        bpUrgentSystolic: int.parse(_bpUrgSys.text.trim()),
        bpUrgentDiastolic: int.parse(_bpUrgDia.text.trim()),
        hrLow: int.parse(_hrLow.text.trim()),
        hrHigh: int.parse(_hrHigh.text.trim()),
        hrUrgentLow: widget.thresholds.hrUrgentLow,
        hrUrgentHigh: widget.thresholds.hrUrgentHigh,
      );
      final saved = await widget.repository.updateThresholds(updated);
      if (!mounted) return;
      _syncControllers(saved);
      setState(() => _success = 'Target ranges saved.');
      widget.onUpdated();
    } catch (err) {
      if (!mounted) return;
      setState(() => _error = err.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _resetDefaults() async {
    setState(() {
      _saving = true;
      _error = null;
      _success = null;
    });
    try {
      final reset = await widget.repository.resetThresholds();
      if (!mounted) return;
      _syncControllers(reset);
      setState(() => _success = 'Reset to recommended default ranges.');
      widget.onUpdated();
    } catch (err) {
      if (!mounted) return;
      setState(() => _error = err.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Target Ranges & Alerts',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const Divider(),
              const Text(
                'These defaults follow general clinical guidance. Adjust only if your doctor or nurse gave you personal target ranges.',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
              const SizedBox(height: 14),
              const Text(
                'Blood Glucose (mg/dL)',
                style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.skyDark),
              ),
              const SizedBox(height: 8),
              _NumPair(
                leftLabel: 'Low alert (below)',
                leftController: _gLow,
                rightLabel: 'Urgent high (>=)',
                rightController: _gUrgent,
              ),
              const SizedBox(height: 10),
              _NumPair(
                leftLabel: 'Fasting max',
                leftController: _gFasting,
                rightLabel: 'Before meal max',
                rightController: _gBefore,
              ),
              const SizedBox(height: 10),
              _NumPair(
                leftLabel: 'After meal max',
                leftController: _gAfter,
                rightLabel: 'Random max',
                rightController: _gRandom,
              ),
              const SizedBox(height: 16),
              const Text(
                'Blood Pressure (mmHg) & Heart Rate (bpm)',
                style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.skyDark),
              ),
              const SizedBox(height: 8),
              _NumPair(
                leftLabel: 'Elevated systolic',
                leftController: _bpAttnSys,
                rightLabel: 'Elevated diastolic',
                rightController: _bpAttnDia,
              ),
              const SizedBox(height: 10),
              _NumPair(
                leftLabel: 'Urgent systolic',
                leftController: _bpUrgSys,
                rightLabel: 'Urgent diastolic',
                rightController: _bpUrgDia,
              ),
              const SizedBox(height: 10),
              _NumPair(
                leftLabel: 'HR lower target',
                leftController: _hrLow,
                rightLabel: 'HR upper target',
                rightController: _hrHigh,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                HealthAlertBanner(
                  colorName: 'red',
                  title: 'Check Values',
                  message: _error!,
                ),
              ],
              if (_success != null) ...[
                const SizedBox(height: 12),
                HealthAlertBanner(
                  colorName: 'green',
                  title: 'Saved',
                  message: _success!,
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving ? null : _resetDefaults,
                      child: const Text('Reset Defaults'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      child: Text(_saving ? 'Saving...' : 'Save Ranges'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NumPair extends StatelessWidget {
  const _NumPair({
    required this.leftLabel,
    required this.leftController,
    required this.rightLabel,
    required this.rightController,
  });

  final String leftLabel;
  final TextEditingController leftController;
  final String rightLabel;
  final TextEditingController rightController;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: leftController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: leftLabel),
            validator: (val) => double.tryParse(val?.trim() ?? '') == null ? 'Required' : null,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextFormField(
            controller: rightController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: rightLabel),
            validator: (val) => double.tryParse(val?.trim() ?? '') == null ? 'Required' : null,
          ),
        ),
      ],
    );
  }
}

