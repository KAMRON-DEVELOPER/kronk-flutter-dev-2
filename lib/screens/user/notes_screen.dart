import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kronk/riverpod/general/theme_notifier_provider.dart';
import 'package:kronk/utility/dimensions.dart';
import 'package:kronk/widgets/custom_appbar.dart';
import 'package:kronk/widgets/navbar.dart';

class NotesScreen extends ConsumerWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeNotifierProvider);
    final Dimensions dimensions = Dimensions.of(context);
    final double margin3 = dimensions.margin3;
    return Scaffold(
      appBar: CustomAppBar(
        appBarHeight: 48,
        bottomHeight: 0,
        bottomGap: 4,
        actionsSpacing: 12,
        appBarPadding: EdgeInsets.only(left: margin3, right: margin3 - 6),
        bottomPadding: EdgeInsets.only(left: margin3, right: margin3, bottom: 4),
        leading: Builder(
          builder: (context) => GestureDetector(
            onTap: () => Scaffold.of(context).openDrawer(),
            child: Icon(Icons.menu_rounded, color: theme.primaryText, size: 24),
          ),
        ),
        title: Text(
          'Chats',
          style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 24, fontWeight: FontWeight.w600),
        ),
        actions: [
          GestureDetector(
            onTap: () {},
            child: Icon(Icons.search_rounded, color: theme.primaryText, size: 24),
          ),
          GestureDetector(
            onTap: () {},
            child: Icon(Icons.more_vert_rounded, color: theme.primaryText, size: 24),
          ),
        ],
      ),
      body: Center(
        child: Text('Will be available soon, ⌛', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 24, fontWeight: FontWeight.bold)),
      ),
      bottomNavigationBar: const Navbar(),
    );
  }
}
