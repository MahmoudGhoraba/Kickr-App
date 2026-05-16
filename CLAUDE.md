# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Key Dependencies

| Package | Version | Purpose |
|---|---|---|
| `flutter_riverpod` | ^2.6.1 | State management |
| `go_router` | ^15.1.2 | Navigation (no `GoRouterRefreshStream` — removed pre-v6) |
| `supabase_flutter` | ^2.9.1 | Backend / auth / storage |
| `file_picker` | ^8.1.4 | PDF file selection for CV upload |
| `url_launcher` | ^6.3.1 | Open CV PDF URLs in system browser (company applicant view) |
| `flutter_dotenv` | ^5.2.1 | `.env` loading |
| `google_fonts` | ^6.2.1 | Inter typography |

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

`flutter analyze` is the lint gate. Fix all warnings before finishing any task — the project uses `flutter_lints` and must report "No issues found."

The app is **portrait-only** (`portraitUp` + `portraitDown` in `main.dart`). Do not add landscape layout handling.

## Environment Setup

Copy `.env.example` to `.env` and fill in real Supabase credentials before running:

```
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

`.env` is bundled as a Flutter asset (declared in `pubspec.yaml`) and loaded at startup via `flutter_dotenv`. It is gitignored. Static images go in `assets/images/` (also declared in `pubspec.yaml`).

`Env.supabaseUrl` and `Env.supabaseAnonKey` in `lib/core/config/env.dart` throw `StateError` at startup if either key is empty or missing — misconfiguration is a hard crash, not a silent auth failure.

## Import Convention

All intra-package imports must use `package:kickr/` — never relative paths (`../../`). This applies to every file under `lib/`, including files in the same directory.

```dart
// correct
import 'package:kickr/core/theme/app_colors.dart';

// wrong — do not use
import '../../core/theme/app_colors.dart';
import 'app_colors.dart';
```

The `analysis_options.yaml` enforces `always_use_package_imports: true`.

## Architecture

Feature-based Flutter app (Riverpod + GoRouter + Supabase). Three layers inside every feature:

- `data/` — repository classes that issue Supabase queries. No business logic, no state.
- `presentation/providers/` — Riverpod providers that own state and call repository methods.
- `presentation/screens/` — widgets that read providers via `ref.watch` / `ref.read`. Never call Supabase directly from a screen.

`core/` is cross-feature infrastructure (router, theme, env config, constants). `shared/` contains UI primitives (`widgets/`) and non-UI services (`services/`) used across features.

**`core/constants/` — centralised constants (do not use raw strings in repositories or services):**

| File | Contents |
|---|---|
| `app_constants.dart` | `emailRedirectUri`, `cvMaxBytes`, `avatarMaxBytes` |
| `storage_constants.dart` | `cvBucket`, `cvPath(userId)`, `avatarBucket`, `avatarPath(userId, ext)` |
| `database_constants.dart` | All Supabase table names (`profiles`, `companies`, `internships`, `saved_internships`, `applications`) |
| `role_constants.dart` | `UserRole` enum: `student`, `company`, `admin` |

### Auth flow

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

`authStateProvider` (StreamProvider) is the single source of truth for session state.

`_RouterNotifier extends ChangeNotifier` (in `app_router.dart`) is the intentional bridge between Riverpod and GoRouter's `refreshListenable`. `GoRouterRefreshStream` was removed from go_router before v6 and does not exist in v15 — do not attempt to use it.

**Supabase `signUp` deep link:** always pass `emailRedirectTo: AppConstants.emailRedirectUri` (`'kickr://login-callback'`) to `_supabase.auth.signUp(...)`. Without it, Supabase's confirmation email links to the dashboard `Site URL` (a web address); iOS intercepts the click in Safari, the session token is consumed there, and the user is never redirected back into the app. The `kickr://` scheme is registered in `ios/Runner/Info.plist`.

**Supabase error extraction:** `auth.*` methods throw `AuthException`, not a plain `Exception`. Extract the message with `e is AuthException ? e.message : e.toString()` — calling `e.toString()` directly on an `AuthException` returns the full class representation (`AuthException(message: ..., statusCode: ...)`) not just the message text, and will break any `contains()`-based error mapping. Always `debugPrint` the raw exception and stack trace before presenting a user-facing message.

**Clearing auth error state:** call `authNotifierProvider.notifier.clearError()` to reset back to `AsyncValue.data(null)` after the user dismisses an error — otherwise the error state persists across navigations.

