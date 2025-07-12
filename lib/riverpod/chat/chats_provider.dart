import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kronk/models/chat_model.dart';
import 'package:kronk/services/api_service/chat_service.dart';
import 'package:kronk/utility/my_logger.dart';
import 'package:kronk/utility/storage.dart';

final chatsNotifierProvider = AsyncNotifierProvider<ChatsNotifier, List<ChatModel>>(ChatsNotifier.new);

class ChatsNotifier extends AsyncNotifier<List<ChatModel>> {
  late ChatService _chatService;
  late Connectivity _connectivity;
  late Storage _storage;
  int _start = 0;
  int _end = 10;

  @override
  Future<List<ChatModel>> build() async {
    _chatService = ChatService();
    _connectivity = Connectivity();
    _storage = Storage();

    ref.onDispose(() => myLogger.f('onDispose chatsNotifierProvider'));

    try {
      final bool isOnlineAndAuthenticated = await _isOnlineAndAuthenticated();
      if (!isOnlineAndAuthenticated) return [];
      return await _getChats();
    } catch (error) {
      state = AsyncValue.error(error, StackTrace.current);
      return [];
    }
  }

  Future<List<ChatModel>> _getChats() async {
    try {
      final List<ChatModel> chats = await _chatService.getChats();
      return chats;
    } catch (error) {
      state = AsyncValue.error(error, StackTrace.current);
      return [];
    }
  }

  Future<ChatModel> createChatMessage({required String message}) async {
    try {
      final ChatModel chat = await _chatService.createChatMessage(message: message);
      state = state.whenData((List<ChatModel> values) => [...values, chat]);
      return chat;
    } catch (error) {
      state = AsyncValue.error(error, StackTrace.current);
      rethrow;
    }
  }

  Future<List<ChatModel>> refresh() async {
    state = const AsyncValue.loading();
    final Future<List<ChatModel>> chats = _getChats();
    state = await AsyncValue.guard(() => chats);
    return chats;
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

    final newFeeds = await _chatService.getChats(start: _start, end: _end);

    state = state.whenData((existing) => [...existing, ...newFeeds]);
  }
}
