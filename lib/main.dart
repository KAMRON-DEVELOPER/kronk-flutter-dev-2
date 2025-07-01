import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kronk/constants/my_theme.dart';
import 'package:kronk/riverpod/general/theme_notifier_provider.dart';
import 'package:kronk/utility/constants.dart';
import 'package:kronk/utility/dimensions.dart';
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
    final Dimensions dimensions = Dimensions.of(context);
    final MyTheme theme = ref.watch(themeNotifierProvider);
    final double textSize2 = dimensions.textSize2;
    final double bodyMedium = dimensions.bodyMedium;
    return MaterialApp.router(
      title: 'Kronk',
      debugShowCheckedModeBanner: false,
      routerDelegate: router.routerDelegate,
      routeInformationParser: router.routeInformationParser,
      routeInformationProvider: router.routeInformationProvider,

      theme: ThemeData(
        splashFactory: NoSplash.splashFactory,
        scaffoldBackgroundColor: theme.primaryBackground,
        textTheme: TextTheme(
          displayLarge: GoogleFonts.quicksand(fontSize: 48, color: theme.primaryText, fontWeight: FontWeight.bold),
          displayMedium: GoogleFonts.quicksand(fontSize: 28, color: theme.primaryText, fontWeight: FontWeight.w600),
          displaySmall: GoogleFonts.quicksand(fontSize: 20, color: theme.primaryText, fontWeight: FontWeight.w700),
          bodyLarge: GoogleFonts.quicksand(fontSize: textSize2, color: theme.primaryText, fontWeight: FontWeight.w700),
          bodyMedium: GoogleFonts.quicksand(fontSize: bodyMedium, color: theme.primaryText, fontWeight: FontWeight.w500),
          bodySmall: GoogleFonts.quicksand(fontSize: 14, color: theme.primaryText),
          titleLarge: GoogleFonts.quicksand(fontSize: 24, color: theme.primaryText),
          titleMedium: GoogleFonts.quicksand(fontSize: 24, color: Colors.purpleAccent),
          titleSmall: GoogleFonts.quicksand(fontSize: 24, color: Colors.purpleAccent),
          labelLarge: GoogleFonts.quicksand(fontSize: 28, color: theme.primaryText, fontWeight: FontWeight.w600),
          labelMedium: GoogleFonts.quicksand(fontSize: 20, color: theme.primaryText),
          labelSmall: GoogleFonts.quicksand(fontSize: 16, color: theme.primaryText, fontWeight: FontWeight.w600),
          headlineLarge: GoogleFonts.quicksand(fontSize: 20, color: theme.primaryText),
          headlineMedium: GoogleFonts.quicksand(fontSize: 16, color: theme.primaryText),
          headlineSmall: GoogleFonts.quicksand(fontSize: 12, color: theme.primaryText),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: theme.primaryBackground,
          surfaceTintColor: theme.primaryBackground,
          centerTitle: true,
          titleSpacing: 0,
          titleTextStyle: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 24, fontWeight: FontWeight.w600),
          actionsPadding: const EdgeInsets.all(0),
          iconTheme: IconThemeData(color: theme.primaryText, size: 28),
          scrolledUnderElevation: 0,
          elevation: 0,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: theme.secondaryBackground,
          foregroundColor: theme.primaryText,
          shape: const CircleBorder(),
          iconSize: 36,
        ),

        progressIndicatorTheme: ProgressIndicatorThemeData(color: theme.primaryText, borderRadius: BorderRadius.circular(8)),
        textSelectionTheme: TextSelectionThemeData(selectionHandleColor: theme.primaryText),
        iconTheme: const IconThemeData(color: Colors.greenAccent),
      ),
    );
  }
}