**`SliverFillRemaining` state widgets — overflow pattern:** Any widget placed inside `SliverFillRemaining` (loading, error, empty states) must use `LayoutBuilder` → `SingleChildScrollView` → `ConstrainedBox(minHeight: constraints.maxHeight)` → `Center` → `Column(mainAxisSize: MainAxisSize.min)`. A plain `Column(mainAxisAlignment: center)` overflows when the sliver's remaining height is shorter than the content (e.g., large keyboard, small device, or a tall header consuming most of the screen).

**Supabase RLS — `FOR ALL USING` blocks trigger INSERTs:** A policy written as `FOR ALL USING (auth.uid() = id)` silently uses the `USING` expression as the `WITH CHECK` for INSERT. During the `handle_new_user()` trigger, `auth.uid()` returns NULL (no session yet), so the INSERT is rejected. **Always write split policies for tables that have both trigger-driven INSERTs and user-driven reads/updates:**

```sql
-- correct split pattern
DROP POLICY IF EXISTS "Users manage own profile" ON profiles; -- drop any existing FOR ALL policy first
CREATE POLICY "Users read own profile"   ON profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users update own profile" ON profiles FOR UPDATE USING (auth.uid() = id);
-- no INSERT policy — handle_new_user() runs as SECURITY DEFINER and bypasses RLS
```

**`CREATE POLICY IF NOT EXISTS` is PostgreSQL 17+ only.** Supabase runs PG 15/16 — this syntax will error. Use `DROP POLICY IF EXISTS` followed by `CREATE POLICY` instead.

**`profiles.role` must be `TEXT`, not an enum type.** If the column is created as a user-defined enum (`USER-DEFINED` in `information_schema.columns`), the trigger's text literal `'student'` will fail to cast and produce `"Database error saving new user"`. Always use `TEXT NOT NULL DEFAULT 'student' CHECK (role IN ('student', 'company', 'admin'))`. If you find an enum column, fix it with `ALTER TABLE profiles DROP COLUMN role` then re-add as TEXT.

**Diagnosing `"Database error saving new user"` (status 500):** This error always means the `handle_new_user()` trigger threw an exception. Disabling RLS does not fix it — check the trigger itself. Run these diagnostics in the Supabase SQL Editor:
```sql
-- Check column types (role should be "text", not "USER-DEFINED")
SELECT column_name, data_type, is_nullable FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'profiles' ORDER BY ordinal_position;
-- Check trigger body
SELECT prosrc FROM pg_proc WHERE proname = 'handle_new_user';
```
Then check Supabase Dashboard → Logs → Postgres for the exact PostgreSQL error message.

### Role system

All app signups default to `'student'`. Company role elevation is done manually in the Supabase dashboard — no in-app role selection exists. `HomeScreen` reads `currentProfileProvider` on every session start and renders the correct tab set without any app change needed when a backend role is updated.

The `handle_new_user()` trigger uses `COALESCE(NEW.raw_user_meta_data->>'role', 'student')`, so the absence of a `role` key in signup metadata correctly defaults new rows to `'student'`.

### Internships / Home feature flow

```
HomeScreen (role-based IndexedStack + NavigationBar)
  → watches currentProfileProvider → profile.effectiveRole
  → student role → 4-tab layout
  → company role → 2-tab layout

  Student Tab 0: InternshipFeedScreen
    → reads filteredInternshipsProvider (derived from internshipsProvider + internshipFilterProvider)
    → pull-to-refresh calls internshipsProvider.notifier.fetch()
    → AppSearchBar updates internshipFilterProvider.notifier.setQuery()
    → InternshipFilterBar updates internshipFilterProvider.notifier.toggleType()
    → each InternshipCard navigates to /internships/:id via context.push()

  Student Tab 1: SavedInternshipsScreen
    → reads savedInternshipListProvider (derived — cross-refs internshipsProvider + savedInternshipIdsProvider)

  Student Tab 2: ApplicationsScreen
    → reads applicationsProvider
    → tapping a card navigates to /internships/:id

  Student/Company Tab (last): ProfileScreen
    → reads currentProfileProvider, authStateProvider
    → Edit Profile button: context.push(AppRoutes.profileEdit, extra: profile)

  Company Tab 0: CompanyDashboardScreen
    → reads currentCompanyProvider (FutureProvider<Company?>)
    → no company → _NoCompanyState → push CompanySetupScreen via MaterialPageRoute
    → has company → reads companyInternshipsProvider (StateNotifier)
    → CompanyInternshipCard: edit pushes CompanyInternshipFormScreen; applicants button
      pushes ApplicantListScreen; archive calls notifier.archiveInternship()
    → FAB pushes CompanyInternshipFormScreen (create mode, extra: companyId)

InternshipDetailScreen (pushed on top of /home)
  → reads internshipDetailProvider(id) — FutureProvider.family
  → save toggle hits savedInternshipIdsProvider.notifier.toggle() — optimistic update
  → _ApplyBar (bottomNavigationBar slot) reads hasAppliedProvider(id) — derived, no query
    → shows "Apply Now" button or green "Applied" chip
    → "Apply Now" opens ApplyBottomSheet via showModalBottomSheet
```

