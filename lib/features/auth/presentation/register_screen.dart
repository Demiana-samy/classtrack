import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import 'auth_cubit.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _studentId = TextEditingController();
  final _password = TextEditingController();
  String _role = Roles.student;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _studentId.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listenWhen: (p, c) => c.error != null && p.error != c.error,
      listener: (context, state) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(state.error!))),
      builder: (context, state) => Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: () => context.go('/login')),
          title: const Text('Create account'),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _form,
              child: ListView(
                children: [
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: Roles.student, label: Text('Student')),
                      ButtonSegment(value: Roles.teacher, label: Text('Teacher')),
                    ],
                    selected: {_role},
                    onSelectionChanged: (s) => setState(() => _role = s.first),
                  ),
                  const SizedBox(height: 18),
                  AppTextField(
                    controller: _name,
                    label: 'Full name',
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    controller: _email,
                    label: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) =>
                        (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                  ),
                  if (_role == Roles.student) ...[
                    const SizedBox(height: 14),
                    AppTextField(
                      controller: _studentId,
                      label: 'Student ID',
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ],
                  const SizedBox(height: 14),
                  AppTextField(
                    controller: _password,
                    label: 'Password',
                    obscure: true,
                    validator: (v) => (v == null || v.length < 6) ? 'Min 6 characters' : null,
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: 'Register',
                    loading: state.isBusy,
                    onPressed: () {
                      if (_form.currentState!.validate()) {
                        context.read<AuthCubit>().register(
                              name: _name.text,
                              email: _email.text,
                              password: _password.text,
                              role: _role,
                              studentId: _studentId.text,
                            );
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Your role is chosen once and cannot be changed later.',
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                    textAlign: TextAlign.center,
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
