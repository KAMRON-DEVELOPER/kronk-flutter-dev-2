import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:kronk/firebase_options.dart';
import 'package:kronk/models/navbar_adapter.dart';
import 'package:kronk/models/navbar_model.dart';
import 'package:kronk/models/user_adapter.dart';
import 'package:kronk/models/user_model.dart';
import 'package:kronk/utility/storage.dart';
import 'package:visibility_detector/visibility_detector.dart';

Future<String> setup() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // Todo: preserve native splash during initialization
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await Hive.initFlutter();

  Hive.registerAdapter(UserAdapter(), override: true);
  Hive.registerAdapter(NavbarAdapter(), override: true);

  await Hive.openBox<UserModel>('userBox');
  await Hive.openBox<NavbarModel>('navbarBox');
  await Hive.openBox('settingsBox');

  // Todo: initialize firebase app
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final Storage storage = Storage();

  await storage.initializeNavbar();

  // Todo: remove native splash
  FlutterNativeSplash.remove();

  /// change configuration for all VisibilityDetector widgets
  VisibilityDetectorController.instance.updateInterval = const Duration(milliseconds: 200);

  return await storage.getRouteAsync();
}
