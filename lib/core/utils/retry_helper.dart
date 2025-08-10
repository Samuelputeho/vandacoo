import 'dart:async';
import 'package:vandacoo/core/common/widgets/error_utils.dart';

class RetryHelper {
  static Future<T> retry<T>({
    required Future<T> Function() operation,
    int maxAttempts = 3,
    Duration? baseDelay,
    bool Function(String error)? shouldRetry,
  }) async {
    int attempt = 1;
    Exception? lastException;

    while (attempt <= maxAttempts) {
      try {
        return await operation();
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        final errorMessage = e.toString();

        // Check if we should retry this error
        final shouldRetryError = shouldRetry?.call(errorMessage) ?? 
            ErrorUtils.shouldRetryOnError(errorMessage);

        if (!shouldRetryError || attempt >= maxAttempts) {
          throw lastException;
        }

        // Calculate delay with exponential backoff
        final delay = baseDelay ?? Duration(milliseconds: ErrorUtils.getRetryDelay(attempt));
        
        // Wait before retrying
        await Future.delayed(delay);
        attempt++;
      }
    }

    throw lastException ?? Exception('Operation failed after $maxAttempts attempts');
  }

  static Future<T> retryWithConnectivity<T>({
    required Future<T> Function() operation,
    required Future<bool> Function() checkConnectivity,
    int maxAttempts = 3,
    Duration? baseDelay,
  }) async {
    int attempt = 1;
    Exception? lastException;

    while (attempt <= maxAttempts) {
      try {
        return await operation();
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        final errorMessage = e.toString();

        // Check if we should retry this error and have connectivity
        final shouldRetryError = ErrorUtils.shouldRetryOnError(errorMessage);
        final hasConnectivity = await checkConnectivity();

        if (!shouldRetryError || !hasConnectivity || attempt >= maxAttempts) {
          throw lastException;
        }

        // Calculate delay with exponential backoff
        final delay = baseDelay ?? Duration(milliseconds: ErrorUtils.getRetryDelay(attempt));
        
        // Wait before retrying
        await Future.delayed(delay);
        attempt++;
      }
    }

    throw lastException ?? Exception('Operation failed after $maxAttempts attempts');
  }
}
