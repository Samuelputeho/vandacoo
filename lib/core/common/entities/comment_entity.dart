class CommentEntity {
  final String id;
  final String posterId;
  final String userId;
  final String comment;
  final DateTime createdAt;
  final String? userName;
  final String? userProPic;

  const CommentEntity({
    required this.id,
    required this.posterId,
    required this.userId,
    required this.comment,
    required this.createdAt,
    this.userName,
    this.userProPic,
  });
}