import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/di/injection.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../../auth/presentation/auth_cubit.dart';
import 'create_class_cubit.dart';
import 'join_code_card.dart';

/// #5 Create Class — owner: Member 1
class CreateClassScreen extends StatelessWidget {
  const CreateClassScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl.isRegistered<CreateClassCubit>() ? sl<CreateClassCubit>() : CreateClassCubit.preview(),
      child: const _CreateClassView(),
    );
  }
}

class _CreateClassView extends StatefulWidget {
  const _CreateClassView();

  @override
  State<_CreateClassView> createState() => _CreateClassViewState();
}

class _CreateClassViewState extends State<_CreateClassView> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _semester = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _semester.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    context.read<CreateClassCubit>().create(
          name: _name.text,
          semester: _semester.text,
          teacherId: context.read<AuthCubit>().state.user?.id ?? '',
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CreateClassCubit, CreateClassState>(
      listenWhen: (p, c) =>
          (c.createdClassId != null && p.createdClassId != c.createdClassId) ||
          (c.error != null && p.error != c.error),
      listener: (context, state) {
        if (state.createdClassId != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.card,
              content: Text('Class created. Share the code ${state.joinCode} with your students.'),
            ),
          );
          Navigator.of(context).pushReplacementNamed(
            AppRoutes.classDetails,
            arguments: state.createdClassId,
          );
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.card,
            content: Text(state.error!, style: const TextStyle(color: AppColors.danger)),
          ),
        );
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const Text('New class')),
          body: SafeArea(
            child: Form(
              key: _form,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  AppTextField(
                    controller: _name,
                    label: 'Class name',
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Enter the class name' : null,
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    controller: _semester,
                    label: 'Semester (e.g. Fall 2026)',
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Enter the semester' : null,
                  ),
                  const SizedBox(height: 20),
                  JoinCodeCard(
                    code: state.joinCode,
                    onRefresh: context.read<CreateClassCubit>().newCode,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Students type this code in "Join a class". You can copy it now or later from the class page.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.muted, fontSize: 12, height: 1.4),
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: 'Create class',
                    loading: state.isSaving,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
