import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kickr/core/theme/app_colors.dart';
import 'package:kickr/core/theme/app_text_styles.dart';
import 'package:kickr/features/company/presentation/providers/company_providers.dart';
import 'package:kickr/features/internships/data/internship_model.dart';
import 'package:kickr/shared/widgets/app_button.dart';
import 'package:kickr/shared/widgets/app_text_field.dart';

/// Create mode: [internship] is null, [companyId] is required.
/// Edit mode:   [internship] is the existing record, [companyId] is ignored
///              (read from internship.companyId).
class CompanyInternshipFormScreen extends ConsumerStatefulWidget {
  const CompanyInternshipFormScreen({
    super.key,
    required this.companyId,
    this.internship,
  });

  final String companyId;
  final Internship? internship;

  @override
  ConsumerState<CompanyInternshipFormScreen> createState() =>
      _CompanyInternshipFormScreenState();
}

class _CompanyInternshipFormScreenState
    extends ConsumerState<CompanyInternshipFormScreen> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _shortDescCtrl;
  late final TextEditingController _locationCtrl;
  late final TextEditingController _categoryCtrl;
  late final TextEditingController _skillCtrl;
  bool _initialized = false;

  bool get _isEditMode => widget.internship != null;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController();
    _descCtrl = TextEditingController();
    _shortDescCtrl = TextEditingController();
    _locationCtrl = TextEditingController();
    _categoryCtrl = TextEditingController();
    _skillCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _shortDescCtrl.dispose();
    _locationCtrl.dispose();
    _categoryCtrl.dispose();
    _skillCtrl.dispose();
    super.dispose();
  }

  void _initFromInternship(Internship internship) {
    if (_initialized) return;
    _initialized = true;
    _titleCtrl.text = internship.title;
    _descCtrl.text = internship.description;
    _shortDescCtrl.text = internship.shortDescription ?? '';
    _locationCtrl.text = internship.location;
    _categoryCtrl.text = internship.category ?? '';
    ref.read(internshipFormProvider.notifier).init(internship);
  }

  @override
  Widget build(BuildContext context) {
    if (_isEditMode && !_initialized) {
      _initFromInternship(widget.internship!);
    }

    final state = ref.watch(internshipFormProvider);
    final notifier = ref.read(internshipFormProvider.notifier);

    ref.listen<InternshipFormState>(internshipFormProvider, (_, next) {
      if (next.isSuccess && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode
                ? 'Internship updated!'
                : 'Internship posted!'),
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
        title: Text(
          _isEditMode ? 'Edit Internship' : 'Post Internship',
          style: AppTextStyles.headlineMedium,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextField(
              label: 'Title *',
              hint: 'Flutter Developer Intern',
              controller: _titleCtrl,
              textInputAction: TextInputAction.next,
              prefixIcon: Icons.work_outline_rounded,
              enabled: !state.isLoading,
              onFieldSubmitted: (_) {},
            ),
            const SizedBox(height: 20),
            AppTextField(
              label: 'Location *',
              hint: 'Cairo, Egypt',
              controller: _locationCtrl,
              textInputAction: TextInputAction.next,
              prefixIcon: Icons.location_on_outlined,
              enabled: !state.isLoading,
              onFieldSubmitted: (_) {},
            ),
            const SizedBox(height: 20),
            Text('Type *', style: AppTextStyles.labelMedium),
            const SizedBox(height: 10),
            _TypeSelector(
              selected: state.type,
              enabled: !state.isLoading,
              onChanged: notifier.setType,
            ),
            const SizedBox(height: 20),
            AppTextField(
              label: 'Category',
              hint: 'Engineering, Design, Marketing…',
              controller: _categoryCtrl,
              textInputAction: TextInputAction.next,
              prefixIcon: Icons.category_outlined,
              enabled: !state.isLoading,
              onFieldSubmitted: (_) {},
            ),
            const SizedBox(height: 20),
            AppTextField(
              label: 'Short Description',
              hint: 'One-line summary shown in the feed',
              controller: _shortDescCtrl,
              textInputAction: TextInputAction.next,
              enabled: !state.isLoading,
              onFieldSubmitted: (_) {},
            ),
            const SizedBox(height: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Description *', style: AppTextStyles.labelMedium),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 6,
                  enabled: !state.isLoading,
                  style: AppTextStyles.bodyLarge,
                  decoration: const InputDecoration(
                    hintText: 'Describe the role, responsibilities, and requirements…',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Required Skills', style: AppTextStyles.labelMedium),
            const SizedBox(height: 10),
            if (state.skills.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: state.skills
                    .map((s) => _EditableChip(
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
                    onFieldSubmitted: (_) => _addSkill(notifier),
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: OutlinedButton(
                    onPressed: state.isLoading ? null : () => _addSkill(notifier),
                    child: const Text('Add'),
                  ),
                ),
              ],
            ),
            if (_isEditMode) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  Text('Active listing', style: AppTextStyles.labelMedium),
                  const Spacer(),
                  Switch(
                    value: state.isActive,
                    onChanged:
                        state.isLoading ? null : notifier.setIsActive,
                    activeThumbColor: AppColors.primary,
                  ),
                ],
              ),
            ],
            const SizedBox(height: 36),
            AppButton(
              label: _isEditMode ? 'Save Changes' : 'Post Internship',
              isLoading: state.isLoading,
              onPressed: state.isLoading
                  ? null
                  : () {
                      notifier.setTitle(_titleCtrl.text);
                      notifier.setDescription(_descCtrl.text);
                      notifier.setShortDescription(_shortDescCtrl.text);
                      notifier.setLocation(_locationCtrl.text);
                      notifier.setCategory(_categoryCtrl.text);
                      notifier.submit(
                        companyId: widget.internship?.companyId ?? widget.companyId,
                        internshipId: widget.internship?.id,
                      );
                    },
            ),
          ],
        ),
      ),
    );
  }

  void _addSkill(InternshipFormNotifier notifier) {
    notifier.setSkillInput(_skillCtrl.text);
    notifier.addSkill();
    _skillCtrl.clear();
  }
}

class _TypeSelector extends StatelessWidget {
  const _TypeSelector({
    required this.selected,
    required this.onChanged,
    required this.enabled,
  });

  final InternshipType selected;
  final ValueChanged<InternshipType> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: InternshipType.values
          .map((type) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: type != InternshipType.values.last ? 8 : 0,
                  ),
                  child: _TypeChip(
                    label: type.label,
                    isSelected: selected == type,
                    enabled: enabled,
                    onTap: () => onChanged(type),
                  ),
                ),
              ))
          .toList(),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.isSelected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.labelMedium.copyWith(
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _EditableChip extends StatelessWidget {
  const _EditableChip({required this.label, required this.onRemove});

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
