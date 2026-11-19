import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/di/injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/primary_button.dart';
import 'join_class_cubit.dart';

/// #12 Join Class — owner: Member 2
class JoinClassScreen extends StatelessWidget {
  const JoinClassScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl.isRegistered<JoinClassCubit>() ? sl<JoinClassCubit>() : JoinClassCubit.preview(),
      child: const _JoinClassView(),
    );
  }
}

class _JoinClassView extends StatefulWidget {
  const _JoinClassView();

  @override
  State<_JoinClassView> createState() => _JoinClassViewState();
}

class _JoinClassViewState extends State<_JoinClassView> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String raw) {
    final code = JoinClassCubit.normalize(raw);
    if (code != raw) {
      _controller.value = TextEditingValue(
        text: code,
        selection: TextSelection.collapsed(offset: code.length),
      );
    }
    context.read<JoinClassCubit>().setCode(code);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<JoinClassCubit, JoinClassState>(
      builder: (context, state) {
        final cubit = context.read<JoinClassCubit>();
        final joined = state.status == JoinStatus.joined;
        return Scaffold(
          appBar: AppBar(title: const Text('Join a class')),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Enter the 6-character code from your teacher',
                    style: TextStyle(color: AppColors.muted, fontSize: 15),
                  ),
                  const SizedBox(height: 20),
                  _CodeBoxes(
                    code: state.code,
                    focused: !joined,
                    error: state.status == JoinStatus.failed,
                    onTap: () => _focus.requestFocus(),
                    field: TextField(
                      key: const Key('join-code-field'),
                      controller: _controller,
                      focusNode: _focus,
                      autofocus: true,
                      enabled: !joined && state.status != JoinStatus.joining,
                      textCapitalization: TextCapitalization.characters,
                      autocorrect: false,
                      enableSuggestions: false,
                      showCursor: false,
                      maxLength: JoinClassState.codeLength,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
                      ],
                      onChanged: _onChanged,
                      onSubmitted: (_) => cubit.join(),
                      style: const TextStyle(color: Colors.transparent),
                      decoration: const InputDecoration(
                        counterText: '',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        filled: false,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (state.status == JoinStatus.failed && state.error != null)
                    _StatusRow(
                      icon: Icons.error_outline,
                      color: AppColors.danger,
                      text: state.error!,
                    ),
                  if (joined)
                    _StatusRow(
                      icon: Icons.check_circle,
                      color: AppColors.success,
                      text: state.alreadyJoined
                          ? 'You are already in ${state.className}'
                          : 'Joined ${state.className}',
                    ),
                  const Spacer(),
                  joined
                      ? PrimaryButton(
                          label: 'Back to my classes',
                          onPressed: () => Navigator.of(context).maybePop(),
                        )
                      : PrimaryButton(
                          label: 'Join class',
                          loading: state.status == JoinStatus.joining,
                          onPressed: state.canJoin ? cubit.join : null,
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

/// Six boxes (design screen 12) on top of an invisible TextField that does the typing.
class _CodeBoxes extends StatelessWidget {
  const _CodeBoxes({
    required this.code,
    required this.focused,
    required this.error,
    required this.onTap,
    required this.field,
  });

  final String code;
  final bool focused;
  final bool error;
  final VoidCallback onTap;
  final Widget field;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: Stack(
        children: [
          Positioned.fill(child: field),
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              child: Row(
                children: List.generate(JoinClassState.codeLength, (i) {
                  final char = i < code.length ? code[i] : '';
                  final active = focused && i == code.length;
                  final borderColor = error
                      ? AppColors.danger
                      : active
                          ? AppColors.primary
                          : AppColors.border;
                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.only(right: i < JoinClassState.codeLength - 1 ? 8 : 0),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor, width: active ? 2 : 1),
                      ),
                      child: Text(
                        char,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.icon, required this.color, required this.text});

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
