import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:kronk/constants/my_theme.dart';
import 'package:kronk/utility/dimensions.dart';
import 'package:kronk/utility/extensions.dart';
import 'package:kronk/utility/my_logger.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../../bloc/authentication/authentication_bloc.dart';
import '../../bloc/authentication/authentication_event.dart';
import '../../bloc/authentication/authentication_state.dart';
import '../../riverpod/general/theme_notifier_provider.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  String? usernameError, emailError, passwordError;
  bool isPasswordVisible = false;
  bool isLoginMode = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onPressed() {
    if (usernameError == null && emailError == null && passwordError == null) {
      final username = _usernameController.text.trim();
      final password = _passwordController.text.trim();

      final loginData = {'username': username, 'password': password};

      if (isLoginMode) {
        context.read<AuthenticationBloc>().add(LoginSubmitEvent(loginData: loginData));
      } else {
        final email = _emailController.text.trim();
        final name = _nameController.text.trim();
        final registerData = {...loginData, 'email': email, 'name': name};
        context.read<AuthenticationBloc>().add(RegisterSubmitEvent(registerData: registerData));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dimensions = Dimensions.of(context);
    final MyTheme theme = ref.watch(themeNotifierProvider);

    final double with2 = dimensions.with2;
    final double margin1 = dimensions.margin1;
    final double margin2 = dimensions.margin2;
    final double buttonHeight1 = dimensions.buttonHeight1;
    final double padding1 = dimensions.padding1;
    final double iconSize2 = dimensions.iconSize2;
    final double iconSize1 = dimensions.iconSize1;
    final double radius1 = dimensions.radius1;
    myLogger.i('🔄 AuthScreen is building...');
    return BlocConsumer<AuthenticationBloc, AuthenticationState>(
      listener: (BuildContext context, AuthenticationState state) async {
        myLogger.d('🚨 listener: $state');
        if (state is AuthLoading) {
        } else if (state is LoginSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: theme.tertiaryBackground,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius1)),
              content: Text('🎉 You have logged in successfully', style: Theme.of(context).textTheme.labelSmall),
            ),
          );
          await Future.delayed(const Duration(seconds: 4));
          if (!context.mounted) return;
          context.go('/settings');
        } else if (state is RegisterSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: theme.tertiaryBackground,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius1)),
              content: Text('🎉 You verification code sent.', style: Theme.of(context).textTheme.labelSmall),
            ),
          );
          await Future.delayed(const Duration(seconds: 4));
          if (!context.mounted) return;
          context.go('/auth/verify');
        } else if (state is GoogleAuthSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: theme.tertiaryBackground,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius1)),
              content: Text('🎉 You have logged in successfully by Google', style: Theme.of(context).textTheme.labelSmall),
            ),
          );
          if (!context.mounted) return;
          context.go('/settings');
        } else if (state is AuthFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: theme.tertiaryBackground,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius1)),
              content: Text('🌋 ${state.failureMessage}', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.redAccent.withValues(alpha: 0.5))),
            ),
          );
        }
      },
      builder: (BuildContext context, AuthenticationState state) {
        return Scaffold(
          appBar: AppBar(automaticallyImplyLeading: false),
          body: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: margin2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(isLoginMode ? 'Login' : 'Register', style: Theme.of(context).textTheme.bodyLarge),
                  SizedBox(height: margin1),
                  AutofillGroup(
                    child: Column(
                      spacing: margin2,
                      children: [
                        if (!isLoginMode)
                          TextFormField(
                            controller: _nameController,
                            style: Theme.of(context).textTheme.bodyMedium,
                            cursorColor: theme.primaryText,
                            // onChanged: (String value) => setState(() => emailError = value.trim().isValidEmail),
                            autofillHints: [AutofillHints.name],
                            // textAlignVertical: TextAlignVertical.center,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: theme.secondaryBackground,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              hintText: 'name',
                              errorText: null,
                              errorStyle: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.red),
                              hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(color: theme.secondaryText),
                              contentPadding: EdgeInsets.symmetric(vertical: padding1, horizontal: padding1),
                            ),
                          ),
                        if (!isLoginMode)
                          TextFormField(
                            controller: _emailController,
                            style: Theme.of(context).textTheme.bodyMedium,
                            cursorColor: theme.primaryText,
                            onChanged: (String value) => setState(() => emailError = value.trim().isValidEmail),
                            autofillHints: [AutofillHints.email],
                            // textAlignVertical: TextAlignVertical.center,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: theme.secondaryBackground,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              hintText: 'email',
                              errorText: emailError,
                              errorStyle: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.red),
                              hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(color: theme.secondaryText),
                              contentPadding: EdgeInsets.symmetric(vertical: padding1, horizontal: padding1),
                            ),
                          ),
                        TextFormField(
                          controller: _usernameController,
                          style: Theme.of(context).textTheme.bodyMedium,
                          cursorColor: theme.primaryText,
                          onChanged: (String value) => setState(() => usernameError = value.trim().isValidUsername),
                          autofillHints: [AutofillHints.username],
                          // textAlignVertical: TextAlignVertical.center,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: theme.secondaryBackground,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            hintText: 'username',
                            errorText: usernameError,
                            hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(color: theme.secondaryText),
                            contentPadding: EdgeInsets.symmetric(vertical: padding1, horizontal: padding1),
                          ),
                        ),
                        TextFormField(
                          controller: _passwordController,
                          style: Theme.of(context).textTheme.bodyMedium,
                          cursorColor: theme.primaryText,
                          onChanged: (String value) => setState(() => usernameError = value.trim().isValidPassword),
                          autofillHints: [AutofillHints.password],
                          obscureText: !isPasswordVisible,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: theme.secondaryBackground,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            hintText: 'password',
                            errorText: passwordError,
                            hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(color: theme.secondaryText),
                            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                            suffixIcon: IconButton(
                              icon: Icon(isPasswordVisible ? Iconsax.eye_outline : Iconsax.eye_slash_outline, color: theme.primaryText.withAlpha(64)),
                              onPressed: () => setState(() => isPasswordVisible = !isPasswordVisible),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isLoginMode) SizedBox(height: margin2),
                  if (isLoginMode)
                    GestureDetector(
                      onTap: () => context.push('/auth/request_forgot_password'),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [Text('Forgot password?', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: theme.secondaryText, height: 0))],
                      ),
                    ),
                  SizedBox(height: margin2),
                  ElevatedButton(
                    onPressed: _onPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryText,
                      fixedSize: Size(with2, buttonHeight1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius1)),
                    ),
                    child: state == AuthLoading()
                        ? LoadingAnimationWidget.inkDrop(color: theme.primaryBackground, size: iconSize2)
                        : Text('Continue', style: Theme.of(context).textTheme.displaySmall?.copyWith(color: theme.primaryBackground)),
                  ),
                  SizedBox(height: margin1),
                  Row(
                    children: [
                      Expanded(child: Divider(color: theme.primaryText.withAlpha(128), thickness: 1, endIndent: 8)),
                      Text('or continue with', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: theme.secondaryText)),
                      Expanded(child: Divider(color: theme.primaryText.withAlpha(128), thickness: 1, indent: 8)),
                    ],
                  ),
                  SizedBox(height: margin1),
                  Row(
                    spacing: margin2,
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.secondaryBackground,
                            fixedSize: Size.fromHeight(buttonHeight1),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius1)),
                            // side: BorderSide(color: activeTheme.primaryText.withAlpha(32), width: 0.4),
                          ),
                          onPressed: () => context.read<AuthenticationBloc>().add(SocialAuthEvent()),
                          child: Icon(IonIcons.logo_google, size: iconSize1, color: theme.primaryText),
                        ),
                      ),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.secondaryBackground,
                            fixedSize: Size.fromHeight(buttonHeight1),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius1)),
                          ),
                          onPressed: () => context.read<AuthenticationBloc>().add(SocialAuthEvent()),
                          child: Icon(IonIcons.logo_apple, size: iconSize1, color: theme.primaryText),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: margin1),
                  GestureDetector(
                    onTap: () => setState(() => isLoginMode = !isLoginMode),
                    child: Text(
                      isLoginMode ? 'Don\'t have an account? Register' : 'Already have an account? Login',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: theme.secondaryText),
                    ),
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
