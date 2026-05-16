import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kickr/core/theme/app_colors.dart';
import 'package:kickr/core/theme/app_text_styles.dart';
import 'package:kickr/features/applications/presentation/providers/application_providers.dart';
import 'package:kickr/shared/widgets/app_button.dart';

class ApplyBottomSheet extends ConsumerWidget {
  const ApplyBottomSheet({
    super.key,
    required this.internshipId,
    required this.internshipTitle,
    this.companyName,
  });

  final String internshipId;
  final String internshipTitle;
  final String? companyName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applyState = ref.watch(applyNotifierProvider);
    final cvUrlAsync = ref.watch(userCvUrlProvider);
    final existingCvUrl = cvUrlAsync.valueOrNull;
    final notifier = ref.read(applyNotifierProvider.notifier);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DragHandle(),
              const SizedBox(height: 8),

              if (applyState.isSuccess) ...[
                _SuccessState(onDone: () => Navigator.of(context).pop()),
              ] else ...[
                Text(
                  companyName != null
                      ? 'Apply to $companyName'
                      : 'Apply for internship',
                  style: AppTextStyles.headlineMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  internshipTitle,
                  style: AppTextStyles.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 24),

                Text('Your CV', style: AppTextStyles.labelMedium),
                const SizedBox(height: 12),

                _CvSection(
                  applyState: applyState,
                  existingCvUrl: existingCvUrl,
                  onPickFile: applyState.isLoading
                      ? null
                      : () => notifier.pickFile(),
                ),

                if (applyState.error != null) ...[
                  const SizedBox(height: 12),
                  _ErrorMessage(message: applyState.error!),
                ],

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    label: 'Submit Application',
                    isLoading: applyState.isLoading,
                    onPressed: (applyState.hasFile ||
                                (existingCvUrl != null &&
                                    existingCvUrl.isNotEmpty)) &&
                            !applyState.isLoading
                        ? () => notifier.submit(
                              internshipId: internshipId,
                              existingCvUrl:
                                  applyState.hasFile ? null : existingCvUrl,
                            )
                        : null,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _CvSection extends StatelessWidget {
  const _CvSection({
    required this.applyState,
    required this.existingCvUrl,
    required this.onPickFile,
  });

  final ApplyState applyState;
  final String? existingCvUrl;
  final VoidCallback? onPickFile;

  @override
  Widget build(BuildContext context) {
    // New file just picked
    if (applyState.hasFile) {
      return _FileCard(
        icon: Icons.check_circle_rounded,
        iconColor: AppColors.success,
        title: applyState.pickedFileName ?? 'Selected file',
        subtitle: 'PDF ready to upload',
        trailingAction: TextButton(
          onPressed: onPickFile,
          child: const Text('Change'),
        ),
      );
    }

    // No new file, but user has a saved CV on their profile
    if (existingCvUrl != null && existingCvUrl!.isNotEmpty) {
      return _FileCard(
        icon: Icons.description_rounded,
        iconColor: AppColors.primary,
        title: 'Your saved CV',
        subtitle: 'Previously uploaded PDF',
        trailingAction: TextButton(
          onPressed: onPickFile,
          child: const Text('Change'),
        ),
      );
    }

    // No file, no saved CV — prompt upload
    return OutlinedButton.icon(
      onPressed: onPickFile,
      icon: const Icon(Icons.upload_file_rounded),
      label: const Text('Select PDF (max 5 MB)'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        side: const BorderSide(color: AppColors.border),
        foregroundColor: AppColors.textSecondary,
      ),
    );
  }
}

class _FileCard extends StatelessWidget {
  const _FileCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.trailingAction,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget trailingAction;

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
          trailingAction,
        ],
      ),
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage({required this.message});

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
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessState extends StatelessWidget {
  const _SuccessState({required this.onDone});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: AppColors.success,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'Application Submitted!',
            style: AppTextStyles.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Your application is pending review.\nWe\'ll keep you posted on any updates.',
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: AppButton(label: 'Done', onPressed: onDone),
          ),
        ],
      ),
    );
  }
}
