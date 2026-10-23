# Contributing

## Branches
- `main` is always working. **Nobody pushes to it directly.**
- One branch per screen: `feature/<screen-name>` (e.g. `feature/teacher-home`, `feature/quiz-builder`).
- Bugs: `fix/<name>`.
- Open a **Pull Request**. Ask one teammate to review, then squash and merge.

## Daily flow
```bash
git checkout main && git pull
git checkout -b feature/my-screen
# work, commit small and often
git add .
git commit -m "feat(classes): add teacher home list"
git push -u origin feature/my-screen
# open a Pull Request
```
Before starting each day: `git pull` on `main` and merge it into your branch.

## Before every PR
```bash
flutter analyze
flutter test
```
Both must be clean. Run the screen on a real phone (GPS on for attendance).

## Commit messages
`type(scope): message`

- type: `feat`, `fix`, `docs`, `refactor`, `chore`
- scope: `auth`, `classes`, `attendance`, `quiz`, `core`

Examples: `feat(quiz): validate 5-question builder`, `fix(auth): show network error on login`.

## Who edits what
Work **only inside your feature folder** (`lib/features/<name>/`).

**Only the leader** edits:

- `lib/core/theme/app_theme.dart`
- `lib/core/router/app_router.dart` (and `app_routes.dart`)
- `lib/core/di/injection.dart`
- `lib/core/widgets/`
- `functions/index.js`, `firestore.rules`

Need a shared widget, a new route, or a Cubit registered? Ask the leader. Routes for all 16 screens are already registered — replace the **body of your screen file**, not the router.

## How to register a Cubit
1. Create the Cubit in `features/<name>/presentation/`.
2. Ask the leader to uncomment / add it in `lib/core/di/injection.dart`:

```dart
sl.registerFactory(() => TeacherHomeCubit(sl<ClassRepository>()));
```

3. In your screen, `BlocProvider(create: (_) => sl<TeacherHomeCubit>()..load(), child: ...)`.
4. Prefer `registerFactory` for Cubits (new instance per screen) and `registerLazySingleton` for repositories.

Commented examples live at the bottom of `injection.dart`.

## Code rules
1. Colors, fonts, buttons: only `AppColors` / `AppTheme` and `core/widgets`. No hardcoded colors or fonts in screens.
2. Screens never import Firebase. Screen → Cubit → Repository.
3. Never write `attendance_records` or `attendance_sessions` from the app. Call Cloud Functions.
4. Session countdown: use `expiryTime` from Firestore, not the phone clock.
5. No `print()`. Use UI error states.
6. Null-safe Dart. `const` where possible.
7. Role is chosen at register and cannot change (Firestore rules enforce this).
8. Do not commit secrets or `node_modules`. The team **does** commit `firebase_options.dart` and `google-services.json` when the leader generates them.
