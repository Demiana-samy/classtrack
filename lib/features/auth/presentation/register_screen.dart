import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_routes.dart';
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

  void _submit() {
    if (_form.currentState!.validate()) {
      context.read<AuthCubit>().register(
            name: _name.text,
            email: _email.text,
            password: _password.text,
            role: _role,
            studentId: _studentId.text,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listenWhen: (p, c) => c.error != null && p.error != c.error,
      listener: (context, state) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.card,
          content: Text(state.error!),
        ),
      ),
      builder: (context, state) => Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: () => context.go(AppRoutes.login)),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _form,
              child: ListView(
                children: [
                  const Text(
                    'Create account',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  _RoleSegment(
                    role: _role,
                    onChanged: (role) => setState(() => _role = role),
                  ),
                  const SizedBox(height: 18),
                  AppTextField(
                    controller: _name,
                    label: 'Full name',
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your name' : null,
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
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Enter your student ID' : null,
                    ),
                  ],
                  const SizedBox(height: 14),
                  AppTextField(
                    controller: _password,
                    label: 'Password',
                    obscure: true,
                    validator: (v) =>
                        (v == null || v.length < 6) ? 'Min 6 characters' : null,
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: 'Register',
                    loading: state.isBusy,
                    onPressed: _submit,
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

class _RoleSegment extends StatelessWidget {
  const _RoleSegment({required this.role, required this.onChanged});

  final String role;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _chip(label: 'Teacher', value: Roles.teacher),
          _chip(label: 'Student', value: Roles.student),
        ],
      ),
    );
  }

  Widget _chip({required String label, required String value}) {
    final selected = role == value;
    return Expanded(
      child: Material(
        color: selected ? AppColors.primaryDark : AppColors.card,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => onChanged(value),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: selected ? null : AppColors.muted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
