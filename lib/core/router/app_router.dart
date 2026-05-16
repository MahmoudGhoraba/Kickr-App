import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kickr/features/auth/presentation/providers/auth_providers.dart';
import 'package:kickr/features/profile/data/profile_model.dart';
import 'package:kickr/features/auth/presentation/screens/login_screen.dart';
import 'package:kickr/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:kickr/features/auth/presentation/screens/signup_screen.dart';
import 'package:kickr/features/auth/presentation/screens/splash_screen.dart';
import 'package:kickr/features/company/presentation/screens/applicant_list_screen.dart';
import 'package:kickr/features/company/presentation/screens/company_internship_form_screen.dart';
import 'package:kickr/features/internships/data/internship_model.dart';
import 'package:kickr/features/internships/presentation/screens/home_screen.dart';
import 'package:kickr/features/internships/presentation/screens/internship_detail_screen.dart';
import 'package:kickr/features/profile/presentation/screens/profile_edit_screen.dart';

// Route path constants — always use these instead of raw strings
class AppRoutes {
  AppRoutes._();

  static const splash = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const signup = '/signup';
  static const home = '/home';
  static const internshipDetail = '/internships/:id';

  // Profile
  static const profileEdit = '/profile/edit';

  // Company portal
  static const companyInternshipCreate = '/company/internships/new';
  static const companyInternshipEdit = '/company/internships/:id/edit';
  static const companyApplicants = '/company/internships/:id/applicants';

  static String internshipDetailPath(String id) => '/internships/$id';
  static String companyInternshipEditPath(String id) =>
      '/company/internships/$id/edit';
  static String companyApplicantsPath(String id) =>
      '/company/internships/$id/applicants';
}

// Bridges Riverpod state into a Listenable for GoRouter's refreshListenable
class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this._ref) {
    _ref.listen(authStateProvider, (_, _) => notifyListeners());
  }

  final Ref _ref;

  bool get isAuthenticated {
    final state = _ref.read(authStateProvider);
    return state.when(
      data: (authState) => authState.session != null,
      loading: () => false,
      error: (_, _) => false,
    );
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: notifier,
    redirect: (BuildContext context, GoRouterState state) {
      final isAuth = notifier.isAuthenticated;
      final location = state.uri.toString();

      final isAuthRoute = location == AppRoutes.login ||
          location == AppRoutes.signup ||
          location == AppRoutes.onboarding ||
          location == AppRoutes.splash;

      // Authenticated users should not linger on auth screens
      if (isAuth && isAuthRoute) return AppRoutes.home;

      // Unauthenticated users cannot access protected routes
      if (!isAuth && !isAuthRoute) return AppRoutes.login;

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, _) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, _) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, _) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        builder: (context, _) => const SignupScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, _) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.internshipDetail,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return InternshipDetailScreen(internshipId: id);
        },
      ),

      // ── Profile ────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.profileEdit,
        builder: (context, state) {
          // Profile is passed as extra so the edit form can pre-fill
          // without a second Supabase fetch.
          final profile = state.extra is Profile ? state.extra as Profile : null;
          return ProfileEditScreen(initialProfile: profile);
        },
      ),

      // ── Company portal ─────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.companyInternshipCreate,
        builder: (context, state) {
          final companyId = state.extra as String;
          return CompanyInternshipFormScreen(companyId: companyId);
        },
      ),
      GoRoute(
        path: AppRoutes.companyInternshipEdit,
        builder: (context, state) {
          final internship = state.extra as Internship;
          return CompanyInternshipFormScreen(
            companyId: internship.companyId,
            internship: internship,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.companyApplicants,
        builder: (context, state) {
          final internshipId = state.pathParameters['id']!;
          final title = state.extra as String? ?? 'Applicants';
          return ApplicantListScreen(
            internshipId: internshipId,
            internshipTitle: title,
          );
        },
      ),
    ],
  );
});
