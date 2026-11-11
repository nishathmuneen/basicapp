import 'package:flutter/material.dart';

import '../models/health_models.dart';
import '../services/health_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/status_badge.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.repository,
    required this.sessionInfo,
    required this.onSignedIn,
    this.initialError,
  });

  final LocalHealthRepository repository;
  final AuthSession? sessionInfo;
  final void Function(AuthSession session) onSignedIn;
  final String? initialError;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _showPassword = false;
  bool _submitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _errorMessage = widget.initialError;
  }

  @override
  void didUpdateWidget(covariant LoginScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialError != oldWidget.initialError && widget.initialError != null) {
      _errorMessage = widget.initialError;
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _errorMessage = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _submitting = true);
    try {
      final nextSession = await widget.repository.login(
        username: _usernameController.text,
        password: _passwordController.text,
      );
      widget.onSignedIn(nextSession);
    } catch (err) {
      if (!mounted) return;
      setState(() => _errorMessage = err.toString());
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  void _fillDefaultCredentials() {
    final user = widget.sessionInfo?.defaultUsername ?? LocalHealthRepository.defaultUsername;
    final pass = widget.sessionInfo?.defaultPassword ?? LocalHealthRepository.defaultPassword;
    setState(() {
      _usernameController.text = user;
      _passwordController.text = pass;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final sessionInfo = widget.sessionInfo;
    final showDefaultHint = sessionInfo?.showDefaultHint ?? true;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: const LinearGradient(
                                  colors: [AppColors.tealAccent, AppColors.skyPrimary],
                                ),
                              ),
                              child: const Icon(
                                Icons.monitor_heart_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'My Health Tracker',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    'Sign in to keep your readings private on this device',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        const Text(
                          'Username',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _usernameController,
                          textInputAction: TextInputAction.next,
                          autocorrect: false,
                          enableSuggestions: false,
                          autofillHints: const [AutofillHints.username],
                          decoration: const InputDecoration(
                            hintText: 'Enter your username',
                            prefixIcon: Icon(Icons.person_outline_rounded),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your username.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Password',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_showPassword,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          onFieldSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            hintText: 'Enter your password',
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              tooltip: _showPassword ? 'Hide password' : 'Show password',
                              icon: Icon(
                                _showPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                              onPressed: () {
                                setState(() => _showPassword = !_showPassword);
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password.';
                            }
                            return null;
                          },
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 14),
                          HealthAlertBanner(
                            colorName: 'red',
                            title: 'Sign In Notice',
                            message: _errorMessage!,
                          ),
                        ],
                        const SizedBox(height: 18),
                        FilledButton.icon(
                          onPressed: _submitting ? null : _submit,
                          icon: const Icon(Icons.lock_open_rounded),
                          label: Text(_submitting ? 'Signing In...' : 'Sign In'),
                        ),
                        const SizedBox(height: 18),
                        if (showDefaultHint)
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.subtleBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.skyBorder),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Default Login Details',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.skyDark,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Username: ${sessionInfo?.defaultUsername ?? LocalHealthRepository.defaultUsername}  ·  '
                                  'Password: ${sessionInfo?.defaultPassword ?? LocalHealthRepository.defaultPassword}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'You can change these login details anytime after signing in.',
                                  style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                                ),
                                const SizedBox(height: 10),
                                OutlinedButton(
                                  onPressed: _fillDefaultCredentials,
                                  child: const Text('Use Default Details'),
                                ),
                              ],
                            ),
                          )
                        else
                          const Text(
                            'Your custom login details are active.',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
