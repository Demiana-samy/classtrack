import 'package:flutter/material.dart';

import '../../features/auth/presentation/auth_cubit.dart';
import 'app_routes.dart';

export 'app_routes.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

void syncAuthRoute(AuthState state) {
  final navigator = appNavigatorKey.currentState;
  if (navigator == null) return;

  final route = switch (state.status) {
    AuthStatus.unknown || AuthStatus.failed => AppRoutes.splash,
    AuthStatus.unauthenticated => AppRoutes.login,
    AuthStatus.authenticated =>
      state.user!.isTeacher ? AppRoutes.teacherHome : AppRoutes.studentHome,
  };

  navigator.pushNamedAndRemoveUntil(route, (route) => false);
}
