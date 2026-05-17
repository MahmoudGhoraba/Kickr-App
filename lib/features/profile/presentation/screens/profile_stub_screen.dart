import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kickr/core/router/app_router.dart';
import 'package:kickr/core/theme/app_colors.dart';
import 'package:kickr/core/theme/app_text_styles.dart';
import 'package:kickr/features/auth/presentation/providers/auth_providers.dart';
import 'package:kickr/features/profile/data/profile_model.dart';
import 'package:kickr/features/profile/presentation/providers/profile_providers.dart';
import 'package:kickr/shared/widgets/app_button.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);
    final email = ref.watch(authStateProvider).valueOrNull?.session?.user.email ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile', style: AppTextStyles.headlineMedium),
        automaticallyImplyLeading: false,
        actions: [
          TextButton.icon(
            onPressed: () =>
                ref.read(authNotifierProvider.notifier).signOut(),
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: const Text('Sign Out'),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (_, _) => _ProfileErrorState(
          onRetry: () => ref.invalidate(currentProfileProvider),
        ),
        data: (profile) => _ProfileBody(profile: profile, email: email),
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({required this.profile, required this.email});

  final Profile? profile;
  final String email;

  @override
  Widget build(BuildContext context) {
    final fullName = profile?.fullName ?? 'User';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _AvatarWidget(profile: profile),
          const SizedBox(height: 16),
          Text(fullName, style: AppTextStyles.headlineLarge),
          if (email.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(email, style: AppTextStyles.bodyMedium),
          ],
          if (profile?.university != null || profile?.major != null) ...[
            const SizedBox(height: 4),
            Text(
              [
                if (profile?.major != null) profile!.major!,
                if (profile?.university != null) profile!.university!,
              ].join(' · '),
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: AppButton(
              label: 'Edit Profile',
              onPressed: () => context.push(
                AppRoutes.profileEdit,
                extra: profile,
              ),
              variant: AppButtonVariant.outline,
              icon: const Icon(Icons.edit_outlined, size: 18),
            ),
          ),
          if (profile?.bio != null && profile!.bio!.isNotEmpty) ...[
            const SizedBox(height: 20),
            _SectionCard(
              title: 'About',
              child: Text(profile!.bio!, style: AppTextStyles.bodyLarge),
            ),
          ],
          if (profile?.skills.isNotEmpty ?? false) ...[
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Skills',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: profile!.skills
                    .map((s) => _SkillChip(label: s))
                    .toList(),
              ),
            ),
          ],
          if (profile?.cvUrl != null) ...[
            const SizedBox(height: 16),
            _SectionCard(
              title: 'CV',
              child: Row(
                children: [
                  const Icon(
                    Icons.picture_as_pdf_outlined,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'CV on file',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProfileErrorState extends StatelessWidget {
  const _ProfileErrorState({required this.onRetry});

  final VoidCallback onRetry;

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
                    Icons.person_off_outlined,
                    size: 48,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Could not load profile',
                    style: AppTextStyles.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Check your connection and try again.',
                    style: AppTextStyles.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
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

class _AvatarWidget extends StatelessWidget {
  const _AvatarWidget({required this.profile});

  final Profile? profile;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = profile?.avatarUrl;
    final fullName = profile?.fullName ?? 'U';

    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 44,
        backgroundImage: NetworkImage(avatarUrl),
        backgroundColor: AppColors.primaryLight,
      );
    }

    return Container(
      width: 88,
      height: 88,
      decoration: const BoxDecoration(
        color: AppColors.primaryLight,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          _initials(fullName),
          style: AppTextStyles.displayMedium.copyWith(
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
    return name.isEmpty ? 'U' : name[0].toUpperCase();
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.labelMedium),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _SkillChip extends StatelessWidget {
  const _SkillChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withAlpha(60)),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
