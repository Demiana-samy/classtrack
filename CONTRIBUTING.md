# Contributing

## Branches
- `main` is always working. Nobody pushes to it directly.
- One branch per task: `feature/<short-name>` (e.g. `feature/mode1-punchin`), `fix/<name>` for bugs.

## Daily flow
```bash
git checkout main && git pull
git checkout -b feature/my-task
# ... work, commit small and often ...
git add . && git commit -m "feat(auth): add register validation"
git push -u origin feature/my-task
# open a Pull Request on GitHub, ask 1 teammate to review, then Squash and merge
```
Before starting work each day: `git pull` on `main` and merge it into your branch.

## Commit messages
`type(scope): message` where type is `feat`, `fix`, `docs`, `refactor`, `chore`.

## Code rules
1. Colors, fonts, buttons: only from `core/theme` and `core/widgets`. No hardcoded colors in screens.
2. Screens never call Firebase directly. Screen -> Cubit -> Repository.
3. Never write `attendance_records` or `attendance_sessions` from the app. Use the Cloud Functions.
4. Session time: always compute the countdown from `expiryTime` in Firestore, not from the phone clock.
5. Run `flutter analyze` before opening a PR.
6. Do not commit secrets or `node_modules`.

## Folder per feature
```
features/<name>/
  data/          models + repositories (Firebase here only)
  presentation/  screens + cubits + feature widgets
```
