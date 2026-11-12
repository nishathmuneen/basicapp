import 'package:flutter/material.dart';

import '../models/health_models.dart';
import '../services/health_repository.dart';
import '../theme/app_theme.dart';
import '../utils/date_formatters.dart';
import '../widgets/app_chrome.dart';
import '../widgets/guidance_plan_card.dart';
import '../widgets/status_badge.dart';

const List<String> _glucoseTypes = [
  'Fasting',
  'Before Meal',
  'After Meal',
  'Random',
];

class RecordGlucoseSheet extends StatefulWidget {
  const RecordGlucoseSheet({
    super.key,
    required this.repository,
    required this.thresholds,
    required this.onSaved,
  });

  final LocalHealthRepository repository;
  final ThresholdsModel? thresholds;
  final VoidCallback onSaved;

  @override
  State<RecordGlucoseSheet> createState() => _RecordGlucoseSheetState();
}

class _RecordGlucoseSheetState extends State<RecordGlucoseSheet> {
  final _formKey = GlobalKey<FormState>();
  final _levelController = TextEditingController();

  String _selectedType = 'Fasting';
  DateTime _recordedAt = DateTime.now();
  bool _submitting = false;
  String? _errorMessage;
  HealthReading? _savedReading;
  DailyGuidancePlan? _guidancePlan;

  @override
  void dispose() {
    _levelController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _recordedAt,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked == null) return;
    setState(() {
      _recordedAt = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _recordedAt.hour,
        _recordedAt.minute,
      );
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_recordedAt),
    );
    if (picked == null) return;
    setState(() {
      _recordedAt = DateTime(
        _recordedAt.year,
        _recordedAt.month,
        _recordedAt.day,
        picked.hour,
        picked.minute,
      );
    });
  }

  Future<void> _save() async {
    setState(() => _errorMessage = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _submitting = true);
    try {
      final result = await widget.repository.createGlucoseReading(
        glucoseValue: double.parse(_levelController.text.trim()),
        glucoseType: _selectedType,
        recordedAt: _recordedAt,
      );
      final plan = await widget.repository.buildLatestGuidancePlan(
        latestGlucoseOverride: result,
      );
      if (!mounted) return;
      setState(() {
        _savedReading = result;
        _guidancePlan = plan;
      });
      widget.onSaved();
    } catch (err) {
      if (!mounted) return;
      setState(() => _errorMessage = err.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _resetForAnother() {
    setState(() {
      _levelController.clear();
      _recordedAt = DateTime.now();
      _savedReading = null;
      _guidancePlan = null;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lowTarget = widget.thresholds?.glucoseLowUrgent ?? 70;
    final highTarget = widget.thresholds?.targetMaxForType(_selectedType) ?? 130;

    return AppSheetContainer(
      title: 'Record Blood Glucose',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_savedReading != null) ...[
              HealthAlertBanner(
                colorName: _savedReading!.evaluation.color,
                badgeLabel: _savedReading!.evaluation.statusLabel,
                title:
                    '${formatGlucoseValue(_savedReading!.glucoseValue)} mg/dL (${_savedReading!.glucoseType})',
                message: _savedReading!.evaluation.warningMessage ??
                    _savedReading!.evaluation.summary,
                subtitle: 'Target range: ${_savedReading!.evaluation.targetRangeText}',
              ),
              if (_guidancePlan != null) ...[
                const SizedBox(height: 14),
                GuidancePlanCard(
                  plan: _guidancePlan!,
                  compact: true,
                ),
              ],
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _resetForAnother,
                      child: const Text('Add Another'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Done'),
                    ),
                  ),
                ],
              ),
            ] else
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Glucose level (mg/dL)',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your $_selectedType target: ${formatGlucoseValue(lowTarget)}–${formatGlucoseValue(highTarget)} mg/dL.',
                      style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _levelController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        hintText: 'e.g. 112',
                        suffixText: 'mg/dL',
                      ),
                      validator: (value) {
                        final parsed = double.tryParse(value?.trim() ?? '');
                        if (parsed == null || parsed < 20 || parsed > 800) {
                          return 'Enter a glucose reading between 20 and 800 mg/dL.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Reading type',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _glucoseTypes.map((typeOption) {
                        final selected = _selectedType == typeOption;
                        return ChoiceChip(
                          label: Text(typeOption),
                          selected: selected,
                          selectedColor: AppColors.turquoiseLight,
                          labelStyle: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: selected ? AppColors.tealDark : AppColors.textPrimary,
                          ),
                          onSelected: (_) {
                            setState(() => _selectedType = typeOption);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Date and time',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _pickDate,
                          icon: const Icon(Icons.calendar_today_outlined, size: 18),
                          label: Text(formatDateDisplay(toApiDateTimeString(_recordedAt))),
                        ),
                        OutlinedButton.icon(
                          onPressed: _pickTime,
                          icon: const Icon(Icons.access_time_rounded, size: 18),
                          label: Text(formatTimeDisplay(toApiDateTimeString(_recordedAt))),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() => _recordedAt = DateTime.now());
                          },
                          child: const Text('Now'),
                        ),
                      ],
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      HealthAlertBanner(
                        colorName: 'red',
                        title: 'Could Not Save',
                        message: _errorMessage!,
                      ),
                    ],
                    const SizedBox(height: 18),
                    FilledButton(
                      onPressed: _submitting ? null : _save,
                      child: Text(_submitting ? 'Saving...' : 'Save Glucose Reading'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
  }
}

