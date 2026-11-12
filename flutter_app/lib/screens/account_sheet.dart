import 'package:flutter/material.dart';

import '../models/health_models.dart';
import '../services/health_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/app_chrome.dart';
import '../widgets/status_badge.dart';

class AccountSheet extends StatefulWidget {
  const AccountSheet({
    super.key,
    required this.repository,
    required this.session,
    required this.onUpdated,
  });

  final LocalHealthRepository repository;
  final AuthSession session;
  final void Function(AuthSession updated) onUpdated;

  @override
  State<AccountSheet> createState() => _AccountSheetState();
}

class _AccountSheetState extends State<AccountSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _usernameController;
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();

  bool _showCurrent = false;
  bool _showNew = false;
  bool _saving = false;
  String? _error;
  String? _success;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.session.displayName ?? 'Patient');
    _usernameController = TextEditingController(text: widget.session.username ?? 'patient');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
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
      final updated = await widget.repository.updateCredentials(
        currentPassword: _currentPasswordController.text,
        username: _usernameController.text.trim(),
        displayName: _nameController.text.trim(),
        newPassword: _newPasswordController.text,
      );
      if (!mounted) return;
      _currentPasswordController.clear();
      _newPasswordController.clear();
      setState(() => _success = 'Your login details have been updated.');
      widget.onUpdated(updated);
    } catch (err) {
      if (!mounted) return;
      setState(() => _error = err.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppSheetContainer(
      title: 'Login Details',
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Update your display name, username, or password. Enter your current password to confirm changes.',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Your name (shown on Home)'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Enter your name.' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _usernameController,
                autocorrect: false,
                decoration: const InputDecoration(labelText: 'Username'),
                validator: (v) =>
                    v == null || v.trim().length < 2 ? 'At least 2 characters.' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _currentPasswordController,
                obscureText: !_showCurrent,
                decoration: InputDecoration(
                  labelText: 'Current password',
                  suffixIcon: IconButton(
                    tooltip: _showCurrent ? 'Hide' : 'Show',
                    icon: Icon(_showCurrent ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _showCurrent = !_showCurrent),
                  ),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter current password to save.' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _newPasswordController,
                obscureText: !_showNew,
                decoration: InputDecoration(
                  labelText: 'New password (optional)',
                  helperText: 'Leave blank to keep your current password.',
                  suffixIcon: IconButton(
                    tooltip: _showNew ? 'Hide' : 'Show',
                    icon: Icon(_showNew ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _showNew = !_showNew),
                  ),
                ),
                validator: (v) {
                  if (v != null && v.isNotEmpty && v.length < 6) {
                    return 'New password must be at least 6 characters.';
                  }
                  return null;
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                HealthAlertBanner(
                  colorName: 'red',
                  title: 'Could Not Update',
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
              FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Saving...' : 'Save Login Details'),
              ),
            ],
          ),
        ),
      );
  }
}

