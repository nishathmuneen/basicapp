import 'package:flutter/material.dart';

import '../models/health_models.dart';
import '../services/health_repository.dart';
import '../services/lifestyle_advisor.dart';
import '../theme/app_theme.dart';
import '../utils/date_formatters.dart';
import '../widgets/app_chrome.dart';
import '../widgets/guidance_plan_card.dart';
import '../widgets/status_badge.dart';

const List<double> _sleepPresets = [5, 6, 7, 7.5, 8, 9];

class RecordLifestyleSheet extends StatefulWidget {
  const RecordLifestyleSheet({
    super.key,
    required this.repository,
    this.initialLifestyle,
    required this.onSaved,
  });

  final LocalHealthRepository repository;
  final LifestyleReading? initialLifestyle;
  final VoidCallback onSaved;

  @override
  State<RecordLifestyleSheet> createState() => _RecordLifestyleSheetState();
}

class _RecordLifestyleSheetState extends State<RecordLifestyleSheet> {
  final _formKey = GlobalKey<FormState>();
  final _sleepController = TextEditingController();
  final _weightController = TextEditingController();

  String _weightUnit = 'kg';
  DateTime _recordedAt = DateTime.now();
  bool _submitting = false;
  String? _errorMessage;
  LifestyleReading? _savedReading;
  DailyGuidancePlan? _updatedPlan;

  @override
  void initState() {
    super.initState();
    final initialSleep = widget.initialLifestyle?.sleepHours;
    final initialWeightKg = widget.initialLifestyle?.weightKg;
    if (initialSleep != null) {
      _sleepController.text = formatHoursValue(initialSleep);
    }
    if (initialWeightKg != null) {
      _weightController.text = formatWeightKg(initialWeightKg);
    }
  }

  @override
  void dispose() {
    _sleepController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _switchWeightUnit(String nextUnit) {
    if (_weightUnit == nextUnit) return;
    final currentVal = double.tryParse(_weightController.text.trim());
    setState(() {
      if (currentVal != null) {
        final converted = nextUnit == 'lbs'
            ? currentVal * 2.20462262
            : currentVal / 2.20462262;
        _weightController.text = converted.toStringAsFixed(1);
      }
      _weightUnit = nextUnit;
    });
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

    final sleepText = _sleepController.text.trim();
    final weightText = _weightController.text.trim();
    final sleepHours = sleepText.isEmpty ? null : double.tryParse(sleepText);
    final rawWeight = weightText.isEmpty ? null : double.tryParse(weightText);
    final weightKg = rawWeight == null
        ? null
        : (_weightUnit == 'lbs' ? rawWeight / 2.20462262 : rawWeight);

    if (sleepHours == null && weightKg == null) {
      setState(() {
        _errorMessage = 'Enter sleep hours or body weight before saving.';
      });
      return;
    }

    setState(() => _submitting = true);
    try {
      final result = await widget.repository.createLifestyleReading(
        sleepHours: sleepHours,
        weightKg: weightKg,
        recordedAt: _recordedAt,
      );
      final plan = await widget.repository.buildLatestGuidancePlan();
      if (!mounted) return;
      setState(() {
        _savedReading = result;
        _updatedPlan = plan;
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
      _recordedAt = DateTime.now();
      _savedReading = null;
      _updatedPlan = null;
      _errorMessage = null;
    });
  }

  String _savedTitle(LifestyleReading reading) {
    final parts = <String>[];
    if (reading.sleepHours != null) {
      parts.add('${formatHoursValue(reading.sleepHours!)} hrs sleep');
    }
    if (reading.weightKg != null) {
      parts.add(
        '${formatWeightKg(reading.weightKg!)} kg (${reading.weightLbs!.toStringAsFixed(1)} lbs)',
      );
    }
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return AppSheetContainer(
      title: 'Sleep & Weight',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_savedReading != null) ...[
            HealthAlertBanner(
              colorName: 'green',
              badgeLabel: 'Saved',
              title: _savedTitle(_savedReading!),
              message:
                  'Your sleep and weight context has been saved to this device.',
              subtitle:
                  'Recorded ${formatDateTimeDisplay(_savedReading!.recordedAt)}',
            ),
            if (_updatedPlan != null) ...[
              const SizedBox(height: 14),
              GuidancePlanCard(
                plan: _updatedPlan!,
                title: 'Updated Diet & Exercise Plan',
                compact: true,
              ),
            ],
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _resetForAnother,
                    child: const Text('Update Again'),
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
                    'Sleep hours (optional)',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Used to adjust your recommended exercise intensity and recovery tips.',
                    style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _sleepController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      hintText: 'e.g. 7.5',
                      suffixText: 'hrs',
                    ),
                    validator: (value) {
                      final trimmed = value?.trim() ?? '';
                      if (trimmed.isEmpty) return null;
                      final parsed = double.tryParse(trimmed);
                      if (parsed == null || parsed < 0 || parsed > 24) {
                        return 'Enter sleep hours between 0 and 24.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _sleepPresets.map((preset) {
                      final presetStr = formatHoursValue(preset);
                      final selected = _sleepController.text.trim() == presetStr;
                      return ChoiceChip(
                        label: Text('${presetStr}h'),
                        selected: selected,
                        selectedColor: AppColors.turquoiseLight,
                        labelStyle: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: selected
                              ? AppColors.tealDark
                              : AppColors.textPrimary,
                        ),
                        onSelected: (_) {
                          setState(() => _sleepController.text = presetStr);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    alignment: WrapAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Body weight (optional)',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      Wrap(
                        spacing: 6,
                        children: ['kg', 'lbs'].map((unit) {
                          final selected = _weightUnit == unit;
                          return ChoiceChip(
                            label: Text(unit),
                            selected: selected,
                            selectedColor: AppColors.turquoiseLight,
                            visualDensity: VisualDensity.compact,
                            labelStyle: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: selected
                                  ? AppColors.tealDark
                                  : AppColors.textPrimary,
                            ),
                            onSelected: (_) => _switchWeightUnit(unit),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _weightController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      hintText: _weightUnit == 'kg' ? 'e.g. 70.5' : 'e.g. 155.4',
                      suffixText: _weightUnit,
                    ),
                    validator: (value) {
                      final trimmed = value?.trim() ?? '';
                      if (trimmed.isEmpty) return null;
                      final parsed = double.tryParse(trimmed);
                      if (parsed == null) {
                        return 'Enter a valid number.';
                      }
                      final kg = _weightUnit == 'lbs'
                          ? parsed / 2.20462262
                          : parsed;
                      if (kg < 20 || kg > 400) {
                        return _weightUnit == 'kg'
                            ? 'Enter weight between 20 and 400 kg.'
                            : 'Enter weight between 44 and 880 lbs.';
                      }
                      return null;
                    },
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
                        icon:
                            const Icon(Icons.calendar_today_outlined, size: 18),
                        label: Text(
                          formatDateDisplay(toApiDateTimeString(_recordedAt)),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: _pickTime,
                        icon: const Icon(Icons.access_time_rounded, size: 18),
                        label: Text(
                          formatTimeDisplay(toApiDateTimeString(_recordedAt)),
                        ),
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
                    child:
                        Text(_submitting ? 'Saving...' : 'Save Sleep & Weight'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
