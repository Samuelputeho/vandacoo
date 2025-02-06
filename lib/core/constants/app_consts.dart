class AppConstants {
  // Collections/Tables
  static const String postTable = 'posts';
  static const String categoryCollection = 'categories';
  static const String profilesTable = 'profiles';
  static const String bookmarksTable = 'bookmarks';

  // Storage buckets
  static const String postImagesBucket = 'post_Images';
  static const String postVideosBucket = 'post_Videos';
  static const String storyViewsTable = 'story_views';
  static const String commentsTable = 'comments';
  static const List<String> categories = [
    'Education',
    'Entertainment',
    'Food and Travel',
    'Health',
    'Kids',
    'Finance',
    'Sports',
    'Technology',
  ];

  static const List<String> regions = [
    'Erongo',
    'Hardap',
    'Karas',
    'Kavango East',
    'Kavango West',
    'Khomas',
    'Kunene',
    'Ohangwena',
    'Omaheke',
    'Omusati',
    'Oshana',
    'Oshikoto',
    'Otjozondjupa',
    'Zambezi',
  ];

  static const List<String> profileImages = [
    "assets/health.jpeg",
    "assets/math1.jpg",
    "assets/math1.jpg",
    "assets/math1.jpg",
    "assets/math1.jpg",
    "assets/math1.jpg",
    "assets/health.jpeg",
    "assets/math1.jpg",
    "assets/math1.jpg",
    "assets/math1.jpg",
    "assets/math1.jpg",
    "assets/math1.jpg",
  ];

  static const List<Map<String, String>> statusCircleItems = [
    {'image': 'assets/Feeds.jpg', 'region': 'Namibia'},
    {'image': 'assets/math1.jpg', 'region': 'Khomas'},
    {'image': 'assets/math1.jpg', 'region': 'Oshana'},
    {'image': 'assets/math1.jpg', 'region': 'Kunene'},
    {'image': 'assets/math1.jpg', 'region': 'Zambezi'},
    {'image': 'assets/math1.jpg', 'region': 'Karas'},
    {'image': 'assets/math1.jpg', 'region': 'Ohangwena'},
    {'image': 'assets/math1.jpg', 'region': 'Omusati'},
    {'image': 'assets/math1.jpg', 'region': 'Erongo'},
  ];
}
