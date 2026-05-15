import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kickr/core/router/app_router.dart';
import 'package:kickr/core/theme/app_colors.dart';
import 'package:kickr/core/theme/app_text_styles.dart';
import 'package:kickr/features/auth/presentation/providers/auth_providers.dart';
import 'package:kickr/shared/widgets/app_button.dart';
import 'package:kickr/shared/widgets/app_logo.dart';
import 'package:kickr/shared/widgets/app_text_field.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreedToTerms) {
      _showError('Please accept the terms and conditions to continue.');
      return;
    }

    ref.read(authNotifierProvider.notifier).clearError();

    await ref.read(authNotifierProvider.notifier).signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          fullName: _nameController.text.trim(),
        );

    if (mounted) {
      final state = ref.read(authNotifierProvider);
      state.whenOrNull(
        data: (_) => _showSuccess(),
        error: (e, _) => _showError(_cleanError(e.toString())),
      );
    }
  }

  void _showSuccess() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Check your email'),
        content: Text(
          'We sent a confirmation link to ${_emailController.text.trim()}. '
          'Please verify your email to complete signup.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go(AppRoutes.login);
            },
            child: const Text('Go to Login'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String _cleanError(String raw) {
    if (raw.contains('User already registered')) {
      return 'An account with this email already exists.';
    }
    if (raw.contains('Password should be')) {
      return 'Password must be at least 6 characters.';
    }
    return 'Something went wrong. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                const AppLogo(),
                const SizedBox(height: 40),
                Text('Create account', style: AppTextStyles.displayMedium),
                const SizedBox(height: 8),
                Text(
                  'Join thousands of students finding internships',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 40),
                AppTextField(
                  label: 'Full Name',
                  hint: 'Ahmed Mohamed',
                  controller: _nameController,
                  keyboardType: TextInputType.name,
                  textInputAction: TextInputAction.next,
                  prefixIcon: Icons.person_outline_rounded,
                  autofillHints: const [AutofillHints.name],
                  enabled: !isLoading,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Name is required';
                    if (v.trim().length < 2) return 'Enter your full name';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                AppTextField(
                  label: 'Email',
                  hint: 'you@example.com',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  prefixIcon: Icons.email_outlined,
                  autofillHints: const [AutofillHints.email],
                  enabled: !isLoading,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email is required';
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                AppTextField(
                  label: 'Password',
                  hint: '••••••••',
                  controller: _passwordController,
                  isPassword: true,
                  textInputAction: TextInputAction.next,
                  prefixIcon: Icons.lock_outline_rounded,
                  autofillHints: const [AutofillHints.newPassword],
                  enabled: !isLoading,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    if (v.length < 6) return 'Password must be at least 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                AppTextField(
                  label: 'Confirm Password',
                  hint: '••••••••',
                  controller: _confirmPasswordController,
                  isPassword: true,
                  textInputAction: TextInputAction.done,
                  prefixIcon: Icons.lock_outline_rounded,
                  enabled: !isLoading,
                  onFieldSubmitted: (_) => _submit(),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Please confirm your password';
                    if (v != _passwordController.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Checkbox(
                      value: _agreedToTerms,
                      onChanged: isLoading
                          ? null
                          : (v) => setState(() => _agreedToTerms = v ?? false),
                      activeColor: AppColors.primary,
                    ),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: 'I agree to the ',
                          style: AppTextStyles.bodyMedium,
                          children: [
                            TextSpan(
                              text: 'Terms of Service',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const TextSpan(text: ' and '),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                AppButton(
                  label: 'Create Account',
                  onPressed: isLoading ? null : _submit,
                  isLoading: isLoading,
                ),
                const SizedBox(height: 24),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: AppTextStyles.bodyMedium,
                      ),
                      GestureDetector(
                        onTap: isLoading ? null : () => context.go(AppRoutes.login),
                        child: Text(
                          'Sign in',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
