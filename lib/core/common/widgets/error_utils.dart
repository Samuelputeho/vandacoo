class ErrorUtils {
  static bool isNetworkError(String errorMessage) {
    final networkKeywords = [
      'SocketException',
      'ClientException',
      'Failed host lookup',
      'nodename nor servname',
      'Network is unreachable',
      'Connection timed out',
      'Operation timed out',
      'TimeoutException',
      'No route to host',
      'Connection refused',
      'Unable to connect',
      'No internet connection',
      'network error',
      'connection error',
      'Please check your internet connection',
      'Can\'t assign requested address',
      'errno = 8',
      'connection timeout',
      'supabase.co', // Supabase-specific network errors
      'rzueqfqjstcbyzkhxxbh.supabase.co', // Your specific Supabase URL
    ];

    return networkKeywords.any((keyword) =>
        errorMessage.toLowerCase().contains(keyword.toLowerCase()));
  }

  static String getNetworkErrorMessage(String originalError) {
    return isNetworkError(originalError)
        ? 'No internet connection. Please check your network and try again.'
        : originalError;
  }

  static bool shouldRetryOnError(String errorMessage) {
    return isNetworkError(errorMessage);
  }

  static int getRetryDelay(int attempt) {
    // Exponential backoff: 1s, 2s, 4s, 8s, 16s
    return (1 << (attempt - 1)) * 1000;
  }
}
