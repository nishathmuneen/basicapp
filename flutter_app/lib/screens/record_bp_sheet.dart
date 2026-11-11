import 'package:flutter/material.dart';

import '../models/health_models.dart';
import '../services/health_repository.dart';
import '../theme/app_theme.dart';
import '../utils/date_formatters.dart';
import '../widgets/status_badge.dart';

class RecordBPSheet extends StatefulWidget {
  const RecordBPSheet({
    super.key,
    required this.repository,
    required this.thresholds,
    required this.onSaved,
  });

  final LocalHealthRepository repository;
  final ThresholdsModel? thresholds;
  final VoidCallback onSaved;

  @override
  State<RecordBPSheet> createState() => _RecordBPSheetState();
}

class _RecordBPSheetState extends State<RecordBPSheet> {
  final _formKey = GlobalKey<FormState>();
  final _sysController = TextEditingController();
  final _diaController = TextEditingController();
  final _hrController = TextEditingController();

  DateTime _recordedAt = DateTime.now();
  bool _submitting = false;
  String? _errorMessage;
  HealthReading? _savedReading;

  @override
  void dispose() {
    _sysController.dispose();
    _diaController.dispose();
    _hrController.dispose();
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
      final hrText = _hrController.text.trim();
      final result = await widget.repository.createBPReading(
        systolic: int.parse(_sysController.text.trim()),
        diastolic: int.parse(_diaController.text.trim()),
        heartRate: hrText.isEmpty ? null : int.parse(hrText),
        recordedAt: _recordedAt,
      );
      if (!mounted) return;
      setState(() => _savedReading = result);
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
      _sysController.clear();
      _diaController.clear();
      _hrController.clear();
      _recordedAt = DateTime.now();
      _savedReading = null;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final sysMax = (widget.thresholds?.bpAttentionSystolic ?? 130) - 1;
    final diaMax = (widget.thresholds?.bpAttentionDiastolic ?? 80) - 1;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Record Blood Pressure',
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
            const SizedBox(height: 10),
            if (_savedReading != null) ...[
              HealthAlertBanner(
                colorName: _savedReading!.evaluation.color,
                badgeLabel: _savedReading!.evaluation.statusLabel,
                title:
                    '${_savedReading!.systolic} / ${_savedReading!.diastolic} mmHg'
                    '${_savedReading!.heartRate != null ? ' · ${_savedReading!.heartRate} bpm' : ''}',
                message: _savedReading!.evaluation.warningMessage ??
                    _savedReading!.evaluation.summary,
                subtitle: 'Target range: ${_savedReading!.evaluation.targetRangeText}',
              ),
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
                    Text(
                      'Normal target: up to $sysMax / $diaMax mmHg.',
                      style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Systolic (top)',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _sysController,
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  hintText: '120',
                                  suffixText: 'mmHg',
                                ),
                                validator: (value) {
                                  final parsed = int.tryParse(value?.trim() ?? '');
                                  if (parsed == null || parsed < 40 || parsed > 300) {
                                    return '40–300';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Diastolic (bottom)',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _diaController,
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  hintText: '78',
                                  suffixText: 'mmHg',
                                ),
                                validator: (value) {
                                  final dia = int.tryParse(value?.trim() ?? '');
                                  if (dia == null || dia < 20 || dia > 200) {
                                    return '20–200';
                                  }
                                  final sys = int.tryParse(_sysController.text.trim());
                                  if (sys != null && dia >= sys) {
                                    return 'Must be < top';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Heart rate (optional, bpm)',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _hrController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: 'e.g. 72 (leave blank if not measured)',
                        suffixText: 'bpm',
                      ),
                      validator: (value) {
                        final trimmed = value?.trim() ?? '';
                        if (trimmed.isEmpty) return null;
                        final parsed = int.tryParse(trimmed);
                        if (parsed == null || parsed < 25 || parsed > 250) {
                          return 'Enter a heart rate between 25 and 250 bpm.';
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
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.skyDark,
                      ),
                      onPressed: _submitting ? null : _save,
                      child: Text(_submitting ? 'Saving...' : 'Save BP Reading'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

