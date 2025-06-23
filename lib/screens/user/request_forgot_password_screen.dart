import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kronk/utility/dimensions.dart';
import 'package:kronk/utility/extensions.dart';
import 'package:kronk/constants/my_theme.dart';
import 'package:kronk/bloc/authentication/authentication_bloc.dart';
import 'package:kronk/bloc/authentication/authentication_event.dart';
import 'package:kronk/bloc/authentication/authentication_state.dart';
import 'package:kronk/riverpod/general/theme_notifier_provider.dart';

import 'package:kronk/riverpod/general/connectivity_notifier_provider.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class RequestForgotPasswordScreen extends ConsumerStatefulWidget {
  const RequestForgotPasswordScreen({super.key});

  @override
  ConsumerState<RequestForgotPasswordScreen> createState() => _RequestForgotPasswordScreenState();
}

class _RequestForgotPasswordScreenState extends ConsumerState<RequestForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  String? _emailError;

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
        } else if (state is RequestForgotPasswordSuccess) {
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
          Navigator.pushNamedAndRemoveUntil(context, '/auth/forgot_password', (Route<dynamic> route) => false);
        } else if (state is AuthFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🌋 ${state.failureMessage!}'),
              duration: const Duration(seconds: 4),
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
                  Text('Request Forgot Password', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 24)),

                  /// Input
                  AutofillGroup(
                    child: TextFormField(
                      controller: _emailController,
                      style: TextStyle(color: theme.primaryText, fontSize: 16, fontWeight: FontWeight.normal),
                      cursorColor: theme.primaryText,
                      onChanged: (String value) => setState(() => _emailError = value.trim().isValidEmail),
                      autofillHints: [AutofillHints.email],
                      decoration: InputDecoration(
                        hintText: 'email',
                        hintStyle: TextStyle(color: theme.secondaryText, fontSize: 16, fontWeight: FontWeight.normal),
                        errorText: _emailError,
                        errorStyle: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.normal),
                        constraints: BoxConstraints(maxHeight: buttonHeight1 + (_emailError != null ? 20 : 0), minHeight: buttonHeight1 + (_emailError != null ? 20 : 0)),
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
                  ),

                  /// Button
                  ElevatedButton(
                    onPressed: () {
                      if (_emailController.text.trim().isValidEmail == null) {
                        context.read<AuthenticationBloc>().add(RequestForgotPasswordEvent(email: _emailController.text.trim()));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryText,
                      fixedSize: Size(with2, buttonHeight1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius1)),
                    ),
                    child: state == AuthLoading()
                        ? LoadingAnimationWidget.inkDrop(color: theme.primaryBackground, size: iconSize2)
                        : Text('Send code', style: Theme.of(context).textTheme.displaySmall?.copyWith(color: theme.primaryBackground)),
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
