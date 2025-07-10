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

final chatsWSNotifierProvider = AutoDisposeAsyncNotifierProvider<ChatsWSNotifierNotifier, String>(ChatsWSNotifierNotifier.new);

class ChatsWSNotifierNotifier extends AutoDisposeAsyncNotifier<String> {
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

  @override
  Future<String> build() async {
    _storage = Storage();

    ref.onDispose(() async {
      myLogger.f('onDispose in chatsWSNotifierProvider');
      await _disposeResources();
    });

    _connectWebSocket();

    return '';
  }

  Future<void> _disposeResources() async {
    await _channel?.sink.close();
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();
    _inactivityTimer?.cancel();
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

      final decoded = jsonDecode(event);

      final String type = decoded['type'];
      if (type == ChatEvent.heartbeatAck.name.toSnakeCase()) return;
      if (type == 'heartbeat') _sendHeartbeat();
      myLogger.d('decoded: $decoded');
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

  void _sendHeartbeat() {
    try {
      _channel?.sink.add(jsonEncode({'type': 'heartbeat'}));
    } catch (e) {
      myLogger.e('Error sending heartbeat: $e');
      _scheduleReconnect();
    }
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
}
