import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kickr/core/theme/app_colors.dart';
import 'package:kickr/core/theme/app_text_styles.dart';
import 'package:kickr/features/applications/presentation/providers/application_providers.dart';
import 'package:kickr/features/applications/presentation/widgets/apply_bottom_sheet.dart';
import 'package:kickr/core/constants/role_constants.dart';
import 'package:kickr/core/router/app_router.dart';
import 'package:kickr/features/auth/presentation/providers/auth_providers.dart';
import 'package:kickr/features/internships/data/company_model.dart';
import 'package:kickr/features/profile/data/profile_model.dart';
import 'package:kickr/features/profile/presentation/providers/profile_providers.dart';
import 'package:kickr/features/internships/data/internship_model.dart';
import 'package:kickr/features/internships/presentation/providers/internship_providers.dart';
import 'package:kickr/features/internships/presentation/widgets/company_avatar.dart';
import 'package:kickr/features/internships/presentation/widgets/deadline_badge.dart';
import 'package:kickr/features/internships/presentation/widgets/internship_chips.dart';

class InternshipDetailScreen extends ConsumerStatefulWidget {
  const InternshipDetailScreen({super.key, required this.internshipId});

  final String internshipId;

  @override
  ConsumerState<InternshipDetailScreen> createState() =>
      _InternshipDetailScreenState();
}

class _InternshipDetailScreenState
    extends ConsumerState<InternshipDetailScreen> {
  bool _viewTracked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _trackView());
  }

  Future<void> _trackView() async {
    if (_viewTracked) return;
    final userId =
        ref.read(authStateProvider).valueOrNull?.session?.user.id;
    if (userId == null) return;
    _viewTracked = true;
    try {
      await ref
          .read(internshipRepositoryProvider)
          .trackView(internshipId: widget.internshipId, userId: userId);
    } catch (_) {
      // View tracking is non-critical; silently ignore failures.
    }
  }

  @override
  Widget build(BuildContext context) {
    final internshipAsync =
        ref.watch(internshipDetailProvider(widget.internshipId));
    final savedIds = ref.watch(savedInternshipIdsProvider);
    final isSaved =
        savedIds.valueOrNull?.contains(widget.internshipId) ?? false;

    return internshipAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (_, _) => Scaffold(
        appBar: AppBar(title: const Text('Internship Details')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 48, color: AppColors.textHint),
                const SizedBox(height: 16),
                Text('Could not load internship',
                    style: AppTextStyles.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  'Check your connection and try again.',
                  style: AppTextStyles.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextButton.icon(
                  onPressed: () => ref
                      .invalidate(internshipDetailProvider(widget.internshipId)),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
                TextButton.icon(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Go back'),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (internship) => Scaffold(
        appBar: AppBar(
          title: Text(
            internship.title,
            style: AppTextStyles.labelMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            IconButton(
              icon: Icon(
                isSaved
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_outline_rounded,
                color: isSaved ? AppColors.primary : null,
              ),
              onPressed: () => ref
                  .read(savedInternshipIdsProvider.notifier)
                  .toggle(widget.internshipId),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 48),
          child: _DetailBody(internship: internship),
        ),
        bottomNavigationBar: _ApplyBar(
          internshipId: widget.internshipId,
          internship: internship,
        ),
      ),
    );
  }
}

// ─── Apply Bar ────────────────────────────────────────────────────────────────

class _ApplyBar extends ConsumerWidget {
  const _ApplyBar({required this.internshipId, required this.internship});

  final String internshipId;
  final Internship internship;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);
    final appsAsync = ref.watch(applicationsProvider);
    final hasApplied = ref.watch(hasAppliedProvider(internshipId));

    // Company users do not apply — hide the bar entirely.
    final profile = profileAsync.valueOrNull;
    if (profile != null && profile.effectiveRole == UserRole.company) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: _buildContent(
          context,
          profile: profile,
          isAppsLoading: appsAsync.isLoading,
          hasApplied: hasApplied,
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context, {
    required Profile? profile,
    required bool isAppsLoading,
    required bool hasApplied,
  }) {
    // Expired internship — show closed state (overrides everything except applied).
    if (internship.isExpired && !hasApplied) {
      return _ClosedChip();
    }

    // Student has already applied — no re-apply.
    if (hasApplied) {
      return _AppliedChip();
    }

    // Profile still loading — treat conservatively as unverified.
    if (profile == null) {
      return _VerifyBanner(context: context);
    }

    // Verified student → normal apply flow.
    if (profile.isVerified) {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: isAppsLoading ? null : () => _showApplySheet(context),
          child: isAppsLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.white,
                  ),
                )
              : Text('Apply Now', style: AppTextStyles.labelLarge),
        ),
      );
    }

    // Pending verification — encourage patience.
    if (profile.verificationStatus == VerificationStatus.pending) {
      return _PendingVerificationChip(context: context);
    }

    // Unverified student — prompt to verify.
    return _VerifyBanner(context: context);
  }

  void _showApplySheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ApplyBottomSheet(
        internshipId: internshipId,
        internshipTitle: internship.title,
        companyName: internship.company?.name,
      ),
    );
  }
}

