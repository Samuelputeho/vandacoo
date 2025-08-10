import 'package:flutter/material.dart';
import 'package:vandacoo/core/utils/connectivity_service.dart';

class NetworkStatusWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback? onRetry;
  final bool showNetworkIndicator;

  const NetworkStatusWidget({
    super.key,
    required this.child,
    this.onRetry,
    this.showNetworkIndicator = true,
  });

  @override
  State<NetworkStatusWidget> createState() => _NetworkStatusWidgetState();
}

class _NetworkStatusWidgetState extends State<NetworkStatusWidget> {
  late ConnectivityService _connectivityService;
  bool _isConnected = true;

  @override
  void initState() {
    super.initState();
    _connectivityService = ConnectivityService();
    _isConnected = _connectivityService.isConnected;

    _connectivityService.connectionStatus.listen((isConnected) {
      if (mounted) {
        setState(() {
          _isConnected = isConnected;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isConnected && widget.showNetworkIndicator) {
      return Column(
        children: [
          // Network status indicator
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: Colors.orange.shade100,
            child: Row(
              children: [
                Icon(
                  Icons.wifi_off,
                  color: Colors.orange.shade800,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'No internet connection',
                    style: TextStyle(
                      color: Colors.orange.shade800,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (widget.onRetry != null)
                  TextButton(
                    onPressed: widget.onRetry,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                    ),
                    child: Text(
                      'Retry',
                      style: TextStyle(
                        color: Colors.orange.shade800,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Main content
          Expanded(child: widget.child),
        ],
      );
    }

    return widget.child;
  }
}

class NetworkAwareScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final VoidCallback? onRetry;

  const NetworkAwareScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return NetworkStatusWidget(
      onRetry: onRetry,
      child: Scaffold(
        appBar: appBar,
        body: body,
        bottomNavigationBar: bottomNavigationBar,
        floatingActionButton: floatingActionButton,
      ),
    );
  }
}
