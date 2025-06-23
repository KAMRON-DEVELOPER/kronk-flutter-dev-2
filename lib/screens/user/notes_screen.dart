import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kronk/constants/my_theme.dart';
import 'package:kronk/widgets/navbar.dart';

import '../../riverpod/general/theme_notifier_provider.dart';

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  @override
  Widget build(BuildContext context) {
    final MyTheme activeTheme = ref.watch(themeNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Note Screen'), automaticallyImplyLeading: false),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Text('Notes Screen', style: TextStyle(color: activeTheme.primaryText, fontSize: 36))],
        ),
      ),
      bottomNavigationBar: const Navbar(),
    );
  }
}
