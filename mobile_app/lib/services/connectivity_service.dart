import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _controller = StreamController<bool>.broadcast();
  bool _isOnline = true;

  ConnectivityService._internal() {
    _init();
  }

  bool get isOnline => _isOnline;
  Stream<bool> get isOnlineStream => _controller.stream;

  Future<void> _init() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateStatus(results);
    } catch (e) {
      // Fallback
      _isOnline = true;
    }
    _connectivity.onConnectivityChanged.listen(_updateStatus);
  }

  void _updateStatus(List<ConnectivityResult> results) {
    // In connectivity_plus v6+, the stream emits a List<ConnectivityResult>.
    // If it is empty or only contains ConnectivityResult.none, we are offline.
    final hasConnection = results.isNotEmpty && !results.contains(ConnectivityResult.none);
    if (_isOnline != hasConnection) {
      _isOnline = hasConnection;
      _controller.add(_isOnline);
      print("[ConnectivityService] Network status changed: $_isOnline");
    }
  }

  void dispose() {
    _controller.close();
  }
}
