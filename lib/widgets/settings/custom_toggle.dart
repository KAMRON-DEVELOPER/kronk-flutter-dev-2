import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kronk/constants/my_theme.dart';

import 'package:kronk/riverpod/general/navbar_provider.dart';
import 'package:kronk/riverpod/general/theme_notifier_provider.dart';

class CustomToggle extends ConsumerWidget {
  final int index;
  final bool isEnabled;
  final bool toggleable;

  const CustomToggle({super.key, required this.index, required this.isEnabled, this.toggleable = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final MyTheme theme = ref.watch(themeNotifierProvider);
    return GestureDetector(
      onTap: toggleable ? () async => await ref.read(navbarProvider.notifier).toggleNavbarItem(index: index) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 48,
        height: 28,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: isEnabled ? theme.primaryText : theme.secondaryText),
        alignment: isEnabled ? Alignment.centerRight : Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 20,
          height: 20,
          decoration: BoxDecoration(color: theme.secondaryBackground, shape: BoxShape.circle),
        ),
      ),
    );
  }
}