**Optimistic save toggle:** `SavedInternshipsNotifier` snapshots the current `Set<String>`, applies the toggle immediately, awaits the Supabase call, and rolls back to the snapshot on failure.

**Derived providers avoid extra queries:** `filteredInternshipsProvider` filters the in-memory list. `savedInternshipListProvider` cross-references `internshipsProvider` with the saved ID set — no second Supabase call for the Saved tab. `hasAppliedProvider` derives from the in-memory `applicationsProvider` list — no per-screen query.

**IndexedStack eagerness:** all four tab screens are created when `HomeScreen` builds. This means `applicationsProvider` starts fetching before the user can navigate to a detail screen, so `hasAppliedProvider` is populated by the time the Apply bar is visible.

### Applications feature flow

```
ApplyBottomSheet (shown from InternshipDetailScreen._ApplyBar)
  → reads applyNotifierProvider (autoDispose StateNotifierProvider)
  → reads userCvUrlProvider (FutureProvider — saved CV from profiles.cv_url)
  → if saved CV exists: shows "Using your saved CV" card + "Change" option
  → if no saved CV: shows "Select PDF" upload button
  → on submit: ApplyNotifier.submit(internshipId, existingCvUrl?)
      1. StorageService.uploadCv()          (only if new file picked)
      2. ApplicationRepository.updateUserCvUrl()   (only if new file uploaded)
      3. ApplicationRepository.submitApplication()
      4. onSuccess callback:
           applicationsProvider.notifier.addApplication(app)  ← optimistic insert
           ref.invalidate(userCvUrlProvider)                   ← refresh saved CV
  → success state shown in sheet; user taps Done to close

ApplicationsScreen (Tab 2)
  → reads applicationsProvider — StateNotifierProvider list
  → pull-to-refresh calls applicationsProvider.notifier.fetch()
  → each ApplicationCard navigates to /internships/:id via context.push()
```

**`applyNotifierProvider` is autoDispose:** a fresh `ApplyState` is created every time the bottom sheet opens and disposed when it closes. No stale state bleeds across apply attempts.

**Duplicate prevention:** `hasAppliedProvider` hides the Apply button in the UI. The `UNIQUE (user_id, internship_id)` constraint on the `applications` table is the authoritative guard — if the UI check misses (e.g. list still loading), the DB returns `PostgrestException` with code `23505`, which `ApplyNotifier._extractError()` maps to a readable message.

**`onSuccess` callback pattern:** `ApplyNotifier` receives side-effect callbacks at construction (`onSuccess`) rather than storing a `Ref`. This avoids lifecycle bugs where an autoDispose notifier holds a ref after disposal.

### Provider structure

```
── Auth ─────────────────────────────────────────────────────────────────
authRepositoryProvider              Provider<AuthRepository>
authStateProvider                   StreamProvider<AuthState>                 ← GoRouter source of truth
authNotifierProvider                StateNotifierProvider<AuthNotifier, AsyncValue<void>>

── Profile ──────────────────────────────────────────────────────────────
profileRepositoryProvider           Provider<ProfileRepository>
currentProfileProvider              FutureProvider<Profile?>                  ← role-based home source of truth
profileEditProvider                 StateNotifierProvider.autoDispose<ProfileEditNotifier, ProfileEditState>

── Internships ──────────────────────────────────────────────────────────
internshipRepositoryProvider        Provider<InternshipRepository>
internshipsProvider                 StateNotifierProvider<InternshipsNotifier, AsyncValue<List<Internship>>>
internshipFilterProvider            StateNotifierProvider<InternshipFilterNotifier, InternshipFilter>
filteredInternshipsProvider         Provider<AsyncValue<List<Internship>>>    ← derived
savedInternshipIdsProvider          StateNotifierProvider<SavedInternshipsNotifier, AsyncValue<Set<String>>>
savedInternshipListProvider         Provider<AsyncValue<List<Internship>>>    ← derived
internshipDetailProvider            FutureProvider.family<Internship, String>

── Applications ─────────────────────────────────────────────────────────
applicationRepositoryProvider       Provider<ApplicationRepository>
storageServiceProvider              Provider<StorageService>
applicationsProvider                StateNotifierProvider<ApplicationsNotifier, AsyncValue<List<Application>>>
userCvUrlProvider                   FutureProvider<String?>                   ← profiles.cv_url
hasAppliedProvider                  Provider.family<bool, String>             ← derived
applyNotifierProvider               StateNotifierProvider.autoDispose<ApplyNotifier, ApplyState>

── Company ──────────────────────────────────────────────────────────────
companyRepositoryProvider           Provider<CompanyRepository>
currentCompanyProvider              FutureProvider<Company?>                  ← keyed on owner_id
companyInternshipsProvider          StateNotifierProvider<CompanyInternshipsNotifier, AsyncValue<List<Internship>>>
applicantsProvider                  StateNotifierProvider.autoDispose.family<ApplicantsNotifier, AsyncValue<List<ApplicantEntry>>, String>
companySetupProvider                StateNotifierProvider.autoDispose<CompanySetupNotifier, AsyncValue<void>>
internshipFormProvider              StateNotifierProvider.autoDispose<InternshipFormNotifier, AsyncValue<void>>
```

