import 'package:flutter/material.dart';
import 'package:kickr/core/theme/app_colors.dart';
import 'package:kickr/core/theme/app_text_styles.dart';
import 'package:kickr/features/admin/data/verification_review_entry.dart';
import 'package:kickr/features/profile/data/profile_model.dart';
import 'package:kickr/features/verification/presentation/widgets/verification_badge.dart';

class VerificationReviewCard extends StatelessWidget {
  const VerificationReviewCard({
    super.key,
    required this.entry,
    required this.onApprove,
    required this.onReject,
    required this.onViewId,
    this.isActing = false,
  });

  final VerificationReviewEntry entry;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  /// Callback to open the student's ID document.
  final VoidCallback onViewId;

  /// True while an approve/reject call is in flight — disables action buttons.
  final bool isActing;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.all(Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ────────────────────────────────────────────────────
          Row(
            children: [
              _Avatar(entry: entry),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            entry.displayName,
                            style: AppTextStyles.labelMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        VerificationBadge(status: entry.verificationStatus),
                        if (entry.verificationStatus ==
                            VerificationStatus.unverified)
                          Text(
                            'Unverified',
                            style: AppTextStyles.badge
                                .copyWith(color: AppColors.textSecondary),
                          ),
                      ],
                    ),
                    if (entry.university != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        entry.university!,
                        style: AppTextStyles.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          // ── Verification evidence ─────────────────────────────────────────
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),

          if (entry.hasUniversityEmail)
            _EvidenceRow(
              icon: Icons.email_outlined,
              label: entry.universityEmail!,
            ),
          if (entry.hasStudentId) ...[
            if (entry.hasUniversityEmail) const SizedBox(height: 6),
            _EvidenceRow(
              icon: Icons.badge_outlined,
              label: 'Student ID uploaded',
              trailing: TextButton.icon(
                onPressed: onViewId,
                icon: const Icon(Icons.open_in_new_rounded, size: 14),
                label: const Text('View'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ],
          if (!entry.hasUniversityEmail && !entry.hasStudentId) ...[
            _EvidenceRow(
              icon: Icons.help_outline_rounded,
              label: 'No verification document submitted',
            ),
          ],

          // ── Meta row ─────────────────────────────────────────────────────
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 12, color: AppColors.textHint),
              const SizedBox(width: 4),
              Text(
                'Submitted ${_formatDate(entry.createdAt)}',
                style: AppTextStyles.caption,
              ),
              if (entry.verifiedAt != null) ...[
                const Text(' · ',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
                const Icon(Icons.check_circle_outline_rounded,
                    size: 12, color: AppColors.success),
                const SizedBox(width: 4),
                Text(
                  'Verified ${_formatDate(entry.verifiedAt!)}',
                  style:
                      AppTextStyles.caption.copyWith(color: AppColors.success),
                ),
              ],
            ],
          ),

          // ── Action buttons ────────────────────────────────────────────────
          const SizedBox(height: 12),
          _ActionRow(
            entry: entry,
            onApprove: onApprove,
            onReject: onReject,
            isActing: isActing,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

// ─── Avatar ───────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  const _Avatar({required this.entry});
  final VerificationReviewEntry entry;

  @override
  Widget build(BuildContext context) {
    final url = entry.avatarUrl;
    if (url != null && url.isNotEmpty) {
      return CircleAvatar(
        radius: 22,
        backgroundImage: NetworkImage(url),
        backgroundColor: AppColors.primaryLight,
      );
    }
    return Container(
      width: 44,
      height: 44,
      decoration: const BoxDecoration(
        color: AppColors.primaryLight,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          _initials(entry.displayName),
          style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary),
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isEmpty ? 'A' : name[0].toUpperCase();
  }
}

// ─── Evidence row ─────────────────────────────────────────────────────────────

class _EvidenceRow extends StatelessWidget {
  const _EvidenceRow({
    required this.icon,
    required this.label,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        ?trailing,
      ],
    );
  }
}

// ─── Action row ───────────────────────────────────────────────────────────────

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.entry,
    required this.onApprove,
    required this.onReject,
    required this.isActing,
  });

  final VerificationReviewEntry entry;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final bool isActing;

  @override
  Widget build(BuildContext context) {
    return switch (entry.verificationStatus) {
      VerificationStatus.pending => Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: isActing ? null : onReject,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: BorderSide(color: AppColors.error.withAlpha(120)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Reject'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: isActing ? null : onApprove,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Approve'),
              ),
            ),
          ],
        ),
      VerificationStatus.unverified => SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: isActing ? null : onApprove,
            icon: const Icon(Icons.check_rounded, size: 16),
            label: const Text('Approve'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.success,
              side: BorderSide(color: AppColors.success.withAlpha(120)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      VerificationStatus.verified => SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: isActing ? null : onReject,
            icon: const Icon(Icons.block_rounded, size: 16),
            label: const Text('Revoke Verification'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: BorderSide(color: AppColors.error.withAlpha(80)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
    };
  }
}
