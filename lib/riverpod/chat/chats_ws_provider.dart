import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kronk/utility/constants.dart';
import 'package:kronk/utility/exceptions.dart';
import 'package:kronk/utility/my_logger.dart';
import 'package:kronk/utility/storage.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

final chatsWSNotifierProvider = AutoDisposeAsyncNotifierProvider<ChatsWSNotifierNotifier, String>(ChatsWSNotifierNotifier.new);

class ChatsWSNotifierNotifier extends AutoDisposeAsyncNotifier<String> {
  Timer? _reconnectTimer;
  IOWebSocketChannel? _channel;
  final Duration _reconnectDelay = const Duration(seconds: 2);
  final Storage _storage = Storage();
  int _reconnectAttempts = 0;
  final int _maxReconnectAttempts = 5;

  @override
  Future<String> build() async {
    ref.onDispose(() {
      _channel?.sink.close();
      _reconnectTimer?.cancel();
    });

    _listenWebSocket();

    return '';
  }

  Future<void> _listenWebSocket() async {
    try {
      final accessToken = await _storage.getAccessTokenAsync();
      if (accessToken == null) {
        throw NoValidTokenException('No valid access token');
      }

      final url = '${constants.websocketEndpoint}/chats/home';
      _channel = IOWebSocketChannel.connect(Uri.parse(url), headers: {'Authorization': 'Bearer $accessToken'});

      // Listen for messages
      _channel?.stream.listen(
        (event) {
          try {
            myLogger.d('event: $event, type: ${event.runtimeType}');
            final decoded = jsonDecode(event as String);
            myLogger.d('decoded: $decoded, type: ${decoded.runtimeType}');
          } catch (error) {
            myLogger.d('error in _channel?.stream.listen in ChatsWSNotifierNotifier: $error, type: ${error.runtimeType}');
            AsyncError(error, StackTrace.current);
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
    myLogger.d('error in _handleWebSocketError in ChatsWSNotifierNotifier: $error, type: ${error.runtimeType}');
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
    myLogger.d('_scheduleReconnect');
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay, () {
      if (_reconnectAttempts < _maxReconnectAttempts) {
        _reconnectAttempts++;
        _listenWebSocket();
      }
    });
  }

  void clearNotifications() {
    state = const AsyncData('');
  }
}
