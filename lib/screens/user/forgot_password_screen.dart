import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kronk/bloc/authentication/authentication_bloc.dart';
import 'package:kronk/bloc/authentication/authentication_event.dart';
import 'package:kronk/bloc/authentication/authentication_state.dart';
import 'package:kronk/constants/my_theme.dart';
import 'package:kronk/riverpod/general/connectivity_notifier_provider.dart';
import 'package:kronk/riverpod/general/theme_provider.dart';
import 'package:kronk/utility/dimensions.dart';
import 'package:kronk/utility/extensions.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _RequestResetPasswordScreenState();
}

class _RequestResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  late TextEditingController _passwordController;
  late List<FocusNode> _focusNodes;
  late List<TextEditingController> _controllers;
  String _code = '';
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    _passwordController = TextEditingController();
    _controllers = List.generate(4, (int index) => TextEditingController());
    _focusNodes = List.generate(4, (int index) => FocusNode());
  }

  @override
  void dispose() {
    for (TextEditingController controller in _controllers) {
      controller.dispose();
    }
    for (FocusNode focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _onChanged() {
    String code = _controllers.map((TextEditingController controller) => controller.text.trim()).join();

    if (code.length == 4) setState(() => _code = code);
  }

  @override
  Widget build(BuildContext context) {
    final MyTheme theme = ref.watch(themeNotifierProvider);
    final AsyncValue<bool> asyncConnectivity = ref.watch(connectivityNotifierProvider);

    asyncConnectivity.when(
      data: (bool data) => log('🚧 asyncConnectivity data: $data'),
      error: (Object error, StackTrace stackTrace) => log('🚧 asyncConnectivity error: $error, $stackTrace'),
      loading: () => log('🚧 asyncConnectivity loading'),
    );

    final dimensions = Dimensions.of(context);

    final double margin1 = dimensions.margin1;
    final double buttonHeight1 = dimensions.buttonHeight1;
    final double iconSize2 = dimensions.iconSize2;
    final double with2 = dimensions.with2;
    final double radius1 = dimensions.radius1;
    final double margin2 = dimensions.margin2;
    return BlocConsumer<AuthenticationBloc, AuthenticationState>(
      listener: (BuildContext context, AuthenticationState state) async {
        log('🚨 listener: $state');
        if (state is AuthLoading) {
        } else if (state is ForgotPasswordSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Column(children: [Text('🎉 You have changed your password successfully.')]),
              duration: const Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
              dismissDirection: DismissDirection.horizontal,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              margin: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
            ),
          );
          await Future.delayed(const Duration(seconds: 4), () {});
          if (!context.mounted) return;
          context.go('/settings');
        } else if (state is AuthFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🌋 ${state.failureMessage!}'),
              duration: const Duration(seconds: 30),
              behavior: SnackBarBehavior.floating,
              dismissDirection: DismissDirection.horizontal,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              margin: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
            ),
          );
        }
      },

      builder: (BuildContext context, AuthenticationState state) {
        log('🎄 state is $state in builder');
        return Scaffold(
          backgroundColor: theme.primaryBackground,
          body: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: margin2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: margin1,
                children: [
                  /// Text
                  Text('Last Step 😉', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 24)),

                  /// code input
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(
                      4,
                      (int index) => SizedBox(
                        width: 60,
                        height: 60,
                        child: TextField(
                          controller: _controllers.elementAt(index),
                          focusNode: _focusNodes.elementAt(index),
                          maxLength: 1,
                          showCursor: false,
                          textAlign: TextAlign.center,
                          textAlignVertical: TextAlignVertical.center,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(height: 2),
                          decoration: InputDecoration(
                            counterText: '',
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: theme.secondaryText),
                              borderRadius: BorderRadius.circular(radius1),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: theme.primaryText, width: 2),
                              borderRadius: BorderRadius.circular(radius1),
                            ),
                          ),
                          onChanged: (String value) {
                            if (value.isNotEmpty) {
                              if (index < 3) {
                                _focusNodes[index + 1].requestFocus();
                              } else {
                                _focusNodes[index].unfocus();
                              }
                            } else if (value.isEmpty && index > 0) {
                              _focusNodes[index - 1].requestFocus();
                            }

                            _onChanged();
                          },
                        ),
                      ),
                    ),
                  ),

                  /// Input
                  TextFormField(
                    controller: _passwordController,
                    style: TextStyle(color: theme.primaryText, fontSize: 16, fontWeight: FontWeight.normal),
                    cursorColor: theme.primaryText,
                    onChanged: (String value) => setState(() => _passwordError = value.trim().isValidPassword),
                    decoration: InputDecoration(
                      hintText: 'new password',
                      hintStyle: TextStyle(color: theme.secondaryText, fontSize: 16, fontWeight: FontWeight.normal),
                      errorText: _passwordError,
                      errorStyle: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.normal),
                      constraints: BoxConstraints(maxHeight: buttonHeight1 + (_passwordError != null ? 20 : 0), minHeight: buttonHeight1 + (_passwordError != null ? 20 : 0)),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: theme.primaryText.withAlpha(128)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: theme.primaryText),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.redAccent),
                        borderRadius: BorderRadius.circular(buttonHeight1 / 2),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.redAccent.withAlpha(128)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  /// Button
                  ElevatedButton(
                    onPressed: () {
                      if (_passwordController.text.trim().isValidPassword == null && _code.length == 4) {
                        context.read<AuthenticationBloc>().add(ForgotPasswordEvent(forgotPasswordData: {'code': _code, 'new_password': _passwordController.text.trim()}));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryText,
                      fixedSize: Size(with2, buttonHeight1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius1)),
                    ),
                    child: state == AuthLoading()
                        ? LoadingAnimationWidget.inkDrop(color: theme.primaryBackground, size: iconSize2)
                        : Text('change password', style: Theme.of(context).textTheme.displaySmall?.copyWith(color: theme.primaryBackground)),
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
