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
import 'package:kronk/riverpod/general/theme_notifier_provider.dart';
import 'package:kronk/utility/dimensions.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class VerifyScreen extends ConsumerStatefulWidget {
  const VerifyScreen({super.key});

  @override
  ConsumerState<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends ConsumerState<VerifyScreen> {
  late List<TextEditingController> _controllers;
  final List<FocusNode> _focusNodes = List.generate(4, (int index) => FocusNode());
  String _code = '';

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(4, (int index) => TextEditingController());
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

    final double screenHeight = dimensions.screenHeight;
    final double contentWidth1 = dimensions.with1;
    final double margin1 = dimensions.margin1;
    final double buttonHeight1 = dimensions.buttonHeight1;
    final double iconSize2 = dimensions.iconSize2;
    final double with2 = dimensions.with2;
    final double radius1 = dimensions.radius1;
    final double margin2 = dimensions.margin2;
    return BlocConsumer<AuthenticationBloc, AuthenticationState>(
      listener: (BuildContext context, AuthenticationState state) {
        log('🚨 listener: $state');
        if (state is AuthLoading) {
        } else if (state is LoginSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Column(children: [Text('🎉 You are verified successfully.')]),
              duration: const Duration(seconds: 30),
              behavior: SnackBarBehavior.floating,
              dismissDirection: DismissDirection.horizontal,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              margin: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
            ),
          );
          Future.delayed(const Duration(seconds: 4), () {});
          context.go('/settings');
        } else if (state is AuthFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.failureMessage!),
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
        return Scaffold(
          backgroundColor: theme.primaryBackground,
          body: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: margin2),
            child: Center(
              child: SizedBox(
                width: contentWidth1,
                height: screenHeight,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: margin1,
                  children: [
                    /// text
                    Text('Verify Code', style: Theme.of(context).textTheme.bodyLarge),

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

                    /// continue button
                    ElevatedButton(
                      onPressed: () {
                        log('code: $_code');
                        context.read<AuthenticationBloc>().add(VerifySubmitEvent(code: _code));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryText,
                        fixedSize: Size(with2, buttonHeight1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius1)),
                      ),
                      child: state == AuthLoading()
                          ? LoadingAnimationWidget.inkDrop(color: theme.primaryBackground, size: iconSize2)
                          : Text('Continue', style: Theme.of(context).textTheme.displaySmall?.copyWith(color: theme.primaryBackground)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
