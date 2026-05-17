import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kickr/core/theme/app_colors.dart';
import 'package:kickr/core/theme/app_text_styles.dart';
import 'package:kickr/features/auth/presentation/providers/auth_providers.dart';
import 'package:kickr/features/company/presentation/providers/company_providers.dart';
import 'package:kickr/features/company/presentation/screens/company_profile_edit_screen.dart';
import 'package:kickr/features/internships/data/company_model.dart';
import 'package:kickr/shared/widgets/app_button.dart';

class CompanyProfileScreen extends ConsumerWidget {
  const CompanyProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companyAsync = ref.watch(currentCompanyProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Company Profile', style: AppTextStyles.headlineMedium),
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
      body: companyAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (_, _) => _ErrorState(
          onRetry: () => ref.invalidate(currentCompanyProvider),
        ),
        data: (company) => company == null
            ? _NoCompanyState(
                onRetry: () => ref.invalidate(currentCompanyProvider),
              )
            : _CompanyBody(company: company),
      ),
    );
  }
}

class _CompanyBody extends StatelessWidget {
  const _CompanyBody({required this.company});

  final Company company;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _LogoWidget(logoUrl: company.logoUrl, name: company.name),
          const SizedBox(height: 16),
          Text(company.name, style: AppTextStyles.headlineLarge),
          if (company.industry != null) ...[
            const SizedBox(height: 4),
            Text(company.industry!, style: AppTextStyles.bodyMedium),
          ],
          if (company.location != null || company.companySize != null) ...[
            const SizedBox(height: 4),
            Text(
              [
                if (company.location != null) company.location!,
                if (company.companySize != null) company.companySize!,
              ].join(' · '),
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: AppButton(
              label: 'Edit Company Profile',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => CompanyProfileEditScreen(company: company),
                ),
              ),
              variant: AppButtonVariant.outline,
              icon: const Icon(Icons.edit_outlined, size: 18),
            ),
          ),
          if (company.website != null && company.website!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _InfoCard(
              icon: Icons.link_rounded,
              label: 'Website',
              value: company.website!,
            ),
          ],
          if (company.description != null &&
              company.description!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionCard(
              title: 'About',
              child: Text(company.description!,
                  style: AppTextStyles.bodyLarge),
            ),
          ],
          if (company.cultureDescription != null &&
              company.cultureDescription!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Culture & Values',
              child: Text(company.cultureDescription!,
                  style: AppTextStyles.bodyLarge),
            ),
          ],
        ],
      ),
    );
  }
}

class _LogoWidget extends StatelessWidget {
  const _LogoWidget({required this.logoUrl, required this.name});

  final String? logoUrl;
  final String name;

  @override
  Widget build(BuildContext context) {
    if (logoUrl != null && logoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 44,
        backgroundImage: NetworkImage(logoUrl!),
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
      child: const Center(
        child: Icon(
          Icons.business_rounded,
          size: 40,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

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
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(value,
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.primary)),
              ],
            ),
          ),
        ],
      ),
    );
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

class _NoCompanyState extends StatelessWidget {
  const _NoCompanyState({required this.onRetry});

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
                  const Icon(Icons.business_outlined,
                      size: 48, color: AppColors.textHint),
                  const SizedBox(height: 16),
                  Text('No company profile found',
                      style: AppTextStyles.headlineMedium),
                  const SizedBox(height: 8),
                  Text(
                    'Your company profile could not be loaded.',
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

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

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
                  const Icon(Icons.wifi_off_rounded,
                      size: 48, color: AppColors.textHint),
                  const SizedBox(height: 16),
                  Text('Could not load company profile',
                      style: AppTextStyles.headlineMedium),
                  const SizedBox(height: 8),
                  Text('Check your connection and try again.',
                      style: AppTextStyles.bodyMedium,
                      textAlign: TextAlign.center),
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