### Storage service

`StorageService` in `shared/services/storage_service.dart` centralises all Supabase Storage operations:

- `pickCvFile()` — `FileType.custom` (PDF only), validates ≤ 5 MB, returns `CvPickResult?`
- `uploadCv(userId, bytes)` — upserts to `StorageConstants.cvPath(userId)`, returns public URL
- `pickAvatarFile()` — `FileType.image`, validates ≤ 2 MB, returns `AvatarPickResult?`
- `uploadAvatar({userId, bytes, extension})` — upserts to `StorageConstants.avatarPath(userId, ext)`, returns public URL

Always go through `StorageService` — never call `Supabase.instance.client.storage` directly from a widget or provider. Bucket names and path formats are owned by `StorageConstants`; never hardcode `'cv-files'` or `'avatars'` inline.

### Profiles table

`public.profiles` already exists (see `database.md`). Schema:

```
id UUID PK → auth.users(id)   full_name TEXT   university TEXT
major TEXT   bio TEXT          skills TEXT[]    cv_url TEXT
avatar_url TEXT                created_at TIMESTAMPTZ
```

`handle_new_user()` trigger auto-inserts a row on signup. Use `UPDATE` (never `INSERT`) from the app. `ApplicationRepository.updateUserCvUrl()` and `fetchUserCvUrl()` are the only profile operations in Stage 3.

A typed `Profile` model lives at `features/profile/data/profile_model.dart` — use `Profile.fromJson()` for all profile reads and `toUpdateJson()` for UPDATE calls. The `effectiveRole` getter returns `UserRole.student` as a safe default when `role` is null. `handle_new_user()` trigger auto-inserts the row on signup; always `UPDATE`, never `INSERT` from the app.

### Adding a new feature

1. Create `lib/features/<name>/data/<name>_repository.dart` — Supabase queries only. Use `DatabaseConstants.<table>` in every `.from(...)` call — no raw table name strings.
2. Create `lib/features/<name>/presentation/providers/<name>_providers.dart` — `Provider` for the repo, `StateNotifierProvider` or `FutureProvider` for UI state.
3. Create screens under `lib/features/<name>/presentation/screens/`.
4. Add route path constants to `AppRoutes` in `app_router.dart` and add the corresponding `GoRoute` to the `routes` list.
5. Routes that require authentication are protected automatically by the `redirect` callback — only add a route to `isAuthRoute` if it should be publicly accessible.
6. In every async-initialising `StateNotifier`, guard state assignment after `await` with `if (mounted) state = result` — the provider may be rebuilt (e.g. on auth change) before the async completes.

### Routing

All route paths are string constants on `AppRoutes` in `lib/core/router/app_router.dart`. Always use those constants and the path-builder helpers — never raw strings.

| Path | Screen | `extra` type |
|---|---|---|
| `/` | `SplashScreen` | — |
| `/onboarding` | `OnboardingScreen` | — |
| `/login` | `LoginScreen` | — |
| `/signup` | `SignupScreen` | — |
| `/home` | `HomeScreen` (role-based IndexedStack shell) | — |
| `/internships/:id` | `InternshipDetailScreen` (with `_ApplyBar`) | — |
| `/profile/edit` | `ProfileEditScreen` | `Profile?` |
| `/company/internships/new` | `CompanyInternshipFormScreen` (create) | `String` (companyId) |
| `/company/internships/:id/edit` | `CompanyInternshipFormScreen` (edit) | `Internship` |
| `/company/internships/:id/applicants` | `ApplicantListScreen` | `String?` (internship title) |

