import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kickr/core/theme/app_colors.dart';
import 'package:kickr/core/theme/app_text_styles.dart';
import 'package:kickr/features/company/presentation/providers/company_providers.dart';
import 'package:kickr/features/internships/data/company_model.dart';
import 'package:kickr/shared/widgets/app_button.dart';
import 'package:kickr/shared/widgets/app_text_field.dart';

const _companySizes = [
  '1–10',
  '11–50',
  '51–200',
  '201–500',
  '500+',
];

class CompanyProfileEditScreen extends ConsumerStatefulWidget {
  const CompanyProfileEditScreen({super.key, required this.company});

  final Company company;

  @override
  ConsumerState<CompanyProfileEditScreen> createState() =>
      _CompanyProfileEditScreenState();
}

class _CompanyProfileEditScreenState
    extends ConsumerState<CompanyProfileEditScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _industryCtrl;
  late final TextEditingController _locationCtrl;
  late final TextEditingController _websiteCtrl;
  late final TextEditingController _cultureCtrl;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _descCtrl = TextEditingController();
    _industryCtrl = TextEditingController();
    _locationCtrl = TextEditingController();
    _websiteCtrl = TextEditingController();
    _cultureCtrl = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _initFromCompany(widget.company);
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _industryCtrl.dispose();
    _locationCtrl.dispose();
    _websiteCtrl.dispose();
    _cultureCtrl.dispose();
    super.dispose();
  }

  void _initFromCompany(Company company) {
    if (_initialized) return;
    _initialized = true;
    _nameCtrl.text = company.name;
    _descCtrl.text = company.description ?? '';
    _industryCtrl.text = company.industry ?? '';
    _locationCtrl.text = company.location ?? '';
    _websiteCtrl.text = company.website ?? '';
    _cultureCtrl.text = company.cultureDescription ?? '';
    ref.read(companyEditProvider.notifier).init(company);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(companyEditProvider);
    final notifier = ref.read(companyEditProvider.notifier);

    ref.listen<CompanyEditState>(companyEditProvider, (_, next) {
      if (next.isSuccess && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Company profile updated!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title:
            Text('Edit Company Profile', style: AppTextStyles.headlineMedium),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _LogoSection(
              currentLogoUrl: state.currentLogoUrl,
              hasPickedLogo: state.hasPickedLogo,
              pickedBytes: state.pickedLogoBytes,
              isLoading: state.isLoading,
              onPick: notifier.pickLogo,
            ),
            const SizedBox(height: 24),
            AppTextField(
              label: 'Company Name *',
              hint: 'Acme Corp',
              controller: _nameCtrl,
              textInputAction: TextInputAction.next,
              prefixIcon: Icons.business_outlined,
              enabled: !state.isLoading,
              onFieldSubmitted: (_) {},
            ),
            const SizedBox(height: 20),
            AppTextField(
              label: 'Industry',
              hint: 'Technology',
              controller: _industryCtrl,
              textInputAction: TextInputAction.next,
              prefixIcon: Icons.category_outlined,
              enabled: !state.isLoading,
              onFieldSubmitted: (_) {},
            ),
            const SizedBox(height: 20),
            AppTextField(
              label: 'Location',
              hint: 'Cairo, Egypt',
              controller: _locationCtrl,
              textInputAction: TextInputAction.next,
              prefixIcon: Icons.location_on_outlined,
              enabled: !state.isLoading,
              onFieldSubmitted: (_) {},
            ),
            const SizedBox(height: 20),
            AppTextField(
              label: 'Website',
              hint: 'https://company.com',
              controller: _websiteCtrl,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.next,
              prefixIcon: Icons.link_rounded,
              enabled: !state.isLoading,
              onFieldSubmitted: (_) {},
            ),
            const SizedBox(height: 20),
            Text('Company Size', style: AppTextStyles.labelMedium),
            const SizedBox(height: 8),
            _CompanySizeSelector(
              selected: state.companySize,
              enabled: !state.isLoading,
              onChanged: notifier.setCompanySize,
            ),
            const SizedBox(height: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Description', style: AppTextStyles.labelMedium),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 4,
                  enabled: !state.isLoading,
                  style: AppTextStyles.bodyLarge,
                  decoration: const InputDecoration(
                    hintText: 'Tell students about your company…',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Culture & Values', style: AppTextStyles.labelMedium),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _cultureCtrl,
                  maxLines: 3,
                  enabled: !state.isLoading,
                  style: AppTextStyles.bodyLarge,
                  decoration: const InputDecoration(
                    hintText:
                        'What makes your workplace unique? Team culture, values, perks…',
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
                  : () => notifier.save(
                        companyId: widget.company.id,
                        name: _nameCtrl.text,
                        description: _descCtrl.text,
                        industry: _industryCtrl.text,
                        location: _locationCtrl.text,
                        website: _websiteCtrl.text,
                        cultureDescription: _cultureCtrl.text,
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoSection extends StatelessWidget {
  const _LogoSection({
    required this.currentLogoUrl,
    required this.hasPickedLogo,
    required this.pickedBytes,
    required this.isLoading,
    required this.onPick,
  });

  final String? currentLogoUrl;
  final bool hasPickedLogo;
  final Uint8List? pickedBytes;
  final bool isLoading;
  final Future<void> Function() onPick;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: isLoading ? null : onPick,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: AppColors.surfaceVariant,
                  backgroundImage: hasPickedLogo && pickedBytes != null
                      ? MemoryImage(pickedBytes!)
                      : (currentLogoUrl != null
                          ? NetworkImage(currentLogoUrl!) as ImageProvider
                          : null),
                  child: (hasPickedLogo || currentLogoUrl != null)
                      ? null
                      : const Icon(Icons.business_rounded,
                          size: 36, color: AppColors.textHint),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt_rounded,
                        size: 14, color: AppColors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasPickedLogo ? 'Logo selected' : 'Tap to upload logo',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}

class _CompanySizeSelector extends StatelessWidget {
  const _CompanySizeSelector({
    required this.selected,
    required this.enabled,
    required this.onChanged,
  });

  final String? selected;
  final bool enabled;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _companySizes
          .map((size) => _SizeChip(
                label: size,
                isSelected: selected == size,
                enabled: enabled,
                onTap: () => onChanged(selected == size ? null : size),
              ))
          .toList(),
    );
  }
}

class _SizeChip extends StatelessWidget {
  const _SizeChip({
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
