import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kronk/constants/enums.dart';
import 'package:kronk/utility/constants.dart';
import 'package:kronk/utility/exceptions.dart';
import 'package:kronk/utility/extensions.dart';
import 'package:kronk/utility/my_logger.dart';
import 'package:kronk/utility/storage.dart';
import 'package:web_socket_channel/io.dart';

final chatsWSNotifierProvider = AutoDisposeAsyncNotifierProvider<ChatsWSNotifierNotifier, Map<String, dynamic>>(ChatsWSNotifierNotifier.new);

class ChatsWSNotifierNotifier extends AutoDisposeAsyncNotifier<Map<String, dynamic>> {
  IOWebSocketChannel? _channel;
  late Storage _storage;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  Timer? _inactivityTimer;
  int _reconnectAttempts = 0;
  final int _maxReconnectAttempts = 5;
  DateTime? _lastActivityTime;
  static const _heartbeatInterval = Duration(seconds: 3600);
  static const _inactivityTimeout = Duration(seconds: 3601);
  final Map<String, Timer?> _typingTimers = {};
  final Duration _typingTimeout = const Duration(seconds: 5);
  final Set<String> _activeTypers = {};

  @override
  Future<Map<String, dynamic>> build() async {
    _storage = Storage();

    ref.onDispose(() async {
      myLogger.f('onDispose in chatsWSNotifierProvider');
      await _disposeResources();
    });

    _connectWebSocket();

    return {};
  }

  Future<void> _disposeResources() async {
    await _channel?.sink.close();
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();
    _inactivityTimer?.cancel();
    for (final timer in _typingTimers.values) {
      timer?.cancel();
    }
  }

  Future<void> _connectWebSocket() async {
    try {
      final accessToken = await _storage.getAccessTokenAsync();
      if (accessToken == null) throw NoValidTokenException('No valid access token');

      final url = '${constants.websocketEndpoint}/chats/home';
      _channel = IOWebSocketChannel.connect(Uri.parse(url), headers: {'Authorization': 'Bearer $accessToken'});

      _lastActivityTime = DateTime.now();
      _startHeartbeat();
      _startInactivityTimer();

      _channel?.stream.listen((event) => _handleIncomingMessage(event), onError: (error) => _handleWebSocketError(error), onDone: () => _handleDisconnection());
    } catch (e) {
      _handleWebSocketError(e);
    }
  }

  void _handleIncomingMessage(dynamic event) {
    try {
      // Update last activity time
      _lastActivityTime = DateTime.now();

      myLogger.w('event in _handleIncomingMessage: $event, type: ${event.runtimeType}');

      final decoded = jsonDecode(event);

      final type = decoded['type'];
      if (type == ChatEvent.heartbeatAck.name.toSnakeCase()) return;
      if (type == ChatEvent.heartbeat.name) _sendHeartbeat();
      myLogger.d('decoded: $decoded');

      state = AsyncData(decoded);
    } catch (error) {
      myLogger.d('Error handling message: $error');
    } finally {
      // Reset inactivity timer on any message
      _resetInactivityTimer();
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (timer) {
      if (_channel?.closeCode == null) _sendHeartbeat();
    });
  }

  /// *********************************** Message handlers ***********************************

  void _sendHeartbeat() {
    try {
      _channel?.sink.add(jsonEncode({'type': ChatEvent.heartbeat.name}));
    } catch (e) {
      myLogger.e('Error sending heartbeat: $e');
      _scheduleReconnect();
    }
  }

  void sendMessage({required String chatId, required String message}) {
    try {
      _channel?.sink.add(jsonEncode({'type': ChatEvent.sentMessage.name.toSnakeCase(), 'chat_id': chatId, 'message': message}));
    } catch (e) {
      myLogger.e('Error while sending message: $e');
      _scheduleReconnect();
    }
  }

  void handleTyping({required String chatId, required String text}) {
    final isTyping = _activeTypers.contains(chatId);

    if (text.isNotEmpty && !isTyping) {
      _sendTypingStart(chatId: chatId);
      _activeTypers.add(chatId);
    }

    // Cancel old timer if exists
    _typingTimers[chatId]?.cancel();

    if (text.isNotEmpty) {
      // Restart debounce timer
      _typingTimers[chatId] = Timer(_typingTimeout, () {
        _sendTypingStop(chatId: chatId);
        _activeTypers.remove(chatId);
        _typingTimers.remove(chatId);
      });
    } else {
      // User cleared input: stop typing immediately
      if (isTyping) {
        _sendTypingStop(chatId: chatId);
        _activeTypers.remove(chatId);
        _typingTimers.remove(chatId)?.cancel();
      }
    }
  }

  void _sendTypingStart({required String chatId}) {
    try {
      _channel?.sink.add(jsonEncode({'type': ChatEvent.typingStart.name.toSnakeCase(), 'chat_id': chatId}));
    } catch (e) {
      myLogger.e('Error while sending typing start event: $e');
      _scheduleReconnect();
    }
  }

  void _sendTypingStop({required String chatId}) {
    try {
      _channel?.sink.add(jsonEncode({'type': ChatEvent.typingStop.name.toSnakeCase(), 'chat_id': chatId}));
    } catch (e) {
      myLogger.e('Error while sending typing stop event: $e');
      _scheduleReconnect();
    }
  }

  /// *********************************** timer & handlers ***********************************

  void _handleWebSocketError(dynamic error) {
    myLogger.d('WebSocket error: $error');
    _scheduleReconnect();
  }

  void _handleDisconnection() {
    myLogger.d('WebSocket disconnected');
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _disposeResources();

    if (_reconnectAttempts >= _maxReconnectAttempts) {
      myLogger.d('Max reconnect attempts reached');
      return;
    }

    // Exponential backoff
    final delay = Duration(seconds: 2 * (_reconnectAttempts + 1));
    _reconnectAttempts++;

    myLogger.d('Reconnecting in ${delay.inSeconds}s (attempt $_reconnectAttempts)');

    _reconnectTimer = Timer(delay, () {
      _connectWebSocket();
    });
  }

  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(_inactivityTimeout, () {
      final now = DateTime.now();
      if (_lastActivityTime != null && now.difference(_lastActivityTime!) > _inactivityTimeout) {
        myLogger.d('Inactivity timeout, reconnecting');
        _scheduleReconnect();
      }
    });
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _startInactivityTimer();
  }
}
