import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kronk/utility/dimensions.dart';
import 'package:kronk/constants/my_theme.dart';
import 'package:rive/rive.dart';
import 'package:kronk/riverpod/general/theme_notifier_provider.dart';

import 'package:kronk/riverpod/general/connectivity_notifier_provider.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Dimensions dimensions = Dimensions.of(context);
    final MyTheme theme = ref.watch(themeNotifierProvider);
    final AsyncValue<bool> asyncConnectivity = ref.watch(connectivityNotifierProvider);

    final double width2 = dimensions.with2;
    final double margin2 = dimensions.margin2;
    final double margin3 = dimensions.margin3;
    final double margin4 = dimensions.margin4;
    final double buttonHeight1 = dimensions.buttonHeight1;
    final double radius1 = dimensions.radius1;

    void onPressed() {
      asyncConnectivity.when(
        data: (bool isOnline) {
          if (!isOnline) {
            return ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: theme.tertiaryBackground,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius1)),
                content: Text("Looks like you're offline! 🥺", style: Theme.of(context).textTheme.labelSmall),
              ),
            );
          }
          Navigator.pushNamed(context, '/auth');
        },
        loading: () {},
        error: (Object err, StackTrace stack) {},
      );
    }

    return Scaffold(
      backgroundColor: theme.primaryBackground,
      body: Stack(
        children: [
          // Animation
          const RiveAnimation.asset('assets/animations/splash-bubble.riv'),

          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(color: theme.primaryBackground.withValues(alpha: 0.5)),
            ),
          ),

          // Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('Kronk', style: Theme.of(context).textTheme.displayLarge),
                Text('it is meant to be yours', style: Theme.of(context).textTheme.displaySmall?.copyWith(color: theme.primaryText)),
                SizedBox(height: margin2),
                ElevatedButton(
                  onPressed: onPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryText,
                    fixedSize: Size(width2, buttonHeight1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius1)),
                  ),
                  child: Text('Continue', style: Theme.of(context).textTheme.displaySmall?.copyWith(color: theme.primaryBackground)),
                ),
                SizedBox(height: margin4),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/settings'),
                  child: Text('Set up later', style: Theme.of(context).textTheme.displaySmall?.copyWith(color: theme.secondaryText)),
                ),
                SizedBox(height: margin3),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
