import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kickr/core/constants/role_constants.dart';
import 'package:kickr/core/theme/app_colors.dart';
import 'package:kickr/core/theme/app_text_styles.dart';
import 'package:kickr/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:kickr/features/applications/presentation/screens/applications_screen.dart';
import 'package:kickr/features/company/presentation/screens/company_dashboard_screen.dart';
import 'package:kickr/features/company/presentation/screens/company_profile_screen.dart';
import 'package:kickr/features/internships/presentation/screens/internship_feed_screen.dart';
import 'package:kickr/features/internships/presentation/screens/saved_internships_screen.dart';
import 'package:kickr/features/profile/presentation/providers/profile_providers.dart';
import 'package:kickr/features/profile/presentation/screens/profile_stub_screen.dart';
import 'package:kickr/shared/services/notifications/notification_providers.dart';
import 'package:kickr/shared/services/notifications/notification_service.dart';
import 'package:kickr/shared/services/notifications/notification_token_service.dart';
import 'package:kickr/shared/services/realtime/applications_realtime_service.dart';
import 'package:kickr/shared/services/realtime/company_realtime_service.dart';
import 'package:kickr/shared/services/realtime/internships_realtime_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  bool _notificationsInitialized = false;

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentProfileProvider);

    // ── Realtime subscriptions — active for the lifetime of HomeScreen ───────
    // Each provider is a no-op when it doesn't apply (wrong role / no userId).
    ref.watch(internshipsRealtimeProvider);
    ref.watch(applicationsRealtimeProvider);
    ref.watch(companyApplicationsRealtimeProvider);

    // ── FCM foreground banner ─────────────────────────────────────────────────
    ref.listen(fcmForegroundProvider, (_, next) {
      final message = next.valueOrNull;
      if (message == null || !mounted) return;
      final title = message.notification?.title ?? 'Kickr';
      final body = message.notification?.body ?? '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.labelMedium
                    .copyWith(color: AppColors.white),
              ),
              if (body.isNotEmpty)
                Text(
                  body,
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.white),
                ),
            ],
          ),
          backgroundColor: AppColors.accent,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    });

    // ── Notifications init — once profile resolves ────────────────────────────
    ref.listen(currentProfileProvider, (_, next) {
      final userId = next.valueOrNull?.id;
      if (userId != null && !_notificationsInitialized) {
        _notificationsInitialized = true;
        _initNotifications(userId);
      }
    });

    return profileAsync.when(
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      // On profile fetch error, fall back to student layout so the app
      // remains usable even if the profiles table isn't migrated yet.
      error: (_, _) => _buildStudentHome(),
      data: (profile) {
        final role = profile?.effectiveRole ?? UserRole.student;
        return switch (role) {
          UserRole.company => _buildCompanyHome(),
          UserRole.admin => _buildAdminHome(),
          _ => _buildStudentHome(),
        };
      },
    );
  }

  Future<void> _initNotifications(String userId) async {
    final tokenService =
        NotificationTokenService(Supabase.instance.client);
    final service = NotificationService(tokenService);
    await service.init(userId);
  }

  Widget _buildStudentHome() {
    const tabs = [
      InternshipFeedScreen(),
      SavedInternshipsScreen(),
      ApplicationsScreen(),
      ProfileScreen(),
    ];

    if (_currentIndex >= tabs.length) _currentIndex = 0;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: tabs,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primaryLight,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_outline_rounded),
            selectedIcon: Icon(Icons.bookmark_rounded),
            label: 'Saved',
          ),
          NavigationDestination(
            icon: Icon(Icons.description_outlined),
            selectedIcon: Icon(Icons.description_rounded),
            label: 'Applications',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildAdminHome() {
    const tabs = [
      AdminDashboardScreen(),
      ProfileScreen(),
    ];

    if (_currentIndex >= tabs.length) _currentIndex = 0;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: tabs,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primaryLight,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.verified_user_outlined),
            selectedIcon: Icon(Icons.verified_user_rounded),
            label: 'Verifications',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyHome() {
    const tabs = [
      CompanyDashboardScreen(),
      CompanyProfileScreen(),
    ];

    if (_currentIndex >= tabs.length) _currentIndex = 0;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: tabs,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primaryLight,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
