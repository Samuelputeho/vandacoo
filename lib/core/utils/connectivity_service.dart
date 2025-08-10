import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _connectionStatusController = StreamController<bool>.broadcast();
  
  Stream<bool> get connectionStatus => _connectionStatusController.stream;
  bool _isConnected = true;

  bool get isConnected => _isConnected;

  Future<void> initialize() async {
    // Check initial connectivity status
    await _checkConnectivityStatus();
    
    // Listen to connectivity changes
    _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      _updateConnectionStatus(results);
    });
  }

  Future<void> _checkConnectivityStatus() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateConnectionStatus(results);
    } catch (e) {
      // If we can't check connectivity, assume we're disconnected
      _updateConnectionStatus([ConnectivityResult.none]);
    }
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final wasConnected = _isConnected;
    _isConnected = results.any((result) => result != ConnectivityResult.none);
    
    // Only emit if the status actually changed
    if (wasConnected != _isConnected) {
      _connectionStatusController.add(_isConnected);
    }
  }

  Future<bool> checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateConnectionStatus(results);
      return _isConnected;
    } catch (e) {
      _updateConnectionStatus([ConnectivityResult.none]);
      return false;
    }
  }

  void dispose() {
    _connectionStatusController.close();
  }
}
