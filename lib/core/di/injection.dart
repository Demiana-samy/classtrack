import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import '../../features/attendance/data/attendance_repository.dart';
import '../../features/attendance/data/location_service.dart';
import '../../features/attendance/data/session_repository.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/presentation/auth_cubit.dart';
import '../../features/classes/data/class_repository.dart';

final sl = GetIt.instance;

void setupDi() {
  final db = FirebaseFirestore.instance;
  final functions = FirebaseFunctions.instance;

  sl
    ..registerLazySingleton(() => AuthRepository(FirebaseAuth.instance, db))
    ..registerLazySingleton(() => ClassRepository(db))
    ..registerLazySingleton(() => SessionRepository(db, functions))
    ..registerLazySingleton(() => AttendanceRepository(db, functions))
    ..registerLazySingleton(() => LocationService())
    ..registerLazySingleton(() => AuthCubit(sl<AuthRepository>()));
}
