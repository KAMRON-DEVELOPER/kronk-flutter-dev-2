import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kronk/bloc/authentication/authentication_bloc.dart';
import 'package:kronk/screens/chat/chat_screen.dart';
import 'package:kronk/screens/education/education_screen.dart';
import 'package:kronk/screens/feed/feeds_screen.dart';
import 'package:kronk/screens/feed/feed_screen.dart';
import 'package:kronk/screens/feed/feeds_search_screen.dart';
import 'package:kronk/screens/user/auth_screen.dart';
import 'package:kronk/screens/user/notes_screen.dart';
import 'package:kronk/screens/user/player_screen.dart';
import 'package:kronk/screens/user/profile_screen.dart';
import 'package:kronk/screens/user/request_forgot_password_screen.dart';
import 'package:kronk/screens/user/forgot_password_screen.dart';
import 'package:kronk/screens/user/settings_screen.dart';
import 'package:kronk/screens/user/welcome_screen.dart';
import 'package:kronk/screens/user/todos_screen.dart';
import 'package:kronk/screens/user/verify_screen.dart';
import 'package:page_transition/page_transition.dart';

PageTransition? routes(RouteSettings settings, BuildContext context) {
  switch (settings.name) {
    case '/welcome':
      return PageTransition(type: PageTransitionType.fade, curve: Curves.easeOut, childCurrent: context.currentRoute, child: const WelcomeScreen(), settings: settings);
    case '/settings':
      return PageTransition(type: PageTransitionType.rightToLeft, curve: Curves.easeOut, childCurrent: context.currentRoute, child: const SettingsScreen(), settings: settings);
    case '/auth':
      return PageTransition(
        child: BlocProvider(create: (BuildContext context) => AuthenticationBloc(), child: const AuthScreen()),
        type: PageTransitionType.rightToLeft,
        reverseType: PageTransitionType.leftToRight,
        alignment: Alignment.center,
        settings: settings,
      );
    case '/auth/verify':
      return PageTransition(
        child: BlocProvider(create: (BuildContext context) => AuthenticationBloc(), child: const VerifyScreen()),
        type: PageTransitionType.rightToLeft,
        reverseType: PageTransitionType.leftToRight,
        alignment: Alignment.center,
        settings: settings,
      );
    case '/auth/request_forgot_password':
      return PageTransition(
        child: BlocProvider(create: (BuildContext context) => AuthenticationBloc(), child: const RequestForgotPasswordScreen()),
        type: PageTransitionType.rightToLeft,
        reverseType: PageTransitionType.leftToRight,
        alignment: Alignment.center,
        settings: settings,
      );
    case '/auth/forgot_password':
      return PageTransition(
        child: BlocProvider(create: (BuildContext context) => AuthenticationBloc(), child: const ResetPasswordScreen()),
        type: PageTransitionType.rightToLeft,
        alignment: Alignment.center,
        settings: settings,
      );
    case '/feeds':
      return PageTransition(child: const FeedsScreen(), type: PageTransitionType.fade, alignment: Alignment.center, settings: settings);
    case '/feed':
      return PageTransition(child: const FeedScreen(), type: PageTransitionType.fade, alignment: Alignment.center, settings: settings);
    case '/search':
      return PageTransition(child: const FeedsSearchScreen(), type: PageTransitionType.rightToLeft, alignment: Alignment.center, settings: settings);
    case '/chats':
      return PageTransition(child: const ChatScreen(), type: PageTransitionType.fade, alignment: Alignment.center, settings: settings);
    case '/education':
      return PageTransition(child: const EducationScreen(), type: PageTransitionType.fade, alignment: Alignment.center, settings: settings);
    case '/notes':
      return PageTransition(child: const NotesScreen(), type: PageTransitionType.fade, alignment: Alignment.center, settings: settings);
    case '/todos':
      return PageTransition(child: const TodosScreen(), type: PageTransitionType.fade, alignment: Alignment.center, settings: settings);
    case '/entertainment':
      return PageTransition(child: const PlayerScreen(), type: PageTransitionType.fade, alignment: Alignment.center, settings: settings);
    case '/profile':
      return PageTransition(child: const ProfileScreen(), type: PageTransitionType.fade, alignment: Alignment.center, settings: settings);
  }
  return null;
}
