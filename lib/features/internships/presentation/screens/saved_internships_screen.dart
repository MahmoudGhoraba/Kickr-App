import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kickr/core/router/app_router.dart';
import 'package:kickr/core/theme/app_colors.dart';
import 'package:kickr/core/theme/app_text_styles.dart';
import 'package:kickr/features/internships/presentation/providers/internship_providers.dart';
import 'package:kickr/features/internships/presentation/widgets/internship_card.dart';

class SavedInternshipsScreen extends ConsumerWidget {
  const SavedInternshipsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedAsync = ref.watch(savedInternshipListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Saved', style: AppTextStyles.headlineMedium),
        automaticallyImplyLeading: false,
      ),
      body: savedAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (_, _) => const _EmptyView(isError: true),
        data: (list) => list.isEmpty
            ? const _EmptyView(isError: false)
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = list[index];
                  return InternshipCard(
                    internship: item,
                    onTap: () => context.push(
                      AppRoutes.internshipDetailPath(item.id),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.isError});

  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.bookmark_outline_rounded,
              size: 56,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 16),
            Text(
              isError ? 'Something went wrong' : 'No saved internships',
              style: AppTextStyles.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              isError
                  ? 'Could not load your saved internships.'
                  : 'Tap the bookmark on any internship to save it for later.',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
