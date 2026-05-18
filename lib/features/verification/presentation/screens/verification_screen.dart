import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kickr/core/constants/university_domains.dart';
import 'package:kickr/core/theme/app_colors.dart';
import 'package:kickr/core/theme/app_text_styles.dart';
import 'package:kickr/features/auth/presentation/providers/auth_providers.dart';
import 'package:kickr/features/profile/data/profile_model.dart';
import 'package:kickr/features/profile/presentation/providers/profile_providers.dart';
import 'package:kickr/features/verification/presentation/providers/verification_providers.dart';
import 'package:kickr/features/verification/presentation/widgets/verification_badge.dart';
import 'package:kickr/shared/widgets/app_button.dart';

class VerificationScreen extends ConsumerWidget {
  const VerificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);
    final authEmail =
        ref.watch(authStateProvider).valueOrNull?.session?.user.email ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text('Student Verification', style: AppTextStyles.headlineMedium),
      ),
      body: profileAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (_, _) => const Center(child: Text('Could not load profile.')),
        data: (profile) => _VerificationBody(
          profile: profile,
          authEmail: authEmail,
        ),
      ),
    );
  }
}

// ─── Body ─────────────────────────────────────────────────────────────────────

class _VerificationBody extends ConsumerWidget {
  const _VerificationBody({
    required this.profile,
    required this.authEmail,
  });

  final Profile? profile;
  final String authEmail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vState = ref.watch(verificationNotifierProvider);
    final currentStatus =
        profile?.verificationStatus ?? VerificationStatus.unverified;
    final displayStatus = vState.resultStatus ?? currentStatus;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(status: displayStatus),
          const SizedBox(height: 32),

          if (displayStatus == VerificationStatus.verified) ...[
            _VerifiedState(),
          ] else if (displayStatus == VerificationStatus.pending) ...[
            _PendingState(
              existingEmail: profile?.universityEmail ??
                  (authEmail.isNotEmpty ? authEmail : null),
            ),
          ] else ...[
            // If the signup email is a university domain, offer one-tap verification
            // so the student doesn't have to retype what they already provided.
            if (authEmail.isNotEmpty &&
                UniversityDomains.isUniversityEmail(authEmail)) ...[
              _SignupEmailBanner(authEmail: authEmail),
              const SizedBox(height: 24),
              _OrDivider(),
              const SizedBox(height: 24),
            ],
            _EmailSection(authEmail: authEmail),
            const SizedBox(height: 24),
            _OrDivider(),
            const SizedBox(height: 24),
            _StudentIdSection(),
          ],

          if (vState.error != null) ...[
            const SizedBox(height: 16),
            _ErrorBanner(message: vState.error!),
          ],
        ],
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.status});

  final VerificationStatus status;

  @override
  Widget build(BuildContext context) {
    final isVerified = status == VerificationStatus.verified;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: isVerified ? AppColors.successBg : AppColors.primaryLight,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            isVerified ? Icons.verified_rounded : Icons.shield_outlined,
            size: 28,
            color: isVerified ? AppColors.success : AppColors.primary,
          ),
        ),
        const SizedBox(height: 16),
        Text('Student Verification', style: AppTextStyles.headlineLarge),
        const SizedBox(height: 8),
        Text(
          'Verify your student status to unlock applications and '
          'build trust with companies.',
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Text('Current status: ', style: AppTextStyles.caption),
            const SizedBox(width: 6),
            if (status == VerificationStatus.unverified)
              Text(
                'Not Verified',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary),
              )
            else
              VerificationBadge(status: status),
          ],
        ),
      ],
    );
  }
}

// ─── Signup email banner (one-tap shortcut) ───────────────────────────────────

/// Shown when the student's signup email is already a university email.
/// Lets them verify in one tap without retyping the address.
class _SignupEmailBanner extends ConsumerWidget {
  const _SignupEmailBanner({required this.authEmail});

