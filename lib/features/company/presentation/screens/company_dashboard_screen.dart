import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kickr/core/router/app_router.dart';
import 'package:kickr/core/theme/app_colors.dart';
import 'package:kickr/core/theme/app_text_styles.dart';
import 'package:kickr/features/company/presentation/providers/company_providers.dart';
import 'package:kickr/features/company/presentation/screens/company_profile_edit_screen.dart';
import 'package:kickr/features/company/presentation/screens/company_setup_screen.dart';
import 'package:kickr/features/company/presentation/widgets/company_internship_card.dart';
import 'package:kickr/features/internships/data/company_model.dart';
import 'package:kickr/features/internships/data/internship_model.dart';
import 'package:kickr/shared/widgets/app_button.dart';

class CompanyDashboardScreen extends ConsumerWidget {
  const CompanyDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companyAsync = ref.watch(currentCompanyProvider);
    final internshipsAsync = ref.watch(companyInternshipsProvider);

    return companyAsync.when(
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (_, _) => Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Could not load company data.',
                  style: AppTextStyles.bodyMedium),
              const SizedBox(height: 16),
              AppButton(
                label: 'Retry',
                onPressed: () => ref.invalidate(currentCompanyProvider),
              ),
            ],
          ),
        ),
      ),
      data: (company) {
        if (company == null) {
          return Scaffold(
            appBar: AppBar(
              title: Text('Dashboard', style: AppTextStyles.headlineMedium),
              automaticallyImplyLeading: false,
            ),
            body: _NoCompanyState(
              onSetup: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const CompanySetupScreen(),
                ),
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(company.name, style: AppTextStyles.headlineMedium),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit Company Profile',
                onPressed: () => _openProfileEdit(context, company),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => context.push(
              AppRoutes.companyInternshipCreate,
              extra: company.id,
            ),
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Post Internship'),
          ),
          body: internshipsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            error: (_, _) => _ErrorState(
              onRetry: () =>
                  ref.read(companyInternshipsProvider.notifier).refresh(),
            ),
            data: (list) {
              final active = list.where((i) => i.isActive).toList();
              final inactive = list.where((i) => !i.isActive).toList();

              if (list.isEmpty) {
                return _EmptyState(
                  onPost: () => context.push(
                    AppRoutes.companyInternshipCreate,
                    extra: company.id,
                  ),
                );
              }

              return RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () =>
                    ref.read(companyInternshipsProvider.notifier).refresh(),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                  children: [
                    if (active.isNotEmpty) ...[
                      _SectionHeader(
                          title: 'Active (${active.length})'),
                      const SizedBox(height: 12),
                      ..._buildCards(context, ref, active, company.id),
                    ],
                    if (inactive.isNotEmpty) ...[
                      if (active.isNotEmpty) const SizedBox(height: 20),
                      _SectionHeader(
                          title: 'Inactive (${inactive.length})'),
                      const SizedBox(height: 12),
                      ..._buildCards(context, ref, inactive, company.id),
                    ],
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _openProfileEdit(BuildContext context, Company company) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CompanyProfileEditScreen(company: company),
      ),
    );
  }

  List<Widget> _buildCards(
    BuildContext context,
    WidgetRef ref,
    List<Internship> internships,
    String companyId,
  ) {
    return [
      for (int i = 0; i < internships.length; i++) ...[
        if (i > 0) const SizedBox(height: 12),
        CompanyInternshipCard(
          internship: internships[i],
          onEdit: () => context.push(
            AppRoutes.companyInternshipEditPath(internships[i].id),
            extra: internships[i],
          ),
          onArchive: () => _confirmArchive(context, ref, internships[i]),
          onViewApplicants: () => context.push(
            AppRoutes.companyApplicantsPath(internships[i].id),
            extra: internships[i].title,
          ),
        ),
      ],
    ];
  }

  Future<void> _confirmArchive(
    BuildContext context,
    WidgetRef ref,
    Internship internship,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Archive internship?'),
        content: Text(
          '"${internship.title}" will no longer appear in the student feed. '
          'Existing applications are preserved.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Archive'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await ref
          .read(companyRepositoryProvider)
          .archiveInternship(internship.id);
      if (context.mounted) {
        ref
            .read(companyInternshipsProvider.notifier)
            .setInactive(internship.id);
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'Failed to archive internship. Please try again.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: AppTextStyles.labelMedium);
  }
}

class _NoCompanyState extends StatelessWidget {
  const _NoCompanyState({required this.onSetup});

  final VoidCallback onSetup;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.business_outlined,
                    size: 56,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(height: 16),
                  Text('Set up your company',
                      style: AppTextStyles.headlineMedium),
                  const SizedBox(height: 8),
                  Text(
                    'Create your company profile to start posting internships and reviewing applicants.',
                    style: AppTextStyles.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  AppButton(
                    label: 'Create Company Profile',
                    onPressed: onSetup,
                    icon: const Icon(Icons.add_rounded, size: 18),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onPost});

  final VoidCallback onPost;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.work_outline_rounded,
                    size: 56,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(height: 16),
                  Text('No internships yet', style: AppTextStyles.headlineMedium),
                  const SizedBox(height: 8),
                  Text(
                    'Post your first internship to start receiving applications.',
                    style: AppTextStyles.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  AppButton(
                    label: 'Post Internship',
                    onPressed: onPost,
                    icon: const Icon(Icons.add_rounded, size: 18),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.wifi_off_rounded,
                      size: 48, color: AppColors.textHint),
                  const SizedBox(height: 16),
                  Text('Could not load internships',
                      style: AppTextStyles.headlineMedium),
                  const SizedBox(height: 8),
                  Text('Check your connection and try again.',
                      style: AppTextStyles.bodyMedium,
                      textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  AppButton(label: 'Retry', onPressed: onRetry),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
