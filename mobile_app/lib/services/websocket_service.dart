import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_constants.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  final StreamController<Map<String, dynamic>> _messageController =
      StreamController<Map<String, dynamic>>.broadcast();
  bool _isConnected = false;
  bool _shouldReconnect = true;
  Timer? _reconnectTimer;
  String? _token;

  Stream<Map<String, dynamic>> get messages => _messageController.stream;
  bool get isConnected => _isConnected;

  WebSocketService();

  Future<void> connect() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      debugPrint("[WS] No token found, aborting WebSocket connection");
      return;
    }
    _token = token;
    _shouldReconnect = true;
    _connectInternal();
  }

  void _connectInternal() {
    if (_isConnected) return;
    if (_token == null) return;

    String base = ApiConstants.baseUrl;
    base = base.replaceAll('/api', '');
    if (base.startsWith('https://')) {
      base = base.replaceAll('https://', 'wss://');
    } else if (base.startsWith('http://')) {
      base = base.replaceAll('http://', 'ws://');
    }
    final wsUrl = '$base/ws/$_token';

    debugPrint("[WS] Connecting to $wsUrl...");
    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _isConnected = true;

      _channel!.stream.listen(
        (data) {
          try {
            final Map<String, dynamic> parsed = jsonDecode(data);
            debugPrint("[WS] Received: $parsed");
            _messageController.add(parsed);
          } catch (e) {
            debugPrint("[WS] Error parsing data: $e");
          }
        },
        onError: (err) {
          debugPrint("[WS] Error: $err");
          _handleDisconnect();
        },
        onDone: () {
          debugPrint("[WS] Connection closed by server");
          _handleDisconnect();
        },
      );
    } catch (e) {
      debugPrint("[WS] Connection error: $e");
      _handleDisconnect();
    }
  }

  void _handleDisconnect() {
    _isConnected = false;
    _channel = null;
    if (_shouldReconnect) {
      _reconnectTimer?.cancel();
      _reconnectTimer = Timer(const Duration(seconds: 5), () {
        debugPrint("[WS] Reconnecting...");
        _connectInternal();
      });
    }
  }

  void subscribeIncident(int incidentId) {
    if (!_isConnected || _channel == null) {
      debugPrint("[WS] Cannot subscribe, not connected");
      return;
    }
    final msg = jsonEncode({
      'type': 'subscribe_incident',
      'incident_id': incidentId,
    });
    _channel!.sink.add(msg);
    debugPrint("[WS] Sent subscription for incident #$incidentId");
  }

  void unsubscribeIncident(int incidentId) {
    if (!_isConnected || _channel == null) return;
    final msg = jsonEncode({
      'type': 'unsubscribe_incident',
      'incident_id': incidentId,
    });
    _channel!.sink.add(msg);
  }

  void disconnect() {
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _isConnected = false;
    debugPrint("[WS] Disconnected explicitly");
  }
}
