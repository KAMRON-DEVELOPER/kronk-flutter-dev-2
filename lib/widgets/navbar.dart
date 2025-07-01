import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kronk/constants/my_theme.dart';
import 'package:kronk/models/navbar_model.dart';
import 'package:kronk/riverpod/general/navbar_provider.dart';
import 'package:kronk/riverpod/general/theme_notifier_provider.dart';
import 'package:kronk/utility/dimensions.dart';

final StateProvider<int> selectedIndexProvider = StateProvider<int>((Ref ref) => 0);

class Navbar extends ConsumerWidget {
  const Navbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Dimensions dimensions = Dimensions.of(context);
    final MyTheme theme = ref.watch(themeNotifierProvider);
    final List<NavbarModel> items = ref.watch(navbarProvider).where((NavbarModel navbarItem) => navbarItem.isEnabled).toList();
    final int selectedIndex = ref.watch(selectedIndexProvider);

    const double iconSize = 32;
    const int maxIconsInScreen = 5;
    final double screenWidth = dimensions.screenWidth;

    // Actual icons we are displaying
    final int count = items.length;

    // If less than or equal to 5 items, distribute evenly
    final bool fitsWithoutScroll = count <= maxIconsInScreen;
    final double itemWidth = fitsWithoutScroll ? screenWidth / count : screenWidth / maxIconsInScreen;

    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: theme.primaryBackground,
        border: Border(top: BorderSide(color: theme.secondaryBackground, width: 0.5)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: count,
        padding: EdgeInsets.zero,
        itemBuilder: (context, index) {
          final item = items.elementAt(index);
          final bool isActive = index == selectedIndex;

          return SizedBox(
            width: itemWidth,
            child: Center(
              child: IconButton(
                padding: EdgeInsets.zero,
                iconSize: iconSize,
                onPressed: () {
                  if (!isActive) {
                    ref.read(selectedIndexProvider.notifier).state = index;
                    context.go(item.route);
                  }
                },
                icon: Icon(
                  item.getIconData(isActive: isActive),
                  color: isActive ? theme.primaryText : theme.secondaryText,
                  size: iconSize,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

String beautifyServiceName(String route, {bool isCapitalize = false}) {
  String cleaned = route.replaceFirst(RegExp(r'^/'), '');

  String spaced = cleaned.replaceAll('_', ' ');

  if (isCapitalize && spaced.isNotEmpty) return spaced[0].toUpperCase() + spaced.substring(1);

  return spaced;
}
