import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kickr/core/theme/app_colors.dart';
import 'package:kickr/core/theme/app_text_styles.dart';
import 'package:kickr/features/applications/presentation/providers/application_providers.dart';
import 'package:kickr/features/applications/presentation/widgets/apply_bottom_sheet.dart';
import 'package:kickr/features/auth/presentation/providers/auth_providers.dart';
import 'package:kickr/features/internships/data/company_model.dart';
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
    final appsAsync = ref.watch(applicationsProvider);
    final hasApplied = ref.watch(hasAppliedProvider(internshipId));

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: appsAsync.isLoading
            ? _applyButton(context, isLoading: true, hasApplied: false)
            : _applyButton(context, isLoading: false, hasApplied: hasApplied),
      ),
    );
  }

  Widget _applyButton(
    BuildContext context, {
    required bool isLoading,
    required bool hasApplied,
  }) {
    if (internship.isExpired && !hasApplied) {
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
                style: AppTextStyles.labelLarge
                    .copyWith(color: AppColors.error),
              ),
            ],
          ),
        ),
      );
    }

    if (hasApplied) {
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
                style: AppTextStyles.labelLarge
                    .copyWith(color: AppColors.success),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading
            ? null
            : () => _showApplySheet(context),
        child: isLoading
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
