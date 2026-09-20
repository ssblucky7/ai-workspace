import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/routing/route_names.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';

/// Password-reset request screen. Always shows a success notice after
/// submitting (Firebase does not reveal whether the address exists).
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final ok = await context.read<AppAuthProvider>().resetPassword(
      email: _emailController.text,
    );
    if (!mounted) return;
    if (ok) {
      setState(() => _sent = true);
    } else {
      final error = context.read<AppAuthProvider>().error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Could not send the reset email.')),
      );
    }
  }

  /// Returns to the previous auth page when one exists on the stack;
  /// otherwise replaces the stack with Sign In.
  void _goBackToSignIn(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RouteNames.signInPath);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => _goBackToSignIn(context)),
        title: const Text('Reset password'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: _sent
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.mark_email_read_outlined,
                          size: 56,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Check your inbox',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'If an account exists for '
                          '${_emailController.text.trim()}, a password-reset '
                          'link has been sent. Check your spam folder if it '
                          'does not arrive within a few minutes.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: () => _goBackToSignIn(context),
                          child: const Text('Back to sign in'),
                        ),
                      ],
                    )
                  : Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Forgot your password?',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Enter your account email and we will send a '
                            'password-reset link.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email address',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.email],
                            onFieldSubmitted: (_) => _submit(),
                            validator: Validators.validateEmail,
                          ),
                          const SizedBox(height: 24),
                          FilledButton(
                            onPressed: auth.busy ? null : _submit,
                            child: auth.busy
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Send reset link'),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
