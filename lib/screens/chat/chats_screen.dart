import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kronk/constants/enums.dart';
import 'package:kronk/riverpod/feed/feed_screen_style_provider.dart';
import 'package:kronk/riverpod/general/theme_notifier_provider.dart';
import 'package:kronk/utility/classes.dart';
import 'package:kronk/utility/dimensions.dart';

class ChatsScreen extends ConsumerWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeNotifierProvider);
    final FeedScreenDisplayState displayState = ref.watch(feedScreenStyleProvider);
    final bool isFloating = displayState.feedScreenDisplayStyle == FeedScreenStyle.floating;
    final Dimensions dimensions = Dimensions.of(context);
    final double margin3 = dimensions.margin3;

    final double screenWidth = dimensions.screenWidth;
    return Scaffold();
  }
}
