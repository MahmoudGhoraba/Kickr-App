import 'package:flutter/material.dart';
import 'package:kickr/core/theme/app_colors.dart';
import 'package:kickr/core/theme/app_text_styles.dart';
import 'package:kickr/features/applications/data/application_model.dart';
import 'package:kickr/features/applications/presentation/widgets/application_status_badge.dart';
import 'package:kickr/features/company/data/applicant_entry.dart';

class ApplicantCard extends StatelessWidget {
  const ApplicantCard({
    super.key,
    required this.entry,
    required this.onStatusChanged,
    required this.onViewCv,
  });

  final ApplicantEntry entry;
  final ValueChanged<ApplicationStatus> onStatusChanged;
  final VoidCallback onViewCv;

  @override
  Widget build(BuildContext context) {
    final app = entry.application;

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
          Row(
            children: [
              _ApplicantAvatar(entry: entry),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.displayName,
                      style: AppTextStyles.labelMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (entry.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        entry.subtitle!,
                        style: AppTextStyles.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _showStatusPicker(context, app.status),
                child: ApplicationStatusBadge(status: app.status),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 12,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                'Applied ${_formatDate(app.createdAt)}',
                style: AppTextStyles.caption,
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onViewCv,
                icon: const Icon(
                  Icons.picture_as_pdf_outlined,
                  size: 16,
                ),
                label: const Text('View CV'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showStatusPicker(BuildContext context, ApplicationStatus current) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _StatusPickerSheet(
        current: current,
        onSelect: (status) {
          Navigator.of(context).pop();
          onStatusChanged(status);
        },
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

class _ApplicantAvatar extends StatelessWidget {
  const _ApplicantAvatar({required this.entry});

  final ApplicantEntry entry;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = entry.avatarUrl;
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 22,
        backgroundImage: NetworkImage(avatarUrl),
        backgroundColor: AppColors.primaryLight,
      );
    }

    final initials = _initials(entry.displayName);
    return Container(
      width: 44,
      height: 44,
      decoration: const BoxDecoration(
        color: AppColors.primaryLight,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.primary,
          ),
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

class _StatusPickerSheet extends StatelessWidget {
  const _StatusPickerSheet({required this.current, required this.onSelect});

  final ApplicationStatus current;
  final ValueChanged<ApplicationStatus> onSelect;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Update Status', style: AppTextStyles.headlineMedium),
            const SizedBox(height: 16),
            ...ApplicationStatus.values.map(
              (status) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: ApplicationStatusBadge(status: status),
                title: Text(status.label, style: AppTextStyles.bodyLarge),
                trailing: current == status
                    ? const Icon(Icons.check_rounded,
                        color: AppColors.primary)
                    : null,
                onTap: () => onSelect(status),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
