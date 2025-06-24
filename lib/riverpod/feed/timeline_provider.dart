import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kronk/constants/enums.dart';
import 'package:kronk/models/feed_model.dart';
import 'package:kronk/models/user_model.dart';
import 'package:kronk/services/api_service/feed_service.dart';
import 'package:kronk/utility/constants.dart';
import 'package:kronk/utility/exceptions.dart';
import 'package:kronk/utility/my_logger.dart';
import 'package:kronk/utility/storage.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

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

  Future<void> createFeed() async {
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

final scrollPositionProvider = StateProvider.autoDispose<double>((ref) => 0.0);

final feedNotificationStateProvider = AutoDisposeAsyncNotifierProvider<FeedNotificationStateNotifier, List<String>>(FeedNotificationStateNotifier.new);

class FeedNotificationStateNotifier extends AutoDisposeAsyncNotifier<List<String>> {
  Timer? _reconnectTimer;
  IOWebSocketChannel? _channel;
  final Duration _reconnectDelay = const Duration(seconds: 2);
  final Storage _storage = Storage();
  int _reconnectAttempts = 0;
  final int _maxReconnectAttempts = 5;

  @override
  Future<List<String>> build() async {
    ref.onDispose(() {
      _channel?.sink.close();
      _reconnectTimer?.cancel();
    });

    _listenWebSocket();

    return [];
  }

  Future<void> _listenWebSocket() async {
    try {
      final accessToken = await _storage.getAccessTokenAsync();
      if (accessToken == null) {
        throw NoValidTokenException('No valid access token');
      }

      final url = '${constants.websocketEndpoint}/feeds/timeline/home';
      _channel = IOWebSocketChannel.connect(Uri.parse(url), headers: {'Authorization': 'Bearer $accessToken'});

      // Listen for messages
      _channel?.stream.listen(
        (event) {
          try {
            final decoded = jsonDecode(event as String);
            final avatarUrl = decoded['avatar_url'] as String?;
            if (avatarUrl != null) {
              final currentList = state.valueOrNull ?? [];
              state = AsyncData([avatarUrl, ...currentList].take(3).toList());
            }
          } catch (e) {
            // Handle message decoding errors
          }
        },
        onError: (error) => _handleWebSocketError(error),
        onDone: () => _scheduleReconnect(),
      );
    } catch (e) {
      _handleWebSocketError(e);
    }
  }

  void _handleWebSocketError(dynamic error) {
    if (error is WebSocketChannelException) {
      if (error.message!.contains('403')) {
        state = AsyncError(NoValidTokenException('Token expired'), StackTrace.current);
        return;
      }
    }

    // Exponential backoff for reconnections
    final delay = Duration(seconds: _reconnectDelay.inSeconds * (_reconnectAttempts + 1));
    _reconnectTimer = Timer(delay, () {
      if (_reconnectAttempts < _maxReconnectAttempts) {
        _reconnectAttempts++;
        _listenWebSocket();
      }
    });
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay, () {
      if (_reconnectAttempts < _maxReconnectAttempts) {
        _reconnectAttempts++;
        _listenWebSocket();
      }
    });
  }

  void clearNotifications() {
    state = const AsyncData([]);
  }
}
