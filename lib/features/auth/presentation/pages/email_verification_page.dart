library;

import 'dart:async';
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:prayers_tracker_plus/features/auth/presentation/providers/auth_provider.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/widgets/app_snackbar.dart';

class EmailVerificationPage extends StatefulWidget {
  const EmailVerificationPage({super.key});

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  Timer? _checkTimer;
  bool _isSending = false;
  bool _isChecking = false;
  bool _emailVerified = false;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    // Send verification email immediately on page load.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sendVerificationEmail();
      _startPeriodicCheck();
    });
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  /// Sends the verification email.
  Future<void> _sendVerificationEmail() async {
    if (_isSending || _resendCooldown > 0) return;

    setState(() => _isSending = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();

        if (!mounted) return;

        AppSnackbar.showSuccess(
          context,
          'Verification email sent to ${user.email}',
        );

        // Start cooldown to prevent spamming.
        _startCooldown();
      }
    } catch (e) {
      AppLogger.error(
        'Failed to send verification email',
        error: e,
        tag: 'EmailVerification',
      );
      if (!mounted) return;
      AppSnackbar.showError(
        context,
        'Could not send verification email. Please try again.',
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  /// Periodically checks if the email has been verified.
  void _startPeriodicCheck() {
    _checkTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _checkVerification(),
    );
  }

  Future<void> _checkVerification() async {
    if (_isChecking) return;
    _isChecking = true;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Reload to get fresh emailVerified status.
      await user.reload();
      final refreshedUser = FirebaseAuth.instance.currentUser;

      if (refreshedUser != null && refreshedUser.emailVerified) {
        _checkTimer?.cancel();

        if (!mounted) return;

        setState(() => _emailVerified = true);

        // Wait a moment so user sees the success state.
        await Future<void>.delayed(const Duration(seconds: 1));

        if (!mounted) return;

        // Navigate to home.
        Navigator.of(context).pushReplacementNamed(AppRoutes.home);
      }
    } catch (e) {
      AppLogger.warning(
        'Email verification check failed',
        error: e,
        tag: 'EmailVerification',
      );
    } finally {
      _isChecking = false;
    }
  }

  void _startCooldown() {
    _resendCooldown = 60; // 60 seconds cooldown.
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!mounted) return;
        setState(() {
          _resendCooldown--;
          if (_resendCooldown <= 0) {
            _cooldownTimer?.cancel();
          }
        });
      },
    );
  }

  Future<void> _skipVerification() async {
    _checkTimer?.cancel();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final auth = context.watch<AuthProvider>();
    final email = auth.user?.email ?? '';

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Verify Your Email'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: _skipVerification,
            child: const Text('Skip'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            children: [
              const Spacer(),

              // ── Icon ─────────────────────────────────────────────────
              AnimatedSwitcher(
                duration: AppDurations.normal,
                child: _emailVerified
                    ? Container(
                        key: const ValueKey('verified'),
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.verified_rounded,
                          size: 48,
                          color: Colors.green,
                        ),
                      )
                    : Container(
                        key: const ValueKey('unverified'),
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.mark_email_unread_rounded,
                          size: 48,
                          color: colorScheme.primary,
                        ),
                      ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── Title ────────────────────────────────────────────────
              Text(
                _emailVerified ? 'Email Verified!' : 'Verify Your Email',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color:
                          _emailVerified ? Colors.green : colorScheme.onSurface,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),

              if (!_emailVerified) ...[
                // ── Description ──────────────────────────────────────────
                Text(
                  'We sent a verification link to:',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // ── Email ────────────────────────────────────────────────
                Text(
                  email,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.primary,
                      ),
                ),
                const SizedBox(height: AppSpacing.lg),

                Text(
                  'Open the link in the email to verify your account.\n'
                  'Check your spam folder if you don\'t see it.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // ── Waiting indicator ────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Waiting for verification…',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),

                // ── Resend button ────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _resendCooldown > 0 || _isSending
                        ? null
                        : _sendVerificationEmail,
                    icon: _isSending
                        ? const AppLoadingIndicator(size: 16)
                        : const Icon(Icons.refresh_rounded),
                    label: Text(
                      _resendCooldown > 0
                          ? 'Resend in ${_resendCooldown}s'
                          : 'Resend Verification Email',
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // ── Change email hint ────────────────────────────────────
                Center(
                  child: TextButton(
                    onPressed: () async {
                      _checkTimer?.cancel();
                      await context.read<AuthProvider>().signOut();
                      if (!context.mounted) return;
                      Navigator.of(context)
                          .pushReplacementNamed(AppRoutes.register);
                    },
                    child: const Text('Wrong email? Create new account'),
                  ),
                ),
              ] else ...[
                // ── Verified message ─────────────────────────────────────
                Text(
                  'Your email has been verified successfully.\n'
                  'Redirecting to home…',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.green,
                        height: 1.5,
                      ),
                ),
              ],

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
