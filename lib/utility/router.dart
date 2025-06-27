import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kronk/bloc/authentication/authentication_bloc.dart';
import 'package:kronk/models/feed_model.dart';
import 'package:kronk/screens/chat/chats_screen.dart';
import 'package:kronk/screens/education/education_screen.dart';
import 'package:kronk/screens/feed/feed_screen.dart';
import 'package:kronk/screens/feed/feeds_screen.dart';
import 'package:kronk/screens/search_screen.dart';
import 'package:kronk/screens/user/auth_screen.dart';
import 'package:kronk/screens/user/forgot_password_screen.dart';
import 'package:kronk/screens/user/notes_screen.dart';
import 'package:kronk/screens/user/player_screen.dart';
import 'package:kronk/screens/user/profile_screen.dart';
import 'package:kronk/screens/user/request_forgot_password_screen.dart';
import 'package:kronk/screens/user/settings_screen.dart';
import 'package:kronk/screens/user/todos_screen.dart';
import 'package:kronk/screens/user/verify_screen.dart';
import 'package:kronk/screens/user/welcome_screen.dart';
import 'package:kronk/utility/my_logger.dart';

// final _rootNavigatorKey = GlobalKey<NavigatorState>();
// final _sectionNavigatorKey = GlobalKey<NavigatorState>();

class MyNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route route, Route? previousRoute) {
    myLogger.i('didPush, route: ${route.settings.name}, previousRoute: ${previousRoute?.settings.name}');
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    myLogger.i('didPop, route: ${route.settings.name}, previousRoute: ${previousRoute?.settings.name}');
    super.didPop(route, previousRoute);
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    myLogger.i('didReplace, newRoute: ${newRoute?.settings.name}, oldRoute: ${oldRoute?.settings.name}');
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  @override
  void didChangeTop(Route topRoute, Route? previousTopRoute) {
    myLogger.i('didChangeTop, topRoute: ${topRoute.settings.name}, previousTopRoute: ${previousTopRoute?.settings.name}');
    super.didChangeTop(topRoute, previousTopRoute);
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    myLogger.i('didRemove, route: ${route.settings.name}, previousRoute: ${previousRoute?.settings.name}');
    super.didRemove(route, previousRoute);
  }
}

class AppRouter {
  final String initialLocation;

  AppRouter({required this.initialLocation});

  GoRouter get router => GoRouter(
    debugLogDiagnostics: true,
    observers: [MyNavigatorObserver()],
    // navigatorKey: _rootNavigatorKey,
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/welcome',
        pageBuilder: (context, state) => FadeTransitionPage(key: state.pageKey, child: const WelcomeScreen()),
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (context, state) => SlidePageTransition(key: state.pageKey, child: const SettingsScreen()),
      ),
      GoRoute(
        path: '/auth',
        pageBuilder: (context, state) {
          return SlidePageTransition(
            key: state.pageKey,
            child: BlocProvider(create: (context) => AuthenticationBloc(), child: const AuthScreen()),
          );
        },
        routes: [
          GoRoute(
            path: 'verify',
            pageBuilder: (context, state) => SlidePageTransition(
              key: state.pageKey,
              child: BlocProvider(create: (BuildContext context) => AuthenticationBloc(), child: const VerifyScreen()),
            ),
          ),
          GoRoute(
            path: 'request_forgot_password',
            pageBuilder: (context, state) => SlidePageTransition(
              key: state.pageKey,
              child: BlocProvider(create: (BuildContext context) => AuthenticationBloc(), child: const RequestForgotPasswordScreen()),
            ),
          ),
          GoRoute(
            path: 'forgot_password',
            pageBuilder: (context, state) => SlidePageTransition(
              key: state.pageKey,
              child: BlocProvider(create: (BuildContext context) => AuthenticationBloc(), child: const ResetPasswordScreen()),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/feeds',
        pageBuilder: (context, state) => SlidePageTransition(key: state.pageKey, child: const FeedsScreen()),
        routes: [
          GoRoute(
            path: 'feed',
            pageBuilder: (context, state) {
              final feed = state.extra as FeedModel;
              return SlidePageTransition(
                child: FeedScreen(key: state.pageKey, feed: feed),
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/search',
        pageBuilder: (context, state) => SlidePageTransition(key: state.pageKey, child: const SearchScreen()),
      ),
      GoRoute(
        path: '/chats',
        pageBuilder: (context, state) => SlidePageTransition(key: state.pageKey, child: const ChatScreen()),
      ),
      GoRoute(
        path: '/education',
        pageBuilder: (context, state) => SlidePageTransition(key: state.pageKey, child: const EducationScreen()),
      ),
      GoRoute(
        path: '/notes',
        pageBuilder: (context, state) => SlidePageTransition(key: state.pageKey, child: const NotesScreen()),
      ),
      GoRoute(
        path: '/todos',
        pageBuilder: (context, state) => SlidePageTransition(key: state.pageKey, child: const TodosScreen()),
      ),
      GoRoute(
        path: '/entertainment',
        pageBuilder: (context, state) => SlidePageTransition(key: state.pageKey, child: const PlayerScreen()),
      ),
      GoRoute(
        path: '/profile',
        pageBuilder: (context, state) => SlidePageTransition(key: state.pageKey, child: const ProfileScreen()),
      ),
    ],
    errorPageBuilder: (context, state) => const MaterialPage(child: Center(child: Text('Error'))),
  );
}

class FadeTransitionPage extends CustomTransitionPage<void> {
  FadeTransitionPage({required super.child, super.key})
    : super(
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
            child: child,
          );
        },
      );
}

class SlidePageTransition extends CustomTransitionPage<void> {
  SlidePageTransition({required super.child, super.key})
    : super(
        transitionDuration: const Duration(milliseconds: 200),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final tween = Tween(begin: const Offset(1.0, 0.0), end: Offset.zero).chain(CurveTween(curve: Curves.easeOut));
          return SlideTransition(position: animation.drive(tween), child: child);
        },
      );
}
