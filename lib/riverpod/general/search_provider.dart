import 'dart:async';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kronk/models/feed_model.dart';
import 'package:kronk/models/user_model.dart';
import 'package:kronk/services/api_service/feed_service.dart';
import 'package:kronk/services/api_service/user_service.dart';

// -------------------- USER SEARCH --------------------

final userSearchNotifierProvider = AsyncNotifierProvider<UserSearchNotifier, List<UserModel>>(() => UserSearchNotifier());

class UserSearchNotifier extends AsyncNotifier<List<UserModel>> {
  final Connectivity _connectivity = Connectivity();
  final UserService _userService = UserService();
  int _end = 9;
  int _realEnd = 10;
  bool _isLoadingMore = false;
  String _searchQuery = '';

  @override
  FutureOr<List<UserModel>> build() {
    _end = 9;
    _realEnd = 10;
    _isLoadingMore = false;
    _searchQuery = '';
    return [];
  }

  Future<void> fetchSearchQueryResult({required String searchQuery}) async {
    if (searchQuery.trim().isEmpty) return;

    if (await _checkConnectivityAndAuth()) {
      final results = await _userService.fetchUserSearch(query: searchQuery);
      _realEnd = results.item2 - 1;
      state = AsyncData(results.item1);
    } else {
      AsyncError('You are not authenticated or you are disconnected from the internet.', StackTrace.current);
    }
  }

  Future<void> toggleFollow({required String userId}) async {
    final currentState = state;

    if (currentState is AsyncData<List<UserModel>>) {
      final users = currentState.value;

      final updatedUsers = users.map((user) {
        if (user.id == userId) {
          final isNowFollowing = !user.isFollowing!;
          return user.copyWith(isFollowing: isNowFollowing, followersCount: isNowFollowing ? user.followersCount + 1 : user.followersCount - 1);
        }
        return user;
      }).toList();

      // Optimistically update the UI
      state = AsyncData(updatedUsers);

      // Perform the actual follow/unfollow API call (fire-and-forget)
      final targetUser = users.firstWhere((user) => user.id == userId);
      if (!targetUser.isFollowing!) {
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

  Future<void> loadMore() async {
    if (_isLoadingMore || _end >= _realEnd || _searchQuery.isEmpty) return;
    _isLoadingMore = true;

    try {
      final nextStart = _end + 1;
      int nextEnd = min(_realEnd, _end + 10);

      final results = await _userService.fetchUserSearch(query: _searchQuery, start: nextStart, end: nextEnd);

      if (results.item1.isEmpty) return;

      _end = nextEnd;
      _realEnd = results.item2 - 1;

      state = AsyncValue.data([...?state.value, ...results.item1]);
    } finally {
      _isLoadingMore = false;
    }
  }
}

// -------------------- FEED SEARCH --------------------

final feedSearchNotifierProvider = AsyncNotifierProvider<FeedSearchNotifier, List<FeedModel>>(FeedSearchNotifier.new);

class FeedSearchNotifier extends AsyncNotifier<List<FeedModel>> {
  final Connectivity _connectivity = Connectivity();
  final FeedService _feedService = FeedService();
  int _end = 9;
  int _realEnd = 10;
  bool _isLoadingMore = false;
  String _searchQuery = '';

  @override
  FutureOr<List<FeedModel>> build() {
    _end = 9;
    _realEnd = 10;
    _isLoadingMore = false;
    _searchQuery = '';
    return [];
  }

  Future<void> fetchSearchQueryResult({required String searchQuery}) async {
    if (searchQuery.trim().isEmpty) return;
    _searchQuery = searchQuery;
    if (await _checkConnectivityAndAuth()) {
      final results = await _feedService.fetchFeedSearch(query: searchQuery);
      _realEnd = results.item2 - 1;
      state = AsyncData(results.item1);
    } else {
      state = AsyncError('You are not authenticated or you are disconnected from the internet.', StackTrace.current);
    }
  }

  Future<bool> _checkConnectivityAndAuth() async {
    final connectivity = await _connectivity.checkConnectivity();
    final isOnline = connectivity.any((ConnectivityResult result) => result != ConnectivityResult.none);
    return isOnline;
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || _end >= _realEnd || _searchQuery.isEmpty) return;
    _isLoadingMore = true;

    try {
      final nextStart = _end + 1;
      int nextEnd = min(_realEnd, _end + 10);

      final results = await _feedService.fetchFeedSearch(query: _searchQuery, start: nextStart, end: nextEnd);

      if (results.item1.isEmpty) return;

      _end = nextEnd;
      _realEnd = results.item2 - 1;

      state = AsyncValue.data([...?state.value, ...results.item1]);
    } finally {
      _isLoadingMore = false;
    }
  }
}