  final String authEmail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vState = ref.watch(verificationNotifierProvider);
    final notifier = ref.read(verificationNotifierProvider.notifier);
    final isTrusted = UniversityDomains.isTrustedDomain(authEmail);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isTrusted ? AppColors.successBg : AppColors.warningBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (isTrusted ? AppColors.success : AppColors.warning)
              .withAlpha(80),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isTrusted
                    ? Icons.verified_rounded
                    : Icons.school_outlined,
                size: 18,
                color:
                    isTrusted ? AppColors.success : AppColors.warning,
              ),
              const SizedBox(width: 8),
              Text(
                isTrusted
                    ? 'Instant verification available'
                    : 'University email detected',
                style: AppTextStyles.labelMedium.copyWith(
                  color:
                      isTrusted ? AppColors.success : AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isTrusted
                ? 'You signed up with a recognised university email. '
                    'Tap below to verify instantly — no need to type it again.'
                : 'You signed up with a university email. '
                    'Tap below to submit it for review.',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 4),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.email_outlined,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(authEmail, style: AppTextStyles.caption),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: AppButton(
              label: isTrusted ? 'Verify Instantly' : 'Submit for Review',
              isLoading: vState.isSubmitting,
              onPressed: vState.isSubmitting
                  ? null
                  : () {
                      notifier.setEmailInput(authEmail);
                      notifier.submitEmail();
                    },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Verified state ───────────────────────────────────────────────────────────

class _VerifiedState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.successBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withAlpha(80)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: AppColors.success,
            size: 56,
          ),
          const SizedBox(height: 16),
          Text(
            'You\'re Verified!',
            style:
                AppTextStyles.headlineMedium.copyWith(color: AppColors.success),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Your student status is confirmed. You can now apply to '
            'internships and appear as a trusted applicant.',
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Pending state ────────────────────────────────────────────────────────────

class _PendingState extends StatelessWidget {
  const _PendingState({required this.existingEmail});

  final String? existingEmail;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.warningBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.schedule_rounded,
                  color: AppColors.warning, size: 22),
              const SizedBox(width: 10),
              Text(
                'Verification Pending',
                style:
                    AppTextStyles.labelMedium.copyWith(color: AppColors.warning),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Your verification request is under review. This typically '
            'takes 1–2 business days.',
            style: AppTextStyles.bodyMedium,
          ),
          if (existingEmail != null && existingEmail!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.email_outlined,
                      size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Text(existingEmail!, style: AppTextStyles.caption),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            'You\'ll be notified once verified. '
            'You can keep exploring internships in the meantime.',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}

// ─── Email section ────────────────────────────────────────────────────────────

class _EmailSection extends ConsumerStatefulWidget {
  const _EmailSection({required this.authEmail});

  final String authEmail;

  @override
  ConsumerState<_EmailSection> createState() => _EmailSectionState();
}

class _EmailSectionState extends ConsumerState<_EmailSection> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    // Pre-fill with auth email only if it is NOT a university email;
    // if it IS a university email the _SignupEmailBanner handles it above.
    final prefill = UniversityDomains.isUniversityEmail(widget.authEmail)
        ? ''
        : widget.authEmail;
    _controller = TextEditingController(text: prefill);
    if (prefill.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(verificationNotifierProvider.notifier).setEmailInput(prefill);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vState = ref.watch(verificationNotifierProvider);
    final notifier = ref.read(verificationNotifierProvider.notifier);
    final email = vState.emailInput;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MethodHeader(
          icon: Icons.email_outlined,
          title: 'University Email',
          subtitle: 'Fastest method — get instantly verified if your '
              'university is on our list.',
          badgeLabel: 'Recommended',
          badgeColor: AppColors.primary,
        ),
        const SizedBox(height: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('University email address', style: AppTextStyles.labelMedium),
            const SizedBox(height: 8),
            TextFormField(
              controller: _controller,
              keyboardType: TextInputType.emailAddress,
              style: AppTextStyles.bodyLarge,
              decoration: const InputDecoration(
                hintText: 'e.g. name@guc.edu.eg',
              ),
              onChanged: notifier.setEmailInput,
            ),
          ],
        ),
        const SizedBox(height: 8),
        _DomainHint(email: email),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: AppButton(
            label: 'Verify with Email',
            isLoading: vState.isSubmitting,
            onPressed:
                vState.isSubmitting ? null : () => _submit(context),
          ),
        ),
      ],
    );
  }

  void _submit(BuildContext context) {
    final email = ref.read(verificationNotifierProvider).emailInput.trim();
    if (!UniversityDomains.isUniversityEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Please enter a valid university email (.edu.eg or .edu domain).',
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }
    ref.read(verificationNotifierProvider.notifier).submitEmail();
  }
}