class _ClosedChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.errorBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.error.withAlpha(80)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.event_busy_rounded,
                color: AppColors.error, size: 20),
            const SizedBox(width: 8),
            Text(
              'Application Closed',
              style: AppTextStyles.labelLarge.copyWith(color: AppColors.error),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppliedChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.successBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.success.withAlpha(80)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_rounded,
                color: AppColors.success, size: 20),
            const SizedBox(width: 8),
            Text(
              'Applied',
              style:
                  AppTextStyles.labelLarge.copyWith(color: AppColors.success),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerifyBanner extends StatelessWidget {
  const _VerifyBanner({required this.context});

  final BuildContext context;

  @override
  Widget build(BuildContext outerContext) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.infoBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.info.withAlpha(60)),
          ),
          child: Row(
            children: [
              const Icon(Icons.shield_outlined,
                  color: AppColors.info, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Verify your student status to start applying for internships.',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.info),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () => outerContext.push(AppRoutes.verification),
            icon: const Icon(Icons.verified_user_outlined, size: 18),
            label: Text('Verify Now', style: AppTextStyles.labelLarge),
          ),
        ),
      ],
    );
  }
}

class _PendingVerificationChip extends StatelessWidget {
  const _PendingVerificationChip({required this.context});

  final BuildContext context;

  @override
  Widget build(BuildContext outerContext) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.warningBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.warning.withAlpha(60)),
          ),
          child: Row(
            children: [
              const Icon(Icons.schedule_rounded,
                  color: AppColors.warning, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Verification pending review — usually 1–2 business days.',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.warning),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () => outerContext.push(AppRoutes.verification),
            icon: const Icon(Icons.info_outline_rounded, size: 18),
            label: const Text('Check Status'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.warning,
              side: const BorderSide(color: AppColors.warning),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Detail body (unchanged from Stage 2) ────────────────────────────────────

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.internship});

  final Internship internship;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (internship.company != null)
          _CompanyHeader(company: internship.company!),
        const SizedBox(height: 20),
        Text(internship.title, style: AppTextStyles.displayMedium),
        const SizedBox(height: 12),
        _MetaRow(internship: internship),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 24),
        Text('About this internship', style: AppTextStyles.headlineMedium),
        const SizedBox(height: 12),
        Text(
          internship.description,
          style: AppTextStyles.bodyLarge.copyWith(height: 1.6),
        ),
        if (internship.requiredSkills.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),
          Text('Required Skills', style: AppTextStyles.headlineMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: internship.requiredSkills
                .map((s) => _SkillTag(skill: s))
                .toList(),
          ),
        ],
        if (internship.company?.description != null) ...[
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),
          Text(
            'About ${internship.company!.name}',
            style: AppTextStyles.headlineMedium,
          ),
          const SizedBox(height: 12),
          Text(
            internship.company!.description!,
            style: AppTextStyles.bodyMedium.copyWith(height: 1.6),
          ),
        ],
      ],
    );
  }
}

class _CompanyHeader extends StatelessWidget {
  const _CompanyHeader({required this.company});

  final Company company;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CompanyAvatar(company: company, size: 60),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(company.name, style: AppTextStyles.headlineMedium),
                  if (company.industry != null) ...[
                    const SizedBox(height: 2),
                    Text(company.industry!, style: AppTextStyles.bodyMedium),
                  ],
                  if (company.location != null || company.companySize != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (company.location != null) ...[
                          const Icon(Icons.location_on_outlined,
                              size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              company.location!,
                              style: AppTextStyles.caption,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                        if (company.location != null && company.companySize != null)
                          const Text(' · ',
                              style: TextStyle(
                                  color: AppColors.textSecondary, fontSize: 12)),
                        if (company.companySize != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.people_outline_rounded,
                                  size: 14, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Text(company.companySize!,
                                  style: AppTextStyles.caption),
                            ],
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        if (company.cultureDescription != null) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.primary.withAlpha(40)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Culture & Values',
                    style: AppTextStyles.labelMedium
                        .copyWith(color: AppColors.primary)),
                const SizedBox(height: 4),
                Text(
                  company.cultureDescription!,
                  style: AppTextStyles.bodyMedium.copyWith(height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.internship});

  final Internship internship;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _MetaBadge(
          icon: Icons.location_on_outlined,
          label: internship.location,
        ),
        InternshipTypeBadge(type: internship.type),
        if (internship.category != null)
          _MetaBadge(
            icon: Icons.work_outline_rounded,
            label: internship.category!,
          ),
        if (internship.deadline != null)
          DeadlineBadge(deadline: internship.deadline!),
      ],
    );
  }
}

class _MetaBadge extends StatelessWidget {
  const _MetaBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style:
                AppTextStyles.caption.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _SkillTag extends StatelessWidget {
  const _SkillTag({required this.skill});

  final String skill;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withAlpha(50)),
      ),
      child: Text(
        skill,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
