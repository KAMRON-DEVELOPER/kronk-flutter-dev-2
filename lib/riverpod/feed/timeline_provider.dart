import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kronk/constants/enums.dart';
import 'package:kronk/models/feed_model.dart';
import 'package:kronk/models/user_model.dart';
import 'package:kronk/services/api_service/feed_service.dart';
import 'package:kronk/utility/my_logger.dart';
import 'package:kronk/utility/storage.dart';
import 'package:uuid/uuid.dart';

final timelineNotifierProvider = AsyncNotifierProviderFamily<TimelineNotifier, List<FeedModel>, TimelineType>(() => TimelineNotifier());

class TimelineNotifier extends FamilyAsyncNotifier<List<FeedModel>, TimelineType> {
  final FeedService _feedService = FeedService();
  final Connectivity _connectivity = Connectivity();
  final Storage _storage = Storage();
  int _start = 0;
  int _end = 10;

  @override
  Future<List<FeedModel>> build(TimelineType timelineType) async {
    try {
      final bool isOnlineAndAuthenticated = await _isOnlineAndAuthenticated();
      if (!isOnlineAndAuthenticated) {
        return [];
      }
      return await _fetchTimeline(timelineType: timelineType);
    } catch (error) {
      state = AsyncValue.error(error, StackTrace.current);
      return [];
    }
  }

  Future<List<FeedModel>> _fetchTimeline({required TimelineType timelineType}) async {
    try {
      final List<FeedModel> feeds = await _feedService.fetchTimeline(timelineType: timelineType);
      myLogger.d('feeds in _fetchTimeline in timelineNotifierProvider: $feeds');
      return feeds.isEmpty ? [] : feeds;
    } catch (error) {
      state = AsyncValue.error(error, StackTrace.current);
      return [];
    }
  }

  Future<List<FeedModel>> refresh({required TimelineType timelineType}) async {
    state = const AsyncValue.loading();
    final Future<List<FeedModel>> feeds = _fetchTimeline(timelineType: timelineType);
    state = await AsyncValue.guard(() => feeds);
    return feeds;
  }

  Future<bool> _isOnlineAndAuthenticated() async {
    final connectivity = await _connectivity.checkConnectivity();
    final isOnline = connectivity.any((ConnectivityResult result) => result != ConnectivityResult.none);

    final accessToken = await _storage.getAccessTokenAsync();
    final bool isAuthenticated = accessToken != null ? true : false;

    return isOnline && isAuthenticated;
  }

  void createFeed() {
    final UserModel? author = _storage.getUser();
    if (author == null) {
      state = AsyncValue.error('User not authenticated', StackTrace.current);
      return;
    }

    final placeholder = FeedModel(
      id: const Uuid().v4(),
      createdAt: DateTime.now(),
      author: AuthorModel(id: author.id, name: author.name, username: author.username, avatarUrl: author.avatarUrl),
      body: null,
      feedModeEnum: FeedModeEnum.create,
      imageUrls: [],
      imageFiles: [],
      engagement: const EngagementModel(),
    );

    state = AsyncValue.data([placeholder, ...state.valueOrNull ?? []]);
  }

  Future<void> loadMore({required TimelineType timelineType}) async {
    _start = _end + 1;
    _end = _start + 10;

    final newFeeds = await _feedService.fetchTimeline(timelineType: timelineType, start: _start, end: _end);

    state = state.whenData((existing) => [...existing, ...newFeeds]);
  }
}

/// ------------------------------------------ Comment --------------------------------------- ///

final commentNotifierProvider = AsyncNotifierProviderFamily<CommentNotifier, List<FeedModel>, String?>(() => CommentNotifier());

class CommentNotifier extends FamilyAsyncNotifier<List<FeedModel>, String?> {
  final FeedService _feedService = FeedService();
  final Connectivity _connectivity = Connectivity();
  final Storage _storage = Storage();
  int _start = 0;
  int _end = 10;

  @override
  Future<List<FeedModel>> build(String? parentId) async {
    try {
      final bool isOnlineAndAuthenticated = await _isOnlineAndAuthenticated();
      if (!isOnlineAndAuthenticated) {
        return [];
      }
      return await _fetchComments(parentId: parentId);
    } catch (error) {
      state = AsyncValue.error(error, StackTrace.current);
      return [];
    }
  }

  Future<List<FeedModel>> _fetchComments({required String? parentId}) async {
    try {
      final List<FeedModel> feeds = await _feedService.fetchComments(parentId: parentId);
      myLogger.d('feeds in _fetchComments in commentNotifierProvider: $feeds');
      return feeds.isEmpty ? [] : feeds;
    } catch (error) {
      state = AsyncValue.error(error, StackTrace.current);
      return [];
    }
  }

  Future<List<FeedModel>> refresh({required String? parentId}) async {
    state = const AsyncValue.loading();
    final Future<List<FeedModel>> feeds = _fetchComments(parentId: parentId);
    state = await AsyncValue.guard(() => feeds);
    return feeds;
  }

  Future<bool> _isOnlineAndAuthenticated() async {
    final connectivity = await _connectivity.checkConnectivity();
    final isOnline = connectivity.any((ConnectivityResult result) => result != ConnectivityResult.none);

    final accessToken = await _storage.getAccessTokenAsync();
    final bool isAuthenticated = accessToken != null ? true : false;

    return isOnline && isAuthenticated;
  }

  void createComment() {
    final UserModel? author = _storage.getUser();
    if (author == null) {
      state = AsyncValue.error('User not authenticated', StackTrace.current);
      return;
    }

    final placeholder = FeedModel(
      id: const Uuid().v4(),
      createdAt: DateTime.now(),
      author: AuthorModel(id: author.id, name: author.name, username: author.username, avatarUrl: author.avatarUrl),
      body: null,
      feedModeEnum: FeedModeEnum.create,
      imageUrls: [],
      imageFiles: [],
      engagement: const EngagementModel(),
    );

    state = AsyncValue.data([placeholder, ...state.valueOrNull ?? []]);
  }

  Future<void> loadMore({required TimelineType timelineType}) async {
    _start = _end + 1;
    _end = _start + 10;

    final newFeeds = await _feedService.fetchTimeline(timelineType: timelineType, start: _start, end: _end);

    state = state.whenData((existing) => [...existing, ...newFeeds]);
  }
}

/// ------------------------------------------ Post Notification ------------------------------------ ///
