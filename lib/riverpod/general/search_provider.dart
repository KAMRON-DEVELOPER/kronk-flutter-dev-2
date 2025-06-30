import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kronk/models/feed_model.dart';
import 'package:kronk/models/user_model.dart';
import 'package:kronk/services/api_service/feed_service.dart';
import 'package:kronk/services/api_service/user_service.dart';

final searchQueryStateProvider = StateProvider<String>((ref) => '');

// -------------------- USER SEARCH --------------------

final userSearchNotifierProvider = AsyncNotifierProvider<UserSearchNotifier, List<UserSearchModel>>(() => UserSearchNotifier());

class UserSearchNotifier extends AsyncNotifier<List<UserSearchModel>> {
  final Connectivity _connectivity = Connectivity();
  final UserService _userService = UserService();

  @override
  FutureOr<List<UserSearchModel>> build() {
    return [];
  }

  Future<void> fetchSearchQueryResult() async {
    final String searchQuery = ref.watch(searchQueryStateProvider);
    if (searchQuery.trim().isEmpty) return;

    if (await _checkConnectivityAndAuth()) {
      final List<UserSearchModel> userSearchResultList = await _userService.fetchUserSearch(query: searchQuery);
      state = AsyncData(userSearchResultList);
    } else {
      throw Exception('You are not authenticated or you are disconnected from the internet.');
    }
  }

  Future<void> toggleFollow({required String userId}) async {
    final currentState = state;

    if (currentState is AsyncData<List<UserSearchModel>>) {
      final users = currentState.value;

      final updatedUsers = users.map((user) {
        if (user.id == userId) {
          final isNowFollowing = !user.isFollowing;
          return user.copyWith(isFollowing: isNowFollowing, followersCount: isNowFollowing ? user.followersCount + 1 : user.followersCount - 1);
        }
        return user;
      }).toList();

      // Optimistically update the UI
      state = AsyncData(updatedUsers);

      // Perform the actual follow/unfollow API call (fire-and-forget)
      final targetUser = users.firstWhere((user) => user.id == userId);
      if (!targetUser.isFollowing) {
        await _userService.fetchFollow(followingId: userId);
      } else {
        await _userService.fetchUnfollow(followingId: userId);
      }
    }
  }

  Future<bool> _checkConnectivityAndAuth() async {
    final connectivity = await _connectivity.checkConnectivity();
    final isOnline = connectivity.any((ConnectivityResult result) => result != ConnectivityResult.none);
    return isOnline;
  }
}

// -------------------- FEED SEARCH --------------------

final feedSearchNotifierProvider = AsyncNotifierProvider<FeedSearchNotifier, List<FeedModel>>(FeedSearchNotifier.new);

class FeedSearchNotifier extends AsyncNotifier<List<FeedModel>> {
  final Connectivity _connectivity = Connectivity();
  final FeedService _feedService = FeedService();

  @override
  FutureOr<List<FeedModel>> build() {
    return [];
  }

  Future<void> fetchSearchQueryResult() async {
    final String searchQuery = ref.watch(searchQueryStateProvider);
    if (searchQuery.trim().isEmpty) return;
    if (await _checkConnectivityAndAuth()) {
      final List<FeedModel> feedSearchResultList = await _feedService.fetchFeedSearch(query: searchQuery);
      state = AsyncData(feedSearchResultList);
    } else {
      throw Exception('You are not authenticated or you are disconnected from the internet.');
    }
  }

  Future<bool> _checkConnectivityAndAuth() async {
    final connectivity = await _connectivity.checkConnectivity();
    final isOnline = connectivity.any((ConnectivityResult result) => result != ConnectivityResult.none);
    return isOnline;
  }
}
