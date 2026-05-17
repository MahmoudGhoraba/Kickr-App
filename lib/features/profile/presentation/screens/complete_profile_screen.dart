import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kickr/core/theme/app_colors.dart';
import 'package:kickr/core/theme/app_text_styles.dart';
import 'package:kickr/features/auth/presentation/providers/auth_providers.dart';
import 'package:kickr/features/profile/presentation/providers/profile_providers.dart';
import 'package:kickr/features/profile/presentation/widgets/academic_year_selector.dart';
import 'package:kickr/features/profile/presentation/widgets/major_selector_field.dart';
import 'package:kickr/features/profile/presentation/widgets/skills_input_field.dart';
import 'package:kickr/features/profile/presentation/widgets/university_selector_field.dart';
import 'package:kickr/shared/widgets/app_button.dart';
import 'package:kickr/shared/widgets/app_text_field.dart';

/// Mandatory profile completion screen shown to students after first login.
///
/// The user cannot access the internship feed until this is submitted.
/// GoRouter redirect handles navigation away once profileCompleted becomes true.
class CompleteProfileScreen extends ConsumerStatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  ConsumerState<CompleteProfileScreen> createState() =>
      _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends ConsumerState<CompleteProfileScreen> {
  final _nameCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final profile = ref.read(currentProfileProvider).valueOrNull;
      if (profile != null) {
        _nameCtrl.text = profile.fullName ?? '';
        ref.read(completeProfileProvider.notifier).init(profile);
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(completeProfileProvider);
    final notifier = ref.read(completeProfileProvider.notifier);

    ref.listen<CompleteProfileState>(completeProfileProvider, (_, next) {
      if (next.error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    });

    return Scaffold(
      // No back button — completion is mandatory.
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Set Up Your Profile', style: AppTextStyles.headlineMedium),
        actions: [
          TextButton.icon(
            onPressed: () =>
                ref.read(authNotifierProvider.notifier).signOut(),
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: const Text('Sign out'),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero banner ──────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withAlpha(204),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'One step to unlock Kickr 🚀',
                    style: AppTextStyles.headlineMedium
                        .copyWith(color: AppColors.white),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Companies use your profile to evaluate applicants. '
                    'A complete profile means more visibility and better matches.',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.white.withAlpha(220)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── Full Name ────────────────────────────────────────────────
            AppTextField(
              label: 'Full Name *',
              hint: 'Ahmed Mohamed',
              controller: _nameCtrl,
              keyboardType: TextInputType.name,
              textInputAction: TextInputAction.next,
              prefixIcon: Icons.person_outline_rounded,
              enabled: !state.isLoading,
              onFieldSubmitted: (_) {},
            ),
            const SizedBox(height: 20),

            // ── University ───────────────────────────────────────────────
            UniversitySelectorField(
              label: 'University *',
              value: state.university,
              onChanged: notifier.setUniversity,
              enabled: !state.isLoading,
            ),
            const SizedBox(height: 20),

            // ── Major ────────────────────────────────────────────────────
            MajorSelectorField(
              label: 'Major *',
              initialValue: state.major,
              onChanged: notifier.setMajor,
              enabled: !state.isLoading,
            ),
            const SizedBox(height: 20),

            // ── Academic Year ─────────────────────────────────────────────
            AcademicYearSelector(
              label: 'Academic Year *',
              value: state.academicYear,
              onChanged: notifier.setAcademicYear,
              enabled: !state.isLoading,
            ),
            const SizedBox(height: 24),

            // ── Skills ───────────────────────────────────────────────────
            SkillsInputField(
              label: 'Skills *',
              hint: 'Add at least one skill',
              skills: state.skills,
              onAdd: notifier.addSkill,
              onRemove: notifier.removeSkill,
              enabled: !state.isLoading,
            ),
            const SizedBox(height: 36),

            // ── Submit ────────────────────────────────────────────────────
            AppButton(
              label: state.isLoading ? 'Saving…' : 'Complete Profile',
              isLoading: state.isLoading,
              onPressed: state.isLoading
                  ? null
                  : () {
                      notifier.setFullName(_nameCtrl.text);
                      notifier.submit();
                    },
            ),
          ],
        ),
      ),
    );
  }
}
