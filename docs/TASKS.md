# ClassTrack screens

Owners are roles, not people: **Leader / Member 1 / Member 2 / Member 3**.
Replace the body of **your screen file only**. Do not edit `app_router.dart`, `app_theme.dart`, `injection.dart`, or `core/widgets` — ask the leader.

Status: **Ready** = UI can be built against mock data and the route is registered. **Done** = shipped.

| # | Screen | Owner | Feature folder | File | Status |
|---|--------|-------|----------------|------|--------|
| 1 | Splash | Leader | `features/auth` | `lib/features/auth/presentation/splash_screen.dart` | Done |
| 2 | Login | Leader | `features/auth` | `lib/features/auth/presentation/login_screen.dart` | Done |
| 3 | Register | Leader | `features/auth` | `lib/features/auth/presentation/register_screen.dart` | Done |
| 4 | Teacher Home | Member 1 | `features/classes` | `lib/features/classes/presentation/teacher_home_screen.dart` | Ready |
| 5 | Create Class | Member 1 | `features/classes` | `lib/features/classes/presentation/create_class_screen.dart` | Ready |
| 6 | Class Details | Member 1 | `features/classes` | `lib/features/classes/presentation/class_details_screen.dart` | Ready |
| 7 | Start Session | Leader | `features/attendance` | `lib/features/attendance/presentation/start_session_screen.dart` | Ready |
| 8 | Quiz Builder | Member 3 | `features/quiz` | `lib/features/quiz/presentation/quiz_builder_screen.dart` | Ready |
| 9 | Live Dashboard | Member 1 | `features/attendance` | `lib/features/attendance/presentation/live_dashboard_screen.dart` | Ready |
| 10 | Session Results | Member 3 | `features/attendance` | `lib/features/attendance/presentation/session_results_screen.dart` | Ready |
| 11 | Student Home | Member 2 | `features/classes` | `lib/features/classes/presentation/student_home_screen.dart` | Ready |
| 12 | Join Class | Member 2 | `features/classes` | `lib/features/classes/presentation/join_class_screen.dart` | Ready |
| 13 | Active Session | Leader | `features/attendance` | `lib/features/attendance/presentation/active_session_screen.dart` | Ready |
| 14 | Quiz | Member 2 | `features/quiz` | `lib/features/quiz/presentation/quiz_screen.dart` | Ready |
| 15 | Result | Leader | `features/attendance` | `lib/features/attendance/presentation/result_screen.dart` | Done |
| 16 | Attendance History | Member 2 | `features/attendance` | `lib/features/attendance/presentation/attendance_history_screen.dart` | Ready |

Mock data (no Firebase): `features/<name>/data/mock_*.dart`.

## Checklist (copy into your PR)

### 4 Teacher Home — Member 1
- [ ] UI with mock data
- [ ] Cubit
- [ ] Connect to repository
- [ ] Loading / empty / error states
- [ ] Tested on phone

### 5 Create Class — Member 1
- [ ] UI with mock data
- [ ] Cubit
- [ ] Connect to repository
- [ ] Loading / empty / error states
- [ ] Tested on phone

### 6 Class Details — Member 1
- [ ] UI with mock data
- [ ] Cubit
- [ ] Connect to repository
- [ ] Loading / empty / error states
- [ ] Tested on phone

### 7 Start Session — Leader
- [ ] UI with mock data
- [ ] Cubit
- [ ] Connect to repository (`startSession`; quiz list is `List<QuizQuestionDraft>`)
- [ ] Loading / empty / error states
- [ ] Tested on phone

### 8 Quiz Builder — Member 3
- [ ] UI with mock data
- [ ] Cubit
- [ ] Connect to repository (pop `List<QuizQuestionDraft>` of 5; use `QuizDraftValidator`)
- [ ] Loading / empty / error states
- [ ] Tested on phone

### 9 Live Dashboard — Member 1
- [ ] UI with mock data
- [ ] Cubit
- [ ] Connect to repository
- [ ] Loading / empty / error states
- [ ] Tested on phone

### 10 Session Results — Member 3
- [ ] UI with mock data
- [ ] Cubit
- [ ] Connect to repository (absent = enrolled minus present)
- [ ] Loading / empty / error states
- [ ] Tested on phone

### 11 Student Home — Member 2
- [ ] UI with mock data
- [ ] Cubit
- [ ] Connect to repository
- [ ] Loading / empty / error states
- [ ] Tested on phone

### 12 Join Class — Member 2
- [ ] UI with mock data
- [ ] Cubit
- [ ] Connect to repository
- [ ] Loading / empty / error states
- [ ] Tested on phone

### 13 Active Session — Leader
- [ ] UI with mock data
- [ ] Cubit
- [ ] Connect to repository
- [ ] Loading / empty / error states
- [ ] Tested on phone

### 14 Quiz — Member 2
- [ ] UI with mock data
- [ ] Cubit
- [ ] Connect to repository
- [ ] Loading / empty / error states
- [ ] Tested on phone

### 15 Result — Leader
- [x] UI with mock data
- [x] Cubit (display-only; no Cubit required)
- [x] Connect to repository (maps server reason codes)
- [x] Loading / empty / error states
- [x] Tested on phone (widget tests + Design Preview)

### 16 Attendance History — Member 2
- [ ] UI with mock data
- [ ] Cubit
- [ ] Connect to repository
- [ ] Loading / empty / error states
- [ ] Tested on phone

## Already in the starter
Project structure, theme, shared widgets, Firebase wiring, auth, router for all 16 screens, repositories, location service, Cloud Functions, Firestore rules, Design Preview.
