import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/di/injection.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/primary_button.dart';
import '../../auth/presentation/auth_cubit.dart';
import '../data/class_info.dart';
import 'teacher_classes_cubit.dart';

/// #4 Teacher Home — owner: Member 1
class TeacherHomeScreen extends StatelessWidget {
  const TeacherHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final teacherId = context.read<AuthCubit>().state.user?.id ?? '';
    return BlocProvider(
      create: (_) => (sl.isRegistered<TeacherClassesCubit>()
          ? sl<TeacherClassesCubit>()
          : TeacherClassesCubit.preview())
        ..init(teacherId),
      child: const _TeacherHomeView(),
    );
  }
}

class _TeacherHomeView extends StatelessWidget {
  const _TeacherHomeView();

  Future<void> _open(BuildContext context, String route, {Object? arguments}) async {
    final cubit = context.read<TeacherClassesCubit>();
    await Navigator.of(context).pushNamed(route, arguments: arguments);
    await cubit.refreshCounts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My classes'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Material(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => _open(context, AppRoutes.createClass),
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.add, color: Colors.white, semanticLabel: 'New class'),
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthCubit>().logout(),
          ),
        ],
      ),
      body: BlocBuilder<TeacherClassesCubit, TeacherClassesState>(
        builder: (context, state) {
          switch (state.status) {
            case TeacherClassesStatus.loading:
              return const Center(child: CircularProgressIndicator());
            case TeacherClassesStatus.error:
              return ErrorView(
                message: state.error ?? 'Could not load your classes.',
                onRetry: context.read<TeacherClassesCubit>().retry,
              );
            case TeacherClassesStatus.ready:
              break;
          }
          if (state.classes.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.class_outlined, size: 56, color: AppColors.muted),
                  const SizedBox(height: 12),
                  const Text(
                    'No classes yet',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Create a class and share its join code with your students.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.muted, height: 1.4),
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: 'Create class',
                    onPressed: () => _open(context, AppRoutes.createClass),
                  ),
                ],
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              for (final c in state.classes)
                _ClassCard(
                  info: c,
                  students: state.studentCounts[c.id],
                  onTap: () => _open(context, AppRoutes.classDetails, arguments: c.id),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  const _ClassCard({required this.info, required this.students, required this.onTap});

  final ClassInfo info;
  final int? students;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      if (info.semester.isNotEmpty) info.semester,
      if (students != null) '$students ${students == 1 ? 'student' : 'students'}',
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(info.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      if (subtitle.isNotEmpty)
                        Text(subtitle, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(
                        'Code ${info.joinCode}',
                        style: const TextStyle(color: AppColors.success, letterSpacing: 1),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
