import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kronk/models/chat_tile_model.dart';
import 'package:kronk/services/api_service/chat_service.dart';
import 'package:kronk/utility/my_logger.dart';
import 'package:kronk/utility/storage.dart';

final chatTileNotifierProvider = AsyncNotifierProvider<ChatTileNotifier, List<ChatTileModel>>(ChatTileNotifier.new);

class ChatTileNotifier extends AsyncNotifier<List<ChatTileModel>> {
  final ChatService _chatService = ChatService();
  final Connectivity _connectivity = Connectivity();
  final Storage _storage = Storage();
  int _start = 0;
  int _end = 10;

  @override
  Future<List<ChatTileModel>> build() async {
    try {
      final bool isOnlineAndAuthenticated = await _isOnlineAndAuthenticated();
      if (!isOnlineAndAuthenticated) {
        return [];
      }
      return await _fetchChatTiles();
    } catch (error) {
      state = AsyncValue.error(error, StackTrace.current);
      return [];
    }
  }

  Future<List<ChatTileModel>> _fetchChatTiles() async {
    try {
      final List<ChatTileModel> chatTiles = await _chatService.fetchChatTiles();
      myLogger.d('chatTiles in _fetchChatTiles in chatTileNotifierProvider: $chatTiles');
      return chatTiles.isEmpty ? [] : chatTiles;
    } catch (error) {
      state = AsyncValue.error(error, StackTrace.current);
      return [];
    }
  }

  Future<List<ChatTileModel>> refresh() async {
    state = const AsyncValue.loading();
    final Future<List<ChatTileModel>> chatTiles = _fetchChatTiles();
    state = await AsyncValue.guard(() => chatTiles);
    return chatTiles;
  }

  Future<bool> _isOnlineAndAuthenticated() async {
    final connectivity = await _connectivity.checkConnectivity();
    final isOnline = connectivity.any((ConnectivityResult result) => result != ConnectivityResult.none);

    final accessToken = await _storage.getAccessTokenAsync();
    final bool isAuthenticated = accessToken != null ? true : false;

    return isOnline && isAuthenticated;
  }

  Future<void> loadMore() async {
    _start = _end + 1;
    _end = _start + 10;

    final newFeeds = await _chatService.fetchChatTiles(start: _start, end: _end);

    state = state.whenData((existing) => [...existing, ...newFeeds]);
  }
}
