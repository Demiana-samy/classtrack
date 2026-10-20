# Task split (edit names, then create one GitHub Issue per line)

Already done in the starter: project structure, theme, shared widgets, Firebase wiring,
Auth (login/register/roles/redirects), router with all routes as TODO screens, repositories,
location service, Cloud Functions (startSession, submitAttendance), Firestore rules.

Phase 0 foundations (done): bundled Cairo font (no google_fonts), app logo + launcher icon
config, Firebase/auth start error screens, debug `/design-preview` catalog with mock data.

## Week 1 - Foundation
| # | Task | Owner | Files |
|---|------|-------|-------|
| 1 | Firebase project + `flutterfire configure` + deploy rules/functions | Leader | firebase_options.dart |
| 2 | Teacher home: class list + Create class screen | Member 2 | classes/presentation |
| 3 | Class details (students + sessions tabs) | Member 2 | classes/presentation |
| 4 | Student home + Join class by code | Member 2 | classes/presentation |
| 5 | Polish Login/Register to match the design | Member 1 | auth/presentation |

## Week 2 - Mode 1 (Punch-In)
| 6 | Start session screen (mode, radius slider, GPS) | Member 3 | attendance/presentation |
| 7 | Student Active Session screen (countdown + PUNCH IN) | Member 3 | attendance/presentation |
| 8 | Result screen (accepted / rejected with reason) | Member 3 | attendance/presentation |
| 9 | Test with 2 phones: near / far / expired / duplicate | Everyone | - |

## Week 3 - Mode 2 (Quiz)
| 10 | Quiz builder (5 questions form + validation) | Member 4 | quiz/presentation |
| 11 | Student quiz screen (timer, progress, submit) | Member 4 | quiz/presentation |
| 12 | Quiz result with score | Member 4 | quiz/presentation |

## Week 4 - Management and polish
| 13 | Teacher live dashboard (stream of records) | Member 5 | attendance/presentation |
| 14 | Session results + absent list (enrolled minus present) | Member 5 | attendance/presentation |
| 15 | Student attendance history | Member 5 | attendance/presentation |
| 16 | Error states: GPS off, permission denied, no internet | Member 1 | core |
| 17 | README final, demo video, report | Leader | - |

Absent students are NOT stored. Compute: enrolled students minus students with a `present` record.
