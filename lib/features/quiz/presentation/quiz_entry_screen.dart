import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_strings.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../../auth/presentation/auth_cubit.dart';
import '../../auth/presentation/login_screen.dart';
import 'quiz_builder_screen.dart';
import 'quiz_screen.dart';

/// Entry screen that serves as the app's initial landing page.
/// Dynamically routes to QuizBuilderScreen (teacher) or QuizScreen (student)
/// while properly collecting required classId or sessionId.
class QuizEntryScreen extends StatefulWidget {
  const QuizEntryScreen({super.key});

  @override
  State<QuizEntryScreen> createState() => _QuizEntryScreenState();
}

class _QuizEntryScreenState extends State<QuizEntryScreen> {
  final _idController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Fallback role selection when not authenticated
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
          builder: (_) => QuizBuilderScreen(classId: id),
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

    // Use authenticated role if logged in; otherwise use the local toggle
    final isTeacher = user != null ? user.isTeacher : (_selectedRole == Roles.teacher);

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
                style: AppTextStyles.withColor(AppTextStyles.cairo14W600, AppColors.primary),
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
                  const AppLogo(size: 72),
                  const SizedBox(height: 16),
                  Text(
                    isTeacher ? AppStrings.teacherQuizBuilder : AppStrings.studentQuiz,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.withColor(AppTextStyles.cairo22W700, Colors.white),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    user != null
                        ? AppStrings.loggedInAs(user.name, user.role)
                        : AppStrings.selectRolePrompt,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.withColor(AppTextStyles.cairo14W400, AppColors.muted),
                  ),
                  const SizedBox(height: 24),

                  // If user is not logged in, allow choosing Teacher or Student
                  if (user == null) ...[
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: Roles.teacher,
                          label: Text(AppStrings.teacher),
                          icon: Icon(Icons.school),
                        ),
                        ButtonSegment(
                          value: Roles.student,
                          label: Text(AppStrings.student),
                          icon: Icon(Icons.person),
                        ),
                      ],
                      selected: {_selectedRole},
                      onSelectionChanged: (newSelection) {
                        setState(() {
                          _selectedRole = newSelection.first;
                          _idController.clear();
                        });
                      },
                      style: SegmentedButton.styleFrom(
                        backgroundColor: AppColors.card,
                        selectedBackgroundColor: AppColors.primary,
                        selectedForegroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Input field for Class ID or Session ID
                  AppTextField(
                    controller: _idController,
                    label: isTeacher ? AppStrings.classId : AppStrings.sessionId,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return isTeacher
                            ? AppStrings.enterValidClassId
                            : AppStrings.enterValidSessionId;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Continue button using shared PrimaryButton
                  PrimaryButton(
                    label: isTeacher ? AppStrings.openQuizBuilder : AppStrings.takeQuiz,
                    onPressed: () => _continue(isTeacher),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => _openDirectly(isTeacher),
                    child: Text(
                      isTeacher
                          ? AppStrings.buildQuizDirectly
                          : AppStrings.openQuizDirectly,
                      style: AppTextStyles.withColor(AppTextStyles.cairo13W400, AppColors.muted),
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
