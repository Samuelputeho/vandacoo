class TimeFormatter {
  static String formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now().toUtc().add(const Duration(hours: 2));
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 0) {
      return 'Just now';
    }

    final seconds = difference.inSeconds;
    final minutes = difference.inMinutes;
    final hours = difference.inHours;
    final days = difference.inDays;

    if (seconds < 5) {
      return 'Just now';
    } else if (seconds < 60) {
      return '$seconds second${seconds == 1 ? '' : 's'} ago';
    } else if (minutes < 60) {
      return '$minutes minute${minutes == 1 ? '' : 's'} ago';
    } else if (hours < 24) {
      return '$hours hour${hours == 1 ? '' : 's'} ago';
    } else if (days < 30) {
      return '$days day${days == 1 ? '' : 's'} ago';
    } else if (days < 365) {
      final months = (days / 30).floor();
      return '$months month${months == 1 ? '' : 's'} ago';
    } else {
      final years = (days / 365).floor();
      return '$years year${years == 1 ? '' : 's'} ago';
    }
  }
}
