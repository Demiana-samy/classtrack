import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../auth/presentation/auth_cubit.dart';
import '../../../auth/presentation/login_screen.dart';
import '../widgets/quiz_entry_header.dart';
import '../widgets/quiz_role_selector.dart';
import 'quiz_build_screen.dart';
import 'quiz_screen.dart';

class QuizEntryScreen extends StatefulWidget {
  const QuizEntryScreen({super.key});

  @override
  State<QuizEntryScreen> createState() => _QuizEntryScreenState();
}

class _QuizEntryScreenState extends State<QuizEntryScreen> {
  final _idController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _selectedRole = Roles.teacher;

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }

  void _continue(bool isTeacher) {
    if (_formKey.currentState?.validate() ?? false) {
      final inputId = _idController.text.trim();
      _navigateToScreen(isTeacher, inputId.isNotEmpty ? inputId : null);
    }
  }

  void _openDirectly(bool isTeacher) {
    final inputId = _idController.text.trim();
    _navigateToScreen(isTeacher, inputId.isNotEmpty ? inputId : null);
  }

  void _navigateToScreen(bool isTeacher, String? id) {
    if (isTeacher) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => QuizBuildScreen(classId: id),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => QuizScreen(sessionId: id),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final user = authState.user;
    final isTeacher =
        user != null ? user.isTeacher : (_selectedRole == Roles.teacher);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text(AppStrings.quizPortal),
        actions: [
          if (user != null)
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: AppStrings.logOut,
              onPressed: () => context.read<AuthCubit>().logout(),
            )
          else
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              child: Text(
                AppStrings.signIn,
                style: AppTextStyles.withColor(
                  AppTextStyles.cairo14W600,
                  AppColors.primary,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  QuizEntryHeader(isTeacher: isTeacher, user: user),
                  const SizedBox(height: 24),
                  if (user == null) ...[
                    QuizRoleSelector(
                      selectedRole: _selectedRole,
                      onChanged: (role) {
                        setState(() {
                          _selectedRole = role;
                          _idController.clear();
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                  AppTextField(
                    controller: _idController,
                    label:
                        isTeacher ? AppStrings.classId : AppStrings.sessionId,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return isTeacher
                            ? AppStrings.enterValidClassId
                            : AppStrings.enterValidSessionId;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  PrimaryButton(
                    label: isTeacher
                        ? AppStrings.openQuizBuilder
                        : AppStrings.takeQuiz,
                    onPressed: () => _continue(isTeacher),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => _openDirectly(isTeacher),
                    child: Text(
                      isTeacher
                          ? AppStrings.buildQuizDirectly
                          : AppStrings.openQuizDirectly,
                      style: AppTextStyles.withColor(
                        AppTextStyles.cairo13W400,
                        AppColors.muted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
