class ErrorUtils {
  static bool isNetworkError(String errorMessage) {
    final networkKeywords = [
      'SocketException',
      'ClientException',
      'Failed host lookup',
      'nodename nor servname',
      'Network is unreachable',
      'Connection timed out',
      'No route to host',
      'Connection refused',
      'Unable to connect', // Add this processed message
      'No internet connection', // Add this processed message
      'network error', // Common generic network error
      'connection error', // Common generic connection error
    ];

    return networkKeywords.any((keyword) =>
        errorMessage.toLowerCase().contains(keyword.toLowerCase()));
  }

  static String getNetworkErrorMessage(String originalError) {
    return isNetworkError(originalError)
        ? 'No internet connection'
        : originalError; // Return the actual error message for non-network errors
  }
}