class _DomainHint extends StatelessWidget {
  const _DomainHint({required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    if (email.isEmpty || !email.contains('@')) {
      return Text(
        'Examples: name@guc.edu.eg, name@aucegypt.edu, name@cu.edu.eg',
        style: AppTextStyles.caption,
      );
    }

    final isTrusted = UniversityDomains.isTrustedDomain(email);
    final isUniversity = UniversityDomains.isUniversityEmail(email);

    if (isTrusted) {
      return Row(
        children: [
          const Icon(Icons.check_circle_rounded,
              size: 14, color: AppColors.success),
          const SizedBox(width: 4),
          Text(
            'Recognised university — instant verification',
            style: AppTextStyles.caption.copyWith(color: AppColors.success),
          ),
        ],
      );
    }

    if (isUniversity) {
      return Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 14, color: AppColors.warning),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              'University domain detected — will be reviewed manually (1–2 days)',
              style: AppTextStyles.caption.copyWith(color: AppColors.warning),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        const Icon(Icons.error_outline_rounded,
            size: 14, color: AppColors.error),
        const SizedBox(width: 4),
        Text(
          'Domain not recognised as a university email',
          style: AppTextStyles.caption.copyWith(color: AppColors.error),
        ),
      ],
    );
  }
}

// ─── Student ID section ───────────────────────────────────────────────────────

class _StudentIdSection extends ConsumerWidget {
  const _StudentIdSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vState = ref.watch(verificationNotifierProvider);
    final notifier = ref.read(verificationNotifierProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MethodHeader(
          icon: Icons.badge_outlined,
          title: 'Student ID',
          subtitle: 'Upload a photo of your university ID or enrollment proof.',
          badgeLabel: 'Manual Review',
          badgeColor: AppColors.textSecondary,
        ),
        const SizedBox(height: 16),

        if (vState.hasPickedId) ...[
          _FileCard(
            icon: Icons.image_rounded,
            iconColor: AppColors.success,
            title: vState.pickedIdName ?? 'Selected image',
            subtitle: 'Ready to upload',
            onReplace:
                vState.isSubmitting ? null : () => notifier.pickStudentId(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: AppButton(
              label: 'Upload Student ID',
              isLoading: vState.isSubmitting,
              onPressed:
                  vState.isSubmitting ? null : () => notifier.submitStudentId(),
            ),
          ),
        ] else ...[
          OutlinedButton.icon(
            onPressed:
                vState.isSubmitting ? null : () => notifier.pickStudentId(),
            icon: const Icon(Icons.upload_rounded),
            label: const Text('Select Image (max 5 MB)'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: const BorderSide(color: AppColors.border),
              foregroundColor: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Accepted: JPG, PNG. Your document is stored securely '
            'and never shared publicly.',
            style: AppTextStyles.caption,
          ),
        ],
      ],
    );
  }
}

// ─── Shared sub-widgets ───────────────────────────────────────────────────────

class _MethodHeader extends StatelessWidget {
  const _MethodHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badgeLabel,
    required this.badgeColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String badgeLabel;
  final Color badgeColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(icon, size: 20, color: AppColors.textSecondary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(title, style: AppTextStyles.labelMedium),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: badgeColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                      border:
                          Border.all(color: badgeColor.withAlpha(60)),
                    ),
                    child: Text(
                      badgeLabel,
                      style: AppTextStyles.badge.copyWith(color: badgeColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(subtitle, style: AppTextStyles.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

class _FileCard extends StatelessWidget {
  const _FileCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onReplace,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onReplace;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.labelMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTextStyles.caption),
              ],
            ),
          ),
          if (onReplace != null)
            TextButton(
              onPressed: onReplace,
              child: const Text('Replace'),
            ),
        ],
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('or', style: AppTextStyles.caption),
        ),
        const Expanded(child: Divider(color: AppColors.border)),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.errorBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withAlpha(60)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.caption.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
