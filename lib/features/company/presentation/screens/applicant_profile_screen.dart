import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:kickr/core/theme/app_colors.dart';
import 'package:kickr/core/theme/app_text_styles.dart';
import 'package:kickr/features/applications/data/application_model.dart';
import 'package:kickr/features/applications/presentation/widgets/application_status_badge.dart';
import 'package:kickr/features/company/data/applicant_entry.dart';
import 'package:kickr/features/company/presentation/providers/company_providers.dart';
import 'package:kickr/features/verification/presentation/widgets/verification_badge.dart';

/// Full-screen student profile for company reviewers.
///
/// Reads a live snapshot from [applicantsProvider] so the status badge
/// updates immediately after the company changes it — no stale data.
class ApplicantProfileScreen extends ConsumerWidget {
  const ApplicantProfileScreen({
    super.key,
    required this.entry,
    required this.internshipId,
  });

  final ApplicantEntry entry;
  final String internshipId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keep in sync with status changes made on this screen.
    final liveApplicants =
        ref.watch(applicantsProvider(internshipId)).valueOrNull;
    final live = liveApplicants?.firstWhere(
          (e) => e.application.id == entry.application.id,
          orElse: () => entry,
        ) ??
        entry;

    final hasBackground = live.university != null ||
        live.major != null ||
        live.academicYear != null;

    return Scaffold(
      appBar: AppBar(
        title: Text('Applicant Profile', style: AppTextStyles.headlineMedium),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            _ProfileHeader(entry: live),
            const SizedBox(height: 24),

            // ── Application ──────────────────────────────────────────────────
            _SectionLabel('Application'),
            const SizedBox(height: 12),
            _ApplicationCard(
              entry: live,
              onChangeStatus: () => _showStatusPicker(context, ref, live),
              onViewCv: () => _openCv(context, live.application.cvUrl),
            ),

            // ── Skills ───────────────────────────────────────────────────────
            if (live.skills.isNotEmpty) ...[
              const SizedBox(height: 28),
              _SectionLabel('Skills'),
              const SizedBox(height: 12),
              _SkillChips(skills: live.skills),
            ],

            // ── Background ───────────────────────────────────────────────────
            if (hasBackground) ...[
              const SizedBox(height: 28),
              _SectionLabel('Background'),
              const SizedBox(height: 12),
              _BackgroundCard(entry: live),
            ],
          ],
        ),
      ),
    );
  }

  void _showStatusPicker(
    BuildContext context,
    WidgetRef ref,
    ApplicantEntry live,
  ) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _StatusPickerSheet(
        current: live.application.status,
        onSelect: (status) async {
          Navigator.of(context).pop();
          try {
            await ref
                .read(applicantsProvider(internshipId).notifier)
                .updateStatus(live.application.id, status);
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to update status: $e'),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            }
          }
        },
      ),
    );
  }

  Future<void> _openCv(BuildContext context, String cvUrl) async {
    final uri = Uri.tryParse(cvUrl.trim());
    if (uri == null || !uri.isAbsolute) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('CV link is not available.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.platformDefault);
      if (!opened) await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open CV.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

// ─── Section label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppTextStyles.caption.copyWith(
        letterSpacing: 0.8,
        fontWeight: FontWeight.w600,
        color: AppColors.textHint,
      ),
    );
  }
}

// ─── Profile header ───────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.entry});
  final ApplicantEntry entry;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _LargeAvatar(entry: entry),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.displayName,
                style: AppTextStyles.headlineLarge,
              ),
              const SizedBox(height: 4),
              VerificationBadge(status: entry.verificationStatus),
              if (entry.subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  entry.subtitle!,
                  style: AppTextStyles.bodyMedium,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _LargeAvatar extends StatelessWidget {
  const _LargeAvatar({required this.entry});
  final ApplicantEntry entry;

  @override
  Widget build(BuildContext context) {
    final url = entry.avatarUrl;
    if (url != null && url.isNotEmpty) {
      return CircleAvatar(
        radius: 36,
        backgroundImage: NetworkImage(url),
        backgroundColor: AppColors.primaryLight,
      );
    }
    return Container(
      width: 72,
      height: 72,
      decoration: const BoxDecoration(
        color: AppColors.primaryLight,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          _initials(entry.displayName),
          style: AppTextStyles.headlineLarge.copyWith(
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

// ─── Application card ─────────────────────────────────────────────────────────

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({
    required this.entry,
    required this.onChangeStatus,
    required this.onViewCv,
  });

  final ApplicantEntry entry;
  final VoidCallback onChangeStatus;
  final VoidCallback onViewCv;

  @override
  Widget build(BuildContext context) {
    final app = entry.application;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.event_available_outlined,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                'Applied on ${_formatDate(app.createdAt)}',
                style: AppTextStyles.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Status', style: AppTextStyles.caption),
                    const SizedBox(height: 4),
                    ApplicationStatusBadge(status: app.status),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: onChangeStatus,
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Update'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onViewCv,
              icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
              label: const Text('View CV'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
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

// ─── Skills ───────────────────────────────────────────────────────────────────

class _SkillChips extends StatelessWidget {
  const _SkillChips({required this.skills});
  final List<String> skills;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: skills
          .map(
            (s) => Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primary.withAlpha(50),
                ),
              ),
              child: Text(
                s,
                style:
                    AppTextStyles.badge.copyWith(color: AppColors.primary),
              ),
            ),
          )
          .toList(),
    );
  }
}

// ─── Background card ──────────────────────────────────────────────────────────

class _BackgroundCard extends StatelessWidget {
  const _BackgroundCard({required this.entry});
  final ApplicantEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          if (entry.university != null)
            _BackgroundRow(
              icon: Icons.account_balance_outlined,
              label: entry.university!,
              divider: entry.major != null || entry.academicYear != null,
            ),
          if (entry.major != null)
            _BackgroundRow(
              icon: Icons.school_outlined,
              label: entry.major!,
              divider: entry.academicYear != null,
            ),
          if (entry.academicYear != null)
            _BackgroundRow(
              icon: Icons.calendar_month_outlined,
              label: entry.academicYear!,
              divider: false,
            ),
        ],
      ),
    );
  }
}

class _BackgroundRow extends StatelessWidget {
  const _BackgroundRow({
    required this.icon,
    required this.label,
    required this.divider,
  });

  final IconData icon;
  final String label;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label, style: AppTextStyles.bodyLarge),
              ),
            ],
          ),
        ),
        if (divider)
          const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.border),
      ],
    );
  }
}

// ─── Status picker sheet ──────────────────────────────────────────────────────

class _StatusPickerSheet extends StatelessWidget {
  const _StatusPickerSheet({
    required this.current,
    required this.onSelect,
  });

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
                    ? const Icon(Icons.check_rounded, color: AppColors.primary)
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
