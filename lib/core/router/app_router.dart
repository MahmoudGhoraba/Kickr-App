import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kickr/features/auth/presentation/providers/auth_providers.dart';
import 'package:kickr/features/auth/presentation/screens/login_screen.dart';
import 'package:kickr/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:kickr/features/auth/presentation/screens/signup_screen.dart';
import 'package:kickr/features/auth/presentation/screens/splash_screen.dart';

// Route name constants — use these instead of raw strings everywhere
class AppRoutes {
  AppRoutes._();
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const signup = '/signup';
  static const home = '/home';
}

// Bridges Riverpod state into a Listenable for GoRouter's refreshListenable
class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this._ref) {
    _ref.listen(authStateProvider, (_, next) => notifyListeners());
  }

  final Ref _ref;

  bool get isAuthenticated {
    final state = _ref.read(authStateProvider);
    return state.when(
      data: (authState) => authState.session != null,
      loading: () => false,
      error: (err, stack) => false,
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
      // Home is a placeholder — replaced by real home in Stage 2
      GoRoute(
        path: AppRoutes.home,
        builder: (context, _) => const _HomeStub(),
      ),
    ],
  );
});

class _HomeStub extends ConsumerWidget {
  const _HomeStub();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome to Kickr!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Home screen coming in Stage 2'),
            const SizedBox(height: 32),
            TextButton(
              onPressed: () => ref.read(authNotifierProvider.notifier).signOut(),
              child: const Text('Sign Out'),
            ),
          ],
        ),
      ),
    );
  }
}
