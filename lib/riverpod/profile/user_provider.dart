import 'dart:developer';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kronk/constants/enums.dart';
import 'package:kronk/models/user_model.dart';
import 'package:kronk/services/api_service/user_service.dart';
import 'package:kronk/utility/my_logger.dart';
import 'package:kronk/utility/storage.dart';

/// profileStateProvider
final profileStateProvider = StateNotifierProvider<ProfileStateNotifier, ProfileStateEnum>((ref) => ProfileStateNotifier());

class ProfileStateNotifier extends StateNotifier<ProfileStateEnum> {
  ProfileStateNotifier() : super(ProfileStateEnum.view);

  void toggleView() => state = state == ProfileStateEnum.view ? ProfileStateEnum.edit : ProfileStateEnum.view;
}

/// profileProvider
final profileProvider = AsyncNotifierProvider<ProfileNotifier, UserModel?>(() => ProfileNotifier());

class ProfileNotifier extends AsyncNotifier<UserModel?> {
  final Connectivity _connectivity = Connectivity();
  final Storage _storage = Storage();
  final UserService _userService = UserService();

  @override
  Future<UserModel?> build() async => _fetchProfile();

  Future<void> fetchProfile() async {
    final user = await _fetchProfile();
    state = AsyncValue.data(user);
  }

  Future<UserModel?> _fetchProfile() async {
    try {
      // await Future.delayed(const Duration(seconds: 0));

      List<ConnectivityResult> initialResults = await _connectivity.checkConnectivity();
      bool isOnline = initialResults.any((ConnectivityResult result) => result != ConnectivityResult.none);

      if (isOnline) {
        Response? response = await _userService.fetchGetProfile();

        try {
          myLogger.d("response.data[followers_count] type: ${response.data['followers_count'].runtimeType}");
          final UserModel userModel = UserModel.fromJson(response.data);
          myLogger.d('2. userModel.username: ${userModel.username}');
          await _storage.setUserAsync(user: userModel);
          return userModel;
        } catch (e, stacktrace) {
          myLogger.e('💀 Error parsing UserModel: $e \nStacktrace: $stacktrace');
          return null;
        }
      }
      return null;
    } catch (e, stacktrace) {
      myLogger.e('💀 Unexpected error in _fetchProfile: $e \nStacktrace: $stacktrace');
      return null;
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
