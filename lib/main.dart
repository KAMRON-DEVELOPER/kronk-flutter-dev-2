import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kronk/constants/my_theme.dart';
import 'package:kronk/riverpod/general/theme_notifier_provider.dart';
import 'package:kronk/utility/constants.dart';
import 'package:kronk/utility/dimensions.dart';
import 'package:kronk/utility/my_logger.dart';
import 'package:kronk/utility/routes.dart';
import 'package:kronk/utility/setup.dart';

void main() async {
  String initialRoute = await setup();

  await GoogleSignIn.instance.initialize(clientId: constants.clientId, serverClientId: constants.serverClientId);

  assert(() {
    debugInvertOversizedImages = true;
    return true;
  }());

  runApp(ProviderScope(child: MyApp(initialRoute: initialRoute)));
}

class MyApp extends ConsumerWidget {
  final String initialRoute;

  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final MyTheme theme = ref.watch(themeNotifierProvider);
    final Dimensions dimensions = Dimensions.of(context);

    final double globalMargin2 = dimensions.margin2;
    // final double textSize1 = dimensions.textSize1;
    final double textSize2 = dimensions.textSize2;
    final double bodyMedium = dimensions.bodyMedium;
    final double textSize3 = dimensions.textSize3;
    // final double textSize4 = dimensions.textSize4;
    final double padding2 = dimensions.padding2;

    myLogger.d('initialRoute: $initialRoute');

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Kronk',
      routerConfig: GoRouter(initialLocation: initialRoute, routes: routes, debugLogDiagnostics: true, restorationScopeId: 'my_app'),

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
          actionsPadding: EdgeInsets.only(right: globalMargin2),
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
        tabBarTheme: TabBarThemeData(
          splashFactory: NoSplash.splashFactory,
          overlayColor: WidgetStatePropertyAll(theme.tertiaryBackground),
          indicatorAnimation: TabIndicatorAnimation.linear,
          dividerHeight: 0,
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(color: theme.primaryBackground, borderRadius: BorderRadius.circular(padding2)),
          labelColor: theme.primaryText,
          unselectedLabelColor: theme.secondaryText,
          labelStyle: GoogleFonts.quicksand(
            textStyle: TextStyle(fontSize: textSize3, fontWeight: FontWeight.w600),
          ),
          unselectedLabelStyle: GoogleFonts.quicksand(
            textStyle: TextStyle(fontSize: textSize3, fontWeight: FontWeight.w600),
          ),
        ),
        progressIndicatorTheme: ProgressIndicatorThemeData(color: theme.primaryText, borderRadius: BorderRadius.circular(8)),
        textSelectionTheme: TextSelectionThemeData(selectionHandleColor: theme.primaryText),
        iconTheme: const IconThemeData(color: Colors.greenAccent),
      ),
    );
  }
}