Path builders: `AppRoutes.internshipDetailPath(id)`, `AppRoutes.companyInternshipEditPath(id)`, `AppRoutes.companyApplicantsPath(id)`.

`context.push` is used for all detail/edit routes to preserve the back-stack. The apply flow and company setup are `showModalBottomSheet` / `MaterialPageRoute` respectively — no GoRouter route added for either.

### Shared widgets and services

| Location | Name | Purpose |
|---|---|---|
| `shared/widgets/` | `AppButton` | Primary / outline / text variants with loading state |
| `shared/widgets/` | `AppTextField` | Labeled form field with password toggle and validator support |
| `shared/widgets/` | `AppLogo` | Brand mark in small / medium / large sizes |
| `shared/widgets/` | `AppSearchBar` | Search input with live clear button; accepts controller + onChanged |
| `shared/services/` | `StorageService` | CV + avatar pick/upload; the only entry point for Supabase Storage |

Internship-specific widgets: `features/internships/presentation/widgets/` — `InternshipCard`, `CompanyAvatar`, `InternshipTypeBadge`, `InternshipSkillChips`, `InternshipFilterBar`.

Application-specific widgets: `features/applications/presentation/widgets/` — `ApplicationCard`, `ApplicationStatusBadge`, `ApplyBottomSheet`.

Company-specific widgets: `features/company/presentation/widgets/` — `CompanyInternshipCard`, `ApplicantCard`.

All styling comes from `AppColors` and `AppTextStyles`. Never use hardcoded `Color(...)` or raw `TextStyle(...)` in screens.

### Theme

Brand palette: primary `#FF6B35` (orange), accent `#1A1F5E` (deep blue). Background and surfaces are pure white (`#FFFFFF`). Typography uses Google Fonts Inter throughout. `AppTheme.light` is the only theme; dark mode is not implemented.

`AppColors.primaryLight` (`#FFF4EF`) is the light orange tint used for selected navigation indicators, skill chips, and profile avatars. `AppColors.cardShadow` (`#0D000000`) is the pre-computed shadow color for cards.

`AppColors` also defines semantic feedback colours for use in widgets — never recreate these as raw `Color(0xFF...)` literals:

| Token | Value | Used for |
|---|---|---|
| `warning` / `warningBg` | amber 700 / amber 50 | Pending application status |
| `info` / `infoBg` | blue 600 / blue 50 | Reviewed status, Hybrid type badge |
| `successBg` | green 50 | Accepted status bg, Applied chip bg |
| `errorBg` | red 50 | Rejected status bg, error containers |
| `typeRemoteText/Bg` | emerald 600 / 50 | Remote internship badge |
| `typeOnsiteText/Bg` | violet 600 / 50 | Onsite internship badge |

## Current Stage

**Stage 4 complete. Stage 5 (AI features) is next.**

Stage 4 delivered:
- `features/company/` — `CompanyRepository`, company dashboard, internship form (create/edit/archive), applicant list with status updates and CV viewer
- `features/profile/` — `ProfileRepository`, `ProfileScreen` (real, not stub), `ProfileEditScreen` with avatar upload
- Role-based `HomeScreen` — student 4-tab / company 2-tab, reads `currentProfileProvider`
- `url_launcher` for opening applicant CV PDFs in the system browser
- `avatars` Supabase Storage bucket + `StorageService.pickAvatarFile()` / `uploadAvatar()`

See `docs/stage4_summary.md` for full SQL migrations, storage setup, and RLS policies.

**Stage 5 will add:** AI CV analysis, AI cover letter generation, AI interview prep. Do not begin Stage 5 without reading `docs/stage4_summary.md` § Stage 5 Recommendations first.

### ConsumerStatefulWidget init pattern

When a `ConsumerStatefulWidget` must initialise Riverpod state from `initState()` (e.g. pre-filling an edit form from an existing model), never call notifier methods directly inside `initState` or `build`. Use `WidgetsBinding.instance.addPostFrameCallback` to defer until after the first frame:

```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;
    ref.read(someProvider.notifier).init(widget.initialData);
  });
}
```

### Company applicant join pattern

`CompanyRepository.fetchApplicants(internshipId)` uses two sequential queries — one for `applications` filtered by internship, then `.inFilter('id', userIds)` on `profiles` — rather than a PostgREST FK join. This avoids adding a FK migration at MVP scale. Results are zipped into `ApplicantEntry` objects in the repository layer.
