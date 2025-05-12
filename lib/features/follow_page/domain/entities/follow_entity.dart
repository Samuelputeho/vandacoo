class FollowEntity {
  final String id;
  final String followerId;
  final String followingId;
  final DateTime createdAt;
  final int numberOfPosts;
  final int numberOfFollowers;
  final int numberOfFollowing;

  const FollowEntity({
    required this.id,
    required this.followerId,
    required this.followingId,
    required this.createdAt,
    required this.numberOfPosts,
    required this.numberOfFollowers,
    required this.numberOfFollowing,
  });
}
