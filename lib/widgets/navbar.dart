import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kronk/constants/my_theme.dart';
import 'package:kronk/models/navbar_model.dart';
import 'package:kronk/riverpod/general/navbar_provider.dart';
import 'package:kronk/riverpod/general/theme_notifier_provider.dart';

final StateProvider<int> selectedIndexProvider = StateProvider<int>((Ref ref) => 0);

class Navbar extends ConsumerWidget {
  const Navbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final MyTheme theme = ref.watch(themeNotifierProvider);
    final List<NavbarModel> enabledNavbarItems = ref.watch(navbarProvider).where((NavbarModel navbarItem) => navbarItem.isEnabled).toList();
    final int selectedIndex = ref.watch(selectedIndexProvider);
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: theme.primaryBackground,
        border: Border(top: BorderSide(color: theme.outline, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: enabledNavbarItems.map((NavbarModel navbarModel) {
          final int index = enabledNavbarItems.indexOf(navbarModel);
          final bool isActive = index == selectedIndex;
          return GestureDetector(
            onTap: () {
              if (isActive) return;
              ref.read(selectedIndexProvider.notifier).state = index;
              Navigator.popAndPushNamed(context, enabledNavbarItems.elementAt(index).route);
            },
            child: Icon(navbarModel.getIconData(isActive: isActive), color: isActive ? theme.primaryText : theme.secondaryText, size: 32),
          );
        }).toList(),
      ),
    );
  }
}

String beautifyServiceName(String route, {bool isCapitalize = false}) {
  String cleaned = route.replaceFirst(RegExp(r'^/'), '');

  String spaced = cleaned.replaceAll('_', ' ');

  if (isCapitalize && spaced.isNotEmpty) {
    return spaced[0].toUpperCase() + spaced.substring(1);
  }

  return spaced;
}
