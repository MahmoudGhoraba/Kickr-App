# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Get dependencies
flutter pub get

# Run the app (requires a connected device or simulator)
flutter run

# Static analysis — must pass clean before committing
flutter analyze

# Run tests
flutter test

# Run a single test file
flutter test test/widget_test.dart

# Build release APK
flutter build apk --release
```

`flutter analyze` is the lint gate. Fix all warnings before finishing any task — the project is configured with `flutter_lints` and must report "No issues found."

## Environment Setup

Copy `.env.example` to `.env` and fill in real Supabase credentials before running:

```
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

`.env` is bundled as a Flutter asset (declared in `pubspec.yaml`) and loaded at startup via `flutter_dotenv`. It is gitignored. Never hardcode credentials.

## Import Convention

All intra-package imports must use `package:kickr/` — never relative paths (`../../`). This applies to every file under `lib/`, including files in the same directory.

```dart
// correct
import 'package:kickr/core/theme/app_colors.dart';

// wrong — do not use
import '../../core/theme/app_colors.dart';
import 'app_colors.dart';
```

## Architecture

This is a **feature-based Flutter app** (Riverpod + GoRouter + Supabase). The three layers inside every feature are:

- `data/` — repository classes that call Supabase directly. No business logic, no state.
- `presentation/providers/` — Riverpod providers that own state and call repository methods.
- `presentation/screens/` — widgets that read providers via `ref.watch` / `ref.read`. Screens never call Supabase directly.

`core/` is cross-feature infrastructure (router, theme, env config). `shared/widgets/` contains UI primitives used across features.

### Auth flow data path

```
SplashScreen
  → reads authStateProvider (StreamProvider<AuthState>)
  → navigates to /onboarding or /home

LoginScreen / SignupScreen
  → calls authNotifierProvider.notifier.signIn() / signUp()
  → authNotifierProvider is StateNotifierProvider<AsyncValue<void>>
  → notifier calls AuthRepository
  → AuthRepository wraps Supabase.instance.client.auth.*

GoRouter redirect
  → _RouterNotifier (ChangeNotifier) listens to authStateProvider
  → redirect() runs on every auth state change
  → unauthenticated → /login, authenticated on auth route → /home
```

`authStateProvider` (StreamProvider) is the single source of truth for session state. Both GoRouter redirects and splash navigation read from it.

`_RouterNotifier extends ChangeNotifier` (in `app_router.dart`) is the intentional bridge between Riverpod and GoRouter's `refreshListenable`. `GoRouterRefreshStream` was removed from go_router before v6 and does not exist in v15 — do not attempt to use it.

### Adding a new feature (Stage 2+)

1. Create `lib/features/<name>/data/<name>_repository.dart` — Supabase queries only.
2. Create `lib/features/<name>/presentation/providers/<name>_providers.dart` — expose a `Provider` for the repository and a `StateNotifierProvider` or `FutureProvider` for UI state.
3. Create screens under `lib/features/<name>/presentation/screens/`.
4. Add routes to `AppRoutes` constants and the `routes` list in `app_router.dart`.
5. Update the `isAuthRoute` check in the router's `redirect` callback if the new routes need protection.

### Routing rules

All route paths are string constants on `AppRoutes` in `lib/core/router/app_router.dart`. Always use those constants — never raw strings. The `isAuthRoute` set in the `redirect` callback determines what is public vs. protected; add new routes to the right side of that check.

### Shared widgets

| Widget | Purpose |
|---|---|
| `AppButton` | Primary / outline / text variants with loading state |
| `AppTextField` | Labeled form field with password toggle and validator support |
| `AppLogo` | Brand mark in small / medium / large sizes |

All styling comes from `AppColors` and `AppTextStyles`. Never use hardcoded `Color(...)` or raw `TextStyle(...)` in screens — extend the theme files instead.

### Theme

Brand palette: primary `#1A1F5E` (deep blue), accent `#FF6B35` (orange). Typography uses Google Fonts Inter throughout. `AppTheme.light` is the only theme; dark mode is not implemented.

## Current Stage

**Stage 1 only** — auth flow and project foundation. The `/home` route is a stub (`_HomeStub` in `app_router.dart`). Stage 2 will replace it with the internship feed and add `features/internships/`, `features/profile/`, `features/applications/`, and `features/company/`.
