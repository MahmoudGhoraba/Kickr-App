import 'package:flutter/material.dart';
import 'package:kickr/core/theme/app_colors.dart';
import 'package:kickr/core/theme/app_text_styles.dart';
import 'package:kickr/features/profile/data/profile_model.dart';

/// Compact trust indicator chip shown next to applicant names and
/// on student profile screens. Only renders for [verified] and [pending] —
/// unverified produces an empty widget to avoid noise.
class VerificationBadge extends StatelessWidget {
  const VerificationBadge({super.key, required this.status});

  final VerificationStatus status;

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      VerificationStatus.verified => _Badge(
          icon: Icons.verified_rounded,
          label: 'Verified',
          textColor: AppColors.success,
          bgColor: AppColors.successBg,
          borderColor: AppColors.success,
        ),
      VerificationStatus.pending => _Badge(
          icon: Icons.schedule_rounded,
          label: 'Pending',
          textColor: AppColors.warning,
          bgColor: AppColors.warningBg,
          borderColor: AppColors.warning,
        ),
      VerificationStatus.unverified => const SizedBox.shrink(),
    };
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.icon,
    required this.label,
    required this.textColor,
    required this.bgColor,
    required this.borderColor,
  });

  final IconData icon;
  final String label;
  final Color textColor;
  final Color bgColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor.withAlpha(80)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.badge.copyWith(color: textColor),
          ),
        ],
      ),
    );
  }
}
