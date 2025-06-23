import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kronk/riverpod/general/theme_notifier_provider.dart';
import 'package:kronk/screens/feed/feeds_screen.dart';
import 'package:kronk/utility/dimensions.dart';
import 'package:kronk/constants/my_theme.dart';
import 'package:page_transition/page_transition.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  @override
  Widget build(BuildContext context) {
    final MyTheme activeTheme = ref.watch(themeNotifierProvider);
    final Dimensions dimensions = Dimensions.of(context);

    final double globalMargin2 = dimensions.margin2;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post'),
        leading: GestureDetector(
          onTap: () => context.pushTransition(type: PageTransitionType.leftToRight, child: const FeedsScreen()),
          child: Icon(Icons.arrow_back_rounded, color: activeTheme.primaryText),
        ),
        actionsPadding: EdgeInsets.only(right: globalMargin2),
      ),
      body: const Center(child: Text('Post View')),
    );
  }
}
