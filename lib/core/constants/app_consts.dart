class AppConstants {
  // Collections/Tables
  static const String postTable = 'posts';
  static const String categoryCollection = 'categories';
  static const String profilesTable = 'profiles';
  static const String bookmarksTable = 'bookmarks';
  static const String messagesTable = 'messages';
  static const String messageMediaTable = 'message_media';
  static const String likesTable = 'likes';
  static const String followsTable = 'follows';
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
    'Entrepreneurship',
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

  static const List<Map<String, String>> homePageItems = [
    {'name': 'Education', 'image': 'assets/education1.jpg'},
    {'name': 'Sports', 'image': 'assets/sports1.jpg'},
    {'name': 'Health', 'image': 'assets/health1.jpg'},
    {'name': 'Food and Travel', 'image': 'assets/travels.jpeg'},
    {'name': 'Technology', 'image': 'assets/tech.jpg'},
    {'name': 'Finance', 'image': 'assets/finance.jpeg'},
    {'name': 'Entrepreneurship', 'image': 'assets/entre.jpeg'},
    {'name': 'Kids', 'image': 'assets/kids.jpg'},
    {'name': 'Entertainment', 'image': 'assets/entertainment.jpg'},
    {'name': 'Advertisements', 'image': 'assets/Feeds.jpg'},
  ];
}
