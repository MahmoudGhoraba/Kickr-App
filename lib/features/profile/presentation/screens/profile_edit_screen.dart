import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kickr/core/theme/app_colors.dart';
import 'package:kickr/core/theme/app_text_styles.dart';
import 'package:kickr/features/profile/data/profile_model.dart';
import 'package:kickr/features/profile/presentation/providers/profile_providers.dart';
import 'package:kickr/shared/widgets/app_button.dart';
import 'package:kickr/shared/widgets/app_text_field.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key, this.initialProfile});

  /// Passed from ProfileScreen so the form pre-fills without a second fetch.
  final Profile? initialProfile;

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _nameCtrl = TextEditingController();
  final _uniCtrl = TextEditingController();
  final _majorCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _skillCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Defer state mutation to after the first frame so it never runs during
    // an ancestor's build phase.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final profile = widget.initialProfile ??
          ref.read(currentProfileProvider).valueOrNull;
      if (profile != null) _initFromProfile(profile);
    });
  }

  void _initFromProfile(Profile profile) {
    _nameCtrl.text = profile.fullName ?? '';
    _uniCtrl.text = profile.university ?? '';
    _majorCtrl.text = profile.major ?? '';
    _bioCtrl.text = profile.bio ?? '';
    ref.read(profileEditProvider.notifier).init(profile);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _uniCtrl.dispose();
    _majorCtrl.dispose();
    _bioCtrl.dispose();
    _skillCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileEditProvider);
    final notifier = ref.read(profileEditProvider.notifier);

    ref.listen<ProfileEditState>(profileEditProvider, (_, next) {
      if (next.isSuccess && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile updated!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.of(context).pop();
      }
      if (next.error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile', style: AppTextStyles.headlineMedium),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: _AvatarPicker(
                state: state,
                onTap: notifier.pickAvatar,
              ),
            ),
            const SizedBox(height: 32),
            AppTextField(
              label: 'Full Name',
              hint: 'Ahmed Mohamed',
              controller: _nameCtrl,
              keyboardType: TextInputType.name,
              textInputAction: TextInputAction.next,
              prefixIcon: Icons.person_outline_rounded,
              enabled: !state.isLoading,
              onFieldSubmitted: (_) {},
            ),
            const SizedBox(height: 20),
            AppTextField(
              label: 'University',
              hint: 'Cairo University',
              controller: _uniCtrl,
              textInputAction: TextInputAction.next,
              prefixIcon: Icons.school_outlined,
              enabled: !state.isLoading,
              onFieldSubmitted: (_) {},
            ),
            const SizedBox(height: 20),
            AppTextField(
              label: 'Major',
              hint: 'Computer Science',
              controller: _majorCtrl,
              textInputAction: TextInputAction.next,
              prefixIcon: Icons.auto_stories_outlined,
              enabled: !state.isLoading,
              onFieldSubmitted: (_) {},
            ),
            const SizedBox(height: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bio', style: AppTextStyles.labelMedium),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _bioCtrl,
                  maxLines: 4,
                  enabled: !state.isLoading,
                  style: AppTextStyles.bodyLarge,
                  decoration: const InputDecoration(
                    hintText: 'Tell companies a little about yourself…',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Skills', style: AppTextStyles.labelMedium),
            const SizedBox(height: 10),
            if (state.skills.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: state.skills
                    .map((s) => _EditableSkillChip(
                          label: s,
                          onRemove: () => notifier.removeSkill(s),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: AppTextField(
                    label: '',
                    hint: 'e.g. Flutter',
                    controller: _skillCtrl,
                    textInputAction: TextInputAction.done,
                    enabled: !state.isLoading,
                    onFieldSubmitted: (_) {
                      notifier.setSkillInput(_skillCtrl.text);
                      notifier.addSkill();
                      _skillCtrl.clear();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 52),
                    ),
                    onPressed: state.isLoading
                        ? null
                        : () {
                            notifier.setSkillInput(_skillCtrl.text);
                            notifier.addSkill();
                            _skillCtrl.clear();
                          },
                    child: const Text('Add'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 36),
            AppButton(
              label: 'Save Changes',
              isLoading: state.isLoading,
              onPressed: state.isLoading
                  ? null
                  : () {
                      notifier.setFullName(_nameCtrl.text);
                      notifier.setUniversity(_uniCtrl.text);
                      notifier.setMajor(_majorCtrl.text);
                      notifier.setBio(_bioCtrl.text);
                      notifier.save();
                    },
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarPicker extends StatelessWidget {
  const _AvatarPicker({required this.state, required this.onTap});

  final ProfileEditState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: state.isLoading ? null : onTap,
      child: Stack(
        children: [
          _AvatarDisplay(state: state),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                size: 16,
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarDisplay extends StatelessWidget {
  const _AvatarDisplay({required this.state});

  final ProfileEditState state;

  @override
  Widget build(BuildContext context) {
    if (state.hasPickedAvatar) {
      return CircleAvatar(
        radius: 44,
        backgroundImage: MemoryImage(state.pickedAvatarBytes!),
        backgroundColor: AppColors.primaryLight,
      );
    }

    final avatarUrl = state.currentAvatarUrl;
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
      child: const Icon(
        Icons.person_outline_rounded,
        size: 40,
        color: AppColors.primary,
      ),
    );
  }
}

class _EditableSkillChip extends StatelessWidget {
  const _EditableSkillChip({required this.label, required this.onRemove});

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withAlpha(60)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              Icons.close_rounded,
              size: 14,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
