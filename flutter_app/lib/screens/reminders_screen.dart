import 'package:flutter/material.dart';

import '../models/health_models.dart';
import '../services/health_repository.dart';
import '../theme/app_theme.dart';
import '../utils/date_formatters.dart';

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({
    super.key,
    required this.repository,
    required this.reminders,
    required this.loading,
    required this.onRefresh,
  });

  final LocalHealthRepository repository;
  final List<ReminderItem> reminders;
  final bool loading;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Reminders',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
            'Set daily times for your morning glucose check, evening glucose check, and blood pressure measurement.',
            style: TextStyle(fontSize: 14, color: AppColors.textMuted),
          ),
          const SizedBox(height: 14),
          if (loading && reminders.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 36),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            ...reminders.map(
              (reminder) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ReminderCard(
                  repository: repository,
                  reminder: reminder,
                  onSaved: onRefresh,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ReminderCard extends StatefulWidget {
  const _ReminderCard({
    required this.repository,
    required this.reminder,
    required this.onSaved,
  });

  final LocalHealthRepository repository;
  final ReminderItem reminder;
  final Future<void> Function() onSaved;

  @override
  State<_ReminderCard> createState() => _ReminderCardState();
}

class _ReminderCardState extends State<_ReminderCard> {
  late bool _enabled;
  late String _timeOfDay;
  late TextEditingController _noteController;
  bool _saving = false;
  String? _feedback;
  String? _error;

  @override
  void initState() {
    super.initState();
    _enabled = widget.reminder.enabled;
    _timeOfDay = widget.reminder.timeOfDay;
    _noteController = TextEditingController(text: widget.reminder.note);
  }

  @override
  void didUpdateWidget(covariant _ReminderCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reminder.key != widget.reminder.key ||
        oldWidget.reminder.timeOfDay != widget.reminder.timeOfDay ||
        oldWidget.reminder.enabled != widget.reminder.enabled ||
        oldWidget.reminder.note != widget.reminder.note) {
      _enabled = widget.reminder.enabled;
      _timeOfDay = widget.reminder.timeOfDay;
      _noteController.text = widget.reminder.note;
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final parts = _timeOfDay.split(':');
    final initialHour = int.tryParse(parts.first) ?? 8;
    final initialMin = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initialHour, minute: initialMin),
    );
    if (picked == null) return;
    setState(() {
      _timeOfDay =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    });
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _feedback = null;
      _error = null;
    });
    try {
      final updated = await widget.repository.updateReminder(
        key: widget.reminder.key,
        timeOfDay: _timeOfDay,
        enabled: _enabled,
        note: _noteController.text,
      );
      if (!mounted) return;
      setState(() {
        _feedback =
            'Saved (${updated.enabled ? formatWallTime(updated.timeOfDay) : 'Paused'}).';
      });
      await widget.onSaved();
    } catch (err) {
      if (!mounted) return;
      setState(() => _error = err.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.notifications_none_rounded, color: AppColors.tealAccent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.reminder.title,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                ),
                Switch.adaptive(
                  value: _enabled,
                  onChanged: (val) => setState(() => _enabled = val),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.access_time_rounded, size: 18),
                    label: Text('Time: ${formatWallTime(_timeOfDay)}'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _noteController,
              maxLength: 200,
              decoration: const InputDecoration(
                labelText: 'Short note (optional)',
                hintText: 'e.g. Check before breakfast',
                counterText: '',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: AppColors.redText)),
            ],
            if (_feedback != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.check_circle_outline_rounded,
                      size: 18, color: AppColors.greenText),
                  const SizedBox(width: 6),
                  Text(
                    _feedback!,
                    style: const TextStyle(
                      color: AppColors.greenText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving...' : 'Save Reminder'),
            ),
          ],
        ),
      ),
    );
  }
}

