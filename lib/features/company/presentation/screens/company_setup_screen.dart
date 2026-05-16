import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kickr/core/theme/app_colors.dart';
import 'package:kickr/core/theme/app_text_styles.dart';
import 'package:kickr/features/company/presentation/providers/company_providers.dart';
import 'package:kickr/shared/widgets/app_button.dart';
import 'package:kickr/shared/widgets/app_text_field.dart';

class CompanySetupScreen extends ConsumerStatefulWidget {
  const CompanySetupScreen({super.key});

  @override
  ConsumerState<CompanySetupScreen> createState() => _CompanySetupScreenState();
}

class _CompanySetupScreenState extends ConsumerState<CompanySetupScreen> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _industryCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _industryCtrl.dispose();
    _locationCtrl.dispose();
    _websiteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(companySetupProvider);
    final notifier = ref.read(companySetupProvider.notifier);

    ref.listen<CompanySetupState>(companySetupProvider, (_, next) {
      if (next.isSuccess && mounted) {
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
        title: Text('Set Up Company', style: AppTextStyles.headlineMedium),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withAlpha(50)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.business_rounded, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Create your company profile to start posting internships.',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
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
            const SizedBox(height: 36),
            AppButton(
              label: 'Create Company Profile',
              isLoading: state.isLoading,
              onPressed: state.isLoading
                  ? null
                  : () => notifier.create(
                        name: _nameCtrl.text,
                        description: _descCtrl.text,
                        industry: _industryCtrl.text,
                        location: _locationCtrl.text,
                        website: _websiteCtrl.text,
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
