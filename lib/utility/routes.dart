import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kronk/bloc/authentication/authentication_bloc.dart';
import 'package:kronk/models/feed_model.dart';
import 'package:kronk/screens/chat/chat_screen.dart';
import 'package:kronk/screens/education/education_screen.dart';
import 'package:kronk/screens/feed/feed_screen.dart';
import 'package:kronk/screens/feed/feeds_screen.dart';
import 'package:kronk/screens/feed/feeds_search_screen.dart';
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

final List<GoRoute> routes = [
  GoRoute(
    path: '/welcome',
    pageBuilder: (context, state) => FadeTransitionPage(child: const WelcomeScreen()),
  ),
  GoRoute(
    path: '/settings',
    pageBuilder: (context, state) => SlidePageTransition(child: const SettingsScreen()),
  ),
  GoRoute(
    path: '/auth',
    pageBuilder: (context, state) {
      return SlidePageTransition(
        child: BlocProvider(create: (context) => AuthenticationBloc(), child: const AuthScreen()),
      );
    },
    routes: [
      GoRoute(
        path: 'verify',
        pageBuilder: (context, state) => SlidePageTransition(
          child: BlocProvider(create: (BuildContext context) => AuthenticationBloc(), child: const VerifyScreen()),
        ),
      ),
      GoRoute(
        path: 'request_forgot_password',
        pageBuilder: (context, state) => SlidePageTransition(
          child: BlocProvider(create: (BuildContext context) => AuthenticationBloc(), child: const RequestForgotPasswordScreen()),
        ),
      ),
      GoRoute(
        path: 'forgot_password',
        pageBuilder: (context, state) => SlidePageTransition(
          child: BlocProvider(create: (BuildContext context) => AuthenticationBloc(), child: const ResetPasswordScreen()),
        ),
      ),
    ],
  ),
  GoRoute(
    path: '/feeds',
    pageBuilder: (context, state) => SlidePageTransition(child: const FeedsScreen()),
    routes: [
      GoRoute(
        path: 'feed',
        pageBuilder: (context, state) {
          final feed = state.extra as FeedModel;
          return SlidePageTransition(child: FeedScreen(feed: feed));
        },
      ),
    ],
  ),
  GoRoute(
    path: '/search',
    pageBuilder: (context, state) => SlidePageTransition(child: const FeedsSearchScreen()),
  ),
  GoRoute(
    path: '/chats',
    pageBuilder: (context, state) => SlidePageTransition(child: const ChatScreen()),
  ),
  GoRoute(
    path: '/education',
    pageBuilder: (context, state) => SlidePageTransition(child: const EducationScreen()),
  ),
  GoRoute(
    path: '/notes',
    pageBuilder: (context, state) => SlidePageTransition(child: const NotesScreen()),
  ),
  GoRoute(
    path: '/todos',
    pageBuilder: (context, state) => SlidePageTransition(child: const TodosScreen()),
  ),
  GoRoute(
    path: '/entertainment',
    pageBuilder: (context, state) => SlidePageTransition(child: const PlayerScreen()),
  ),
  GoRoute(
    path: '/profile',
    pageBuilder: (context, state) => SlidePageTransition(child: const ProfileScreen()),
  ),
];

class FadeTransitionPage extends CustomTransitionPage<void> {
  FadeTransitionPage({required super.child, super.key})
    : super(
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      );
}

class SlideRightToLeftPage extends CustomTransitionPage<void> {
  SlideRightToLeftPage({required super.child, super.key})
    : super(
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(animation),
            child: child,
          );
        },
      );
}

class SlideFromRightPage extends CustomTransitionPage<void> {
  SlideFromRightPage({required super.child, super.key})
    : super(
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween(begin: const Offset(1.0, 0.0), end: Offset.zero).chain(CurveTween(curve: Curves.easeOut)).animate(animation),
            child: child,
          );
        },
      );
}

class SlideFromLeftPage extends CustomTransitionPage<void> {
  SlideFromLeftPage({required super.child, super.key})
    : super(
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween(begin: const Offset(-1.0, 0.0), end: Offset.zero).chain(CurveTween(curve: Curves.easeOut)).animate(animation),
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
          final isPush = animation.status != AnimationStatus.reverse;

          final beginOffset = isPush ? const Offset(1.0, 0.0) : const Offset(-1.0, 0.0);
          final endOffset = Offset.zero;
          final tween = Tween(begin: beginOffset, end: endOffset).chain(CurveTween(curve: Curves.easeOut));

          return SlideTransition(position: animation.drive(tween), child: child);
        },
      );
}
