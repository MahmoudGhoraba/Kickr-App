import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:kickr/core/theme/app_colors.dart';
import 'package:kickr/core/theme/app_text_styles.dart';
import 'package:kickr/features/applications/data/application_model.dart';
import 'package:kickr/features/company/presentation/providers/company_providers.dart';
import 'package:kickr/features/company/presentation/widgets/applicant_card.dart';
import 'package:kickr/shared/widgets/app_button.dart';

class ApplicantListScreen extends ConsumerWidget {
  const ApplicantListScreen({
    super.key,
    required this.internshipId,
    required this.internshipTitle,
  });

  final String internshipId;
  final String internshipTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applicantsAsync = ref.watch(applicantsProvider(internshipId));

    return Scaffold(
      appBar: AppBar(
        title: Text(internshipTitle, style: AppTextStyles.headlineMedium),
      ),
      body: applicantsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (_, _) => _ErrorState(
          onRetry: () =>
              ref.read(applicantsProvider(internshipId).notifier).refresh(),
        ),
        data: (list) => list.isEmpty
            ? const _EmptyState()
            : RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () =>
                    ref.read(applicantsProvider(internshipId).notifier).refresh(),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  children: [
                    _ApplicantCount(count: list.length),
                    const SizedBox(height: 12),
                    for (int i = 0; i < list.length; i++) ...[
                      if (i > 0) const SizedBox(height: 12),
                      ApplicantCard(
                        entry: list[i],
                        onStatusChanged: (status) => _updateStatus(
                          context,
                          ref,
                          list[i].application.id,
                          status,
                        ),
                        onViewCv: () => _openCv(context, list[i].application.cvUrl),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Future<void> _updateStatus(
    BuildContext context,
    WidgetRef ref,
    String applicationId,
    ApplicationStatus status,
  ) async {
    try {
      await ref
          .read(applicantsProvider(internshipId).notifier)
          .updateStatus(applicationId, status);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Future<void> _openCv(BuildContext context, String cvUrl) async {
    final uri = Uri.tryParse(cvUrl);
    if (uri == null) return;

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open CV. Copy the URL manually.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _ApplicantCount extends StatelessWidget {
  const _ApplicantCount({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.infoBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count applicant${count == 1 ? '' : 's'}',
        style: AppTextStyles.labelMedium.copyWith(color: AppColors.info),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

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
                  const Icon(Icons.inbox_rounded,
                      size: 56, color: AppColors.textHint),
                  const SizedBox(height: 16),
                  Text('No applicants yet',
                      style: AppTextStyles.headlineMedium),
                  const SizedBox(height: 8),
                  Text(
                    'Applications will appear here once students apply.',
                    style: AppTextStyles.bodyMedium,
                    textAlign: TextAlign.center,
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
                  Text('Could not load applicants',
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
