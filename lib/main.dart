import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kronk/constants/my_theme.dart';
import 'package:kronk/riverpod/general/theme_provider.dart';
import 'package:kronk/utility/constants.dart';
import 'package:kronk/utility/dimensions.dart';
import 'package:kronk/utility/extensions.dart';
import 'package:kronk/utility/router.dart';
import 'package:kronk/utility/setup.dart';

void main() async {
  String initialLocation = await setup();

  if (kIsWeb) {
    await GoogleSignIn.instance.initialize(clientId: constants.clientId, serverClientId: constants.serverClientId);
  } else {
    await GoogleSignIn.instance.initialize(serverClientId: constants.serverClientId);
  }

  assert(() {
    debugInvertOversizedImages = true;
    return true;
  }());

  final GoRouter router = AppRouter(initialLocation: initialLocation).router;

  runApp(ProviderScope(child: MyApp(router: router)));
}

class MyApp extends ConsumerWidget {
  final GoRouter router;

  const MyApp({super.key, required this.router});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final MyTheme theme = ref.watch(themeNotifierProvider);
    Sizes.init(context);
    return MaterialApp.router(
      title: 'Kronk',
      debugShowCheckedModeBanner: false,
      routerDelegate: router.routerDelegate,
      routeInformationParser: router.routeInformationParser,
      routeInformationProvider: router.routeInformationProvider,

      theme: ThemeData(
        splashFactory: NoSplash.splashFactory,
        scaffoldBackgroundColor: theme.primaryBackground,
        appBarTheme: AppBarTheme(
          backgroundColor: theme.primaryBackground,
          surfaceTintColor: theme.primaryBackground,
          centerTitle: true,
          titleSpacing: 0,
          scrolledUnderElevation: 0,
          elevation: 0,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: theme.secondaryBackground,
          foregroundColor: theme.primaryText,
          shape: const CircleBorder(),
          iconSize: 36.dp,
        ),
        iconTheme: IconThemeData(color: theme.primaryText, size: 16.dp),
        scrollbarTheme: ScrollbarThemeData(radius: Radius.circular(2.dp), thickness: WidgetStatePropertyAll(4.dp), thumbColor: WidgetStatePropertyAll(theme.secondaryText)),
      ),
    );
  }
}
