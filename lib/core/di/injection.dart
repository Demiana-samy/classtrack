import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import '../../features/attendance/data/attendance_repository.dart';
import '../../features/attendance/data/location_service.dart';
import '../../features/attendance/data/session_repository.dart';
import '../../features/attendance/presentation/active_session_cubit.dart';
import '../../features/attendance/presentation/attendance_history_cubit.dart';
import '../../features/attendance/presentation/start_session_cubit.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/presentation/auth_cubit.dart';
import '../../features/classes/data/class_repository.dart';
import '../../features/classes/presentation/join_class_cubit.dart';
import '../../features/classes/presentation/student_classes_cubit.dart';

final sl = GetIt.instance;

void setupDi() {
  final db = FirebaseFirestore.instance;
  final functions = FirebaseFunctions.instance;

  sl
    ..registerLazySingleton(() => AuthRepository(FirebaseAuth.instance, db))
    ..registerLazySingleton(() => ClassRepository(db, functions))
    ..registerLazySingleton(() => SessionRepository(db, functions))
    ..registerLazySingleton(() => AttendanceRepository(db, functions))
    ..registerLazySingleton(() => LocationService())
    ..registerLazySingleton(() => AuthCubit(sl<AuthRepository>()))
    ..registerFactory(() => StartSessionCubit(sl<SessionRepository>(), sl<LocationService>()))
    ..registerFactory(
      () => ActiveSessionCubit(
        sl<SessionRepository>(),
        sl<AttendanceRepository>(),
        sl<LocationService>(),
        sl<ClassRepository>(),
      ),
    )
    ..registerFactory(() => StudentClassesCubit(sl<ClassRepository>(), sl<SessionRepository>()))
    ..registerFactory(() => JoinClassCubit(sl<ClassRepository>()))
    ..registerFactory(
      () => AttendanceHistoryCubit(
        sl<AttendanceRepository>(),
        sl<SessionRepository>(),
        sl<ClassRepository>(),
      ),
    );

  // --- Cubits teammates will add (leader registers them here) ---
  // sl.registerFactory(() => TeacherHomeCubit(sl<ClassRepository>()));
  // sl.registerFactory(() => CreateClassCubit(sl<ClassRepository>()));
  // sl.registerFactory(() => ClassDetailsCubit(sl<ClassRepository>()));
  // sl.registerFactory(() => LiveDashboardCubit(sl<AttendanceRepository>(), sl<SessionRepository>()));
  // sl.registerFactory(() => SessionResultsCubit(sl<AttendanceRepository>(), sl<ClassRepository>()));
  // sl.registerFactory(() => QuizBuilderCubit());
}
