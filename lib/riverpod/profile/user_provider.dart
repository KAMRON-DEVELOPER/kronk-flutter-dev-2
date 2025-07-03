import 'dart:developer';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kronk/models/user_model.dart';
import 'package:kronk/services/api_service/user_service.dart';
import 'package:kronk/utility/my_logger.dart';
import 'package:kronk/utility/storage.dart';

final profileNotifierProvider = AsyncNotifierProvider<ProfileNotifier, UserModel>(ProfileNotifier.new);

class ProfileNotifier extends AsyncNotifier<UserModel> {
  late Connectivity _connectivity;
  late Storage _storage;
  late UserService _userService;

  @override
  Future<UserModel> build() async {
    _connectivity = Connectivity();
    _storage = Storage();
    _userService = UserService();

    try {
      return await _fetchProfile();
    } catch (error, stackTrace) {
      myLogger.e('Error in build: $error');
      rethrow;
    }
  }

  Future<UserModel> refresh() async {
    state = const AsyncValue.loading();

    try {
      final UserModel user = await _fetchProfile();
      state = await AsyncValue.guard(() async => user);
      return user;
    } catch (error) {
      myLogger.e('Error in refresh: $error');
      rethrow;
    }
  }

  Future<UserModel> _fetchProfile() async {
    try {
      List<ConnectivityResult> initialResults = await _connectivity.checkConnectivity();
      bool isOnline = initialResults.any((ConnectivityResult result) => result != ConnectivityResult.none);

      // await Future.delayed(const Duration(seconds: 0));

      if (!isOnline) {
        final UserModel? user = _storage.getUser();
        if (user == null) throw Exception('You are not authenticated');
        return user;
      }
      final UserModel user = await _userService.fetchGetProfile();

      await _storage.setUserAsync(user: user);
      return user;
    } catch (error, stacktrace) {
      myLogger.e('Unexpected error in _fetchProfile: $error \nStacktrace: $stacktrace');
      rethrow;
    }
  }

  Future<void> updateUser({required Map<String, dynamic> profileMap}) async {}

  Future<int?> deleteAccount() async {
    final int? statusCode = await _userService.fetchDeleteProfile();
    log('🔨 statusCode: $statusCode');

    if (statusCode == 204) {
      final GoogleSignIn googleSignIn = GoogleSignIn.instance;
      final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
      User? firebaseUser = firebaseAuth.currentUser;

      try {
        final GoogleSignInAccount googleSignInAccount = await googleSignIn.authenticate();

        final GoogleSignInAuthentication googleAuth = googleSignInAccount.authentication;
        AuthCredential authCredential = GoogleAuthProvider.credential(idToken: googleAuth.idToken);

        await firebaseUser?.reauthenticateWithCredential(authCredential);
      } catch (e) {
        log('💀 Error during user deletion: $e');
        return null;
      }

      await firebaseUser?.delete();
      return statusCode;
    }
    return null;
  }

  Future<void> logoutUser() async {
    final GoogleSignIn googleSignIn = GoogleSignIn.instance;
    final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
    await googleSignIn.signOut();
    await firebaseAuth.signOut();
    log('🔨 googleSignInAccount in logoutUser');
  }
}
