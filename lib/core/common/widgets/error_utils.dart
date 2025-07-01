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
    ];

    return networkKeywords.any((keyword) =>
        errorMessage.toLowerCase().contains(keyword.toLowerCase()));
  }

  static String getNetworkErrorMessage(String originalError) {
    return isNetworkError(originalError)
        ? 'No internet connection'
        : 'Unable to connect';
  }
}
