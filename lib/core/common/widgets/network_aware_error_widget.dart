import 'package:flutter/material.dart';
import 'package:vandacoo/core/common/widgets/error_utils.dart';
import 'package:vandacoo/core/common/widgets/network_error_widget.dart';
import 'package:vandacoo/core/utils/connectivity_service.dart';

class NetworkAwareErrorWidget extends StatefulWidget {
  final String errorMessage;
  final VoidCallback? onRetry;
  final String? title;
  final String? customMessage;

  const NetworkAwareErrorWidget({
    super.key,
    required this.errorMessage,
    this.onRetry,
    this.title,
    this.customMessage,
  });

  @override
  State<NetworkAwareErrorWidget> createState() => _NetworkAwareErrorWidgetState();
}

class _NetworkAwareErrorWidgetState extends State<NetworkAwareErrorWidget> {
  late ConnectivityService _connectivityService;

  @override
  void initState() {
    super.initState();
    _connectivityService = ConnectivityService();
    
    _connectivityService.connectionStatus.listen((isConnected) {
      if (mounted) {
        setState(() {
          // Update UI if needed
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isNetworkError = ErrorUtils.isNetworkError(widget.errorMessage);
    
    if (isNetworkError) {
      return NetworkErrorWidget(
        onRetry: widget.onRetry ?? () {},
        title: widget.title ?? 'No Internet Connection',
        message: widget.customMessage ?? 
            'Please check your internet connection and try again.',
      );
    }

    // For non-network errors, show a generic error widget
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              widget.title ?? 'Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.customMessage ?? widget.errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            if (widget.onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: widget.onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
