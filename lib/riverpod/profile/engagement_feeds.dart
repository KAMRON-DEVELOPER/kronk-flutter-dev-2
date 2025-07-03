import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kronk/constants/enums.dart';
import 'package:kronk/models/feed_model.dart';
import 'package:kronk/services/api_service/feed_service.dart';
import 'package:kronk/utility/storage.dart';

final engagementFeedNotifierProvider = AsyncNotifierProviderFamily<EngagementFeedNotifier, List<FeedModel>, EngagementType>(EngagementFeedNotifier.new);

class EngagementFeedNotifier extends FamilyAsyncNotifier<List<FeedModel>, EngagementType> {
  final FeedService _feedService = FeedService();
  final Connectivity _connectivity = Connectivity();
  final Storage _storage = Storage();
  int _end = 9;
  int _realEnd = 10;
  bool _isLoadingMore = false;

  @override
  Future<List<FeedModel>> build(EngagementType engagementType) async {
    _end = 0;
    _realEnd = 9;
    try {
      final bool isOnlineAndAuthenticated = await _isOnlineAndAuthenticated();
      if (!isOnlineAndAuthenticated) {
        return [];
      }
      return await _fetchEngagementFeeds(engagementType: engagementType);
    } catch (error) {
      rethrow;
    }
  }

  Future<List<FeedModel>> _fetchEngagementFeeds({required EngagementType engagementType}) async {
    try {
      final results = await _feedService.fetchEngagementFeeds(engagementType: engagementType);
      _end = results.item2 - 1;
      return results.item1;
    } catch (error) {
      rethrow;
    }
  }

  Future<List<FeedModel>> refresh({required EngagementType engagementType}) async {
    state = const AsyncValue.loading();
    _end = 0;
    _realEnd = 10;
    _isLoadingMore = false;
    try {
      final Future<List<FeedModel>> feeds = _fetchEngagementFeeds(engagementType: engagementType);
      state = await AsyncValue.guard(() => feeds);
      return feeds;
    } catch (error) {
      rethrow;
    }
  }

  Future<bool> _isOnlineAndAuthenticated() async {
    final connectivity = await _connectivity.checkConnectivity();
    final isOnline = connectivity.any((ConnectivityResult result) => result != ConnectivityResult.none);

    final accessToken = await _storage.getAccessTokenAsync();
    final bool isAuthenticated = accessToken != null ? true : false;

    return isOnline && isAuthenticated;
  }

  Future<void> loadMore({required EngagementType engagementType}) async {
    if (_isLoadingMore || _end >= _realEnd) return;
    _isLoadingMore = true;

    try {
      final nextStart = _end + 1;
      int nextEnd = min(_realEnd, _end + 10);

      final results = await _feedService.fetchEngagementFeeds(engagementType: engagementType, start: nextStart, end: nextEnd);

      if (results.item1.isEmpty) return;

      _end = nextEnd;
      _realEnd = results.item2 - 1;

      state = AsyncValue.data([...?state.value, ...results.item1]);
    } finally {
      _isLoadingMore = false;
    }
  }
}
