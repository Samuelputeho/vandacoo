class StoryEntity {
  final String id;
  final String userId;
  final String postId;
  final DateTime createdAt;

  StoryEntity({
    required this.id,
    required this.userId,
    required this.postId,
    required this.createdAt,
  });
}
